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

# Function to properly escape YAML values
escape_yaml_value() {
    local value="$1"
    # If value contains special characters, spaces, or starts with special chars, quote it
    if [[ "$value" =~ [[:space:]|\|\>\<\[\]\{\}\*\&\!\%\@\`] ]] || [[ "$value" =~ ^[-\?\:\,] ]]; then
        # Escape any existing quotes and wrap in quotes
        echo "\"$(echo "$value" | sed 's/"/\\"/g')\""
    else
        echo "$value"
    fi
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

# Validate required environment variables
print_status "Validating required environment variables..."

VALIDATION_FAILED=false

if [[ -z "$SERVICE_NAME" ]]; then
    print_error "SERVICE_NAME is required but not set in $ENV_FILE"
    VALIDATION_FAILED=true
fi

if [[ -z "$GCP_PROJECT_ID" ]]; then
    print_error "GCP_PROJECT_ID is required but not set in $ENV_FILE"
    VALIDATION_FAILED=true
fi

if [[ -z "$CLOUD_RUN_REGION" ]]; then
    print_error "CLOUD_RUN_REGION is required but not set in $ENV_FILE"
    VALIDATION_FAILED=true
fi

# Optional variables with defaults
MEMORY=${CLOUD_RUN_MEMORY:-1Gi}
CPU=${CLOUD_RUN_CPU:-1}

# Use the validated required variables
REGION="$CLOUD_RUN_REGION"
PROJECT_ID="$GCP_PROJECT_ID"

if [[ "$VALIDATION_FAILED" == true ]]; then
    print_error ""
    print_error "Missing required environment variables in $ENV_FILE"
    print_error "Required variables:"
    print_error "  - SERVICE_NAME (e.g., my-api-dev)"
    print_error "  - GCP_PROJECT_ID (e.g., my-project-123)"
    print_error "  - CLOUD_RUN_REGION (e.g., asia-south1)"
    print_error ""
    print_error "Optional variables (with defaults):"
    print_error "  - CLOUD_RUN_MEMORY (default: 1Gi)"
    print_error "  - CLOUD_RUN_CPU (default: 1)"
    exit 1
fi

print_success "All required environment variables are set"

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

# Create a temporary env vars file for deployment in YAML format
TEMP_ENV_FILE=$(mktemp)

# Start YAML content
echo "# Environment variables for Cloud Run deployment" > "$TEMP_ENV_FILE"

# Add NODE_ENV first
echo "NODE_ENV: $(escape_yaml_value "$ENVIRONMENT")" >> "$TEMP_ENV_FILE"

# Add other environment variables from the env file if they exist (excluding reserved ones)
while IFS='=' read -r key value; do
    # Skip comments, empty lines, and reserved variables
    if [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ -n "$key" ]] && [[ "$key" != "PORT" ]] && [[ "$key" != "NODE_ENV" ]] && [[ "$key" != "SERVICE_NAME" ]] && [[ "$key" != "GCP_PROJECT_ID" ]] && [[ "$key" != "CLOUD_RUN_REGION" ]] && [[ "$key" != "CLOUD_RUN_MEMORY" ]] && [[ "$key" != "CLOUD_RUN_CPU" ]]; then
        # Remove any quotes and whitespace from key
        clean_key=$(echo "$key" | xargs)
        # Handle value more carefully - preserve content but remove outer quotes if they exist
        clean_value=$(echo "$value" | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
        if [[ -n "$clean_value" ]]; then
            escaped_value=$(escape_yaml_value "$clean_value")
            echo "$clean_key: $escaped_value" >> "$TEMP_ENV_FILE"
        fi
    fi
done < "$ENV_FILE"

print_status "Environment variables file created at: $TEMP_ENV_FILE"
print_status "Environment variables YAML content:"
cat "$TEMP_ENV_FILE" | while read line; do echo "  $line"; done

# Function to cleanup temp file
cleanup_temp_file() {
    if [[ -f "$TEMP_ENV_FILE" ]]; then
        rm -f "$TEMP_ENV_FILE"
    fi
}

# Ensure cleanup happens on script exit
trap cleanup_temp_file EXIT

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
    --env-vars-file="$TEMP_ENV_FILE" \
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
        --env-vars-file="$TEMP_ENV_FILE" \
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