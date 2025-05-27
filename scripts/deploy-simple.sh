#!/bin/bash

# =============================================================================
# Cloud Run Deployment Script with Auto-Cleanup
# =============================================================================
# This script deploys the Hono.js application to Google Cloud Run
# using service account credentials for authentication and automatically
# cleans up old deployments, keeping only the last 2 revisions.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup old revisions
cleanup_old_revisions() {
    local service_name=$1
    local region=$2
    local keep_count=${3:-2}
    
    print_status "Cleaning up old revisions for service: $service_name"
    
    # Get all revisions for the service, sorted by creation time (newest first)
    local revisions=$(gcloud run revisions list \
        --service="$service_name" \
        --region="$region" \
        --format="value(metadata.name)" \
        --sort-by="~metadata.creationTimestamp" 2>/dev/null || echo "")
    
    if [[ -z "$revisions" ]]; then
        print_status "No existing revisions found for service $service_name"
        return 0
    fi
    
    # Convert to array
    local revision_array=($revisions)
    local total_revisions=${#revision_array[@]}
    
    print_status "Found $total_revisions total revisions"
    
    if [[ $total_revisions -le $keep_count ]]; then
        print_status "Only $total_revisions revisions exist, keeping all (target: keep $keep_count)"
        return 0
    fi
    
    # Calculate how many to delete
    local delete_count=$((total_revisions - keep_count))
    print_status "Will delete $delete_count old revisions (keeping newest $keep_count)"
    
    # Delete old revisions (skip the first $keep_count newest ones)
    for ((i=$keep_count; i<$total_revisions; i++)); do
        local revision_name=${revision_array[$i]}
        print_status "Deleting old revision: $revision_name"
        
        if gcloud run revisions delete "$revision_name" \
            --region="$region" \
            --quiet 2>/dev/null; then
            print_success "Deleted revision: $revision_name"
        else
            print_warning "Failed to delete revision: $revision_name (may be in use or already deleted)"
        fi
    done
}

# Function to cleanup old container images
cleanup_old_images() {
    local service_name=$1
    local project_id=$2
    local keep_count=${3:-3}  # Keep one extra image as safety buffer
    
    print_status "Cleaning up old container images for service: $service_name"
    
    # List images with the service name tag, sorted by creation time (newest first)
    local images=$(gcloud container images list-tags \
        "gcr.io/$project_id/cloud-run-source-deploy/$service_name" \
        --format="value(digest)" \
        --sort-by="~timestamp" \
        --limit=20 2>/dev/null || echo "")
    
    if [[ -z "$images" ]]; then
        print_status "No container images found for service $service_name"
        return 0
    fi
    
    # Convert to array
    local image_array=($images)
    local total_images=${#image_array[@]}
    
    print_status "Found $total_images container images"
    
    if [[ $total_images -le $keep_count ]]; then
        print_status "Only $total_images images exist, keeping all (target: keep $keep_count)"
        return 0
    fi
    
    # Calculate how many to delete
    local delete_count=$((total_images - keep_count))
    print_status "Will delete $delete_count old container images (keeping newest $keep_count)"
    
    # Delete old images (skip the first $keep_count newest ones)
    for ((i=$keep_count; i<$total_images; i++)); do
        local image_digest=${image_array[$i]}
        local image_url="gcr.io/$project_id/cloud-run-source-deploy/$service_name@$image_digest"
        
        print_status "Deleting old container image: $image_digest"
        
        if gcloud container images delete "$image_url" \
            --quiet 2>/dev/null; then
            print_success "Deleted container image: $image_digest"
        else
            print_warning "Failed to delete container image: $image_digest"
        fi
    done
}

# Determine environment
ENVIRONMENT=${1:-development}

if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Use 'development' or 'production'"
    exit 1
fi

print_status "Starting deployment for $ENVIRONMENT environment"

# Check if credential file exists
CREDENTIAL_FILE="deploy-credential.json"
if [[ ! -f "$CREDENTIAL_FILE" ]]; then
    print_error "Credential file $CREDENTIAL_FILE not found!"
    print_error "Please create $CREDENTIAL_FILE with your service account key"
    print_error "Make sure to add your actual GCP service account JSON key to this file"
    exit 1
fi

# Set service name based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    SERVICE_NAME="hono-serverless-api"
else
    SERVICE_NAME="hono-serverless-api-dev"
fi

# Check if environment file exists
ENV_FILE=".env.$ENVIRONMENT"
if [[ ! -f "$ENV_FILE" ]]; then
    print_error "Environment file $ENV_FILE not found!"
    print_error "Please create $ENV_FILE with the required configuration"
    exit 1
fi

print_status "Loading environment configuration from $ENV_FILE"

# Load environment variables (excluding PORT which is reserved by Cloud Run)
set -a
source "$ENV_FILE"
set +a

# Unset PORT to avoid conflicts with Cloud Run
unset PORT

# Set defaults if not specified
REGION=${CLOUD_RUN_REGION:-asia-south1}
MEMORY=${CLOUD_RUN_MEMORY:-1Gi}
CPU=${CLOUD_RUN_CPU:-1}
PROJECT_ID=${GCP_PROJECT_ID:-patient-lens-ai-new}

print_status "Deployment Configuration:"
echo "  Service Name: $SERVICE_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo "  Memory: $MEMORY"
echo "  CPU: $CPU"
echo "  Project: $PROJECT_ID"

# Authenticate with service account
print_status "Authenticating with service account..."
gcloud auth activate-service-account --key-file="$CREDENTIAL_FILE"

# Set the project
print_status "Setting project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Enable required APIs
print_status "Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Get the service account email from the credential file
SERVICE_ACCOUNT_EMAIL=$(python3 -c "import json; print(json.load(open('$CREDENTIAL_FILE'))['client_email'])" 2>/dev/null || \
                       node -e "console.log(JSON.parse(require('fs').readFileSync('$CREDENTIAL_FILE', 'utf8')).client_email)" 2>/dev/null || \
                       echo "terraform-sa@patient-lens-ai-new.iam.gserviceaccount.com")

print_status "Using service account: $SERVICE_ACCOUNT_EMAIL"

# Clean up old revisions before deployment
print_status "=== PRE-DEPLOYMENT CLEANUP ==="
cleanup_old_revisions "$SERVICE_NAME" "$REGION" 2

# Deploy to Cloud Run
print_status "=== STARTING DEPLOYMENT ==="
print_status "Deploying to Cloud Run: $SERVICE_NAME"

# Try Docker-based deployment first, fallback to source-based if it fails
print_status "Attempting Docker-based deployment..."

DEPLOYMENT_SUCCESS=false

if gcloud run deploy "$SERVICE_NAME" \
    --source=. \
    --region="$REGION" \
    --allow-unauthenticated \
    --memory="$MEMORY" \
    --cpu="$CPU" \
    --timeout=300 \
    --concurrency=100 \
    --min-instances=0 \
    --max-instances=10 \
    --service-account="$SERVICE_ACCOUNT_EMAIL" \
    --set-env-vars="NODE_ENV=$ENVIRONMENT,PORT=8080" \
    --port=8080 \
    --quiet; then
    print_success "Docker-based deployment successful!"
    DEPLOYMENT_SUCCESS=true
else
    print_warning "Docker-based deployment failed. Trying source-based deployment..."
    
    # Remove Dockerfile temporarily for source-based deployment
    if [[ -f "Dockerfile" ]]; then
        mv Dockerfile Dockerfile.bak
        print_status "Temporarily moved Dockerfile to Dockerfile.bak"
    fi
    
    # Try source-based deployment
    if gcloud run deploy "$SERVICE_NAME" \
        --source=. \
        --region="$REGION" \
        --allow-unauthenticated \
        --memory="$MEMORY" \
        --cpu="$CPU" \
        --timeout=300 \
        --concurrency=100 \
        --min-instances=0 \
        --max-instances=10 \
        --service-account="$SERVICE_ACCOUNT_EMAIL" \
        --set-env-vars="NODE_ENV=$ENVIRONMENT" \
        --port=8080 \
        --quiet; then
        print_success "Source-based deployment successful!"
        DEPLOYMENT_SUCCESS=true
        
        # Restore Dockerfile
        if [[ -f "Dockerfile.bak" ]]; then
            mv Dockerfile.bak Dockerfile
            print_status "Restored Dockerfile"
        fi
    else
        # Restore Dockerfile even if deployment failed
        if [[ -f "Dockerfile.bak" ]]; then
            mv Dockerfile.bak Dockerfile
            print_status "Restored Dockerfile"
        fi
        print_error "Both Docker-based and source-based deployments failed!"
        exit 1
    fi
fi

if [[ "$DEPLOYMENT_SUCCESS" == true ]]; then
    print_success "Service deployed successfully!"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
    print_success "Service URL: $SERVICE_URL"
    
    # Post-deployment cleanup
    print_status "=== POST-DEPLOYMENT CLEANUP ==="
    
    # Clean up old revisions again (in case the pre-deployment cleanup missed anything)
    cleanup_old_revisions "$SERVICE_NAME" "$REGION" 2
    
    # Clean up old container images
    cleanup_old_images "$SERVICE_NAME" "$PROJECT_ID" 3
    
    print_success "=== DEPLOYMENT AND CLEANUP COMPLETED ==="
    print_status "You can test the API with: curl $SERVICE_URL/health"
    
    # Show current revisions
    print_status "Current active revisions:"
    gcloud run revisions list \
        --service="$SERVICE_NAME" \
        --region="$REGION" \
        --format="table(metadata.name,status.conditions[0].status,metadata.creationTimestamp)" \
        --sort-by="~metadata.creationTimestamp" \
        --limit=5 2>/dev/null || print_warning "Could not list current revisions"
        
else
    print_error "Deployment failed!"
    exit 1
fi