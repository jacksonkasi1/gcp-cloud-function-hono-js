#!/bin/bash

# =============================================================================
# Simple Cloud Run Deployment Script with Service Account
# =============================================================================
# This script deploys the Hono.js application to Google Cloud Run
# using service account credentials for authentication.
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

# Deploy to Cloud Run
print_status "Deploying to Cloud Run: $SERVICE_NAME"

# Try Docker-based deployment first, fallback to source-based if it fails
print_status "Attempting Docker-based deployment..."

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

if [[ $? -eq 0 ]]; then
    print_success "Service deployed successfully!"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
    
    print_success "Service URL: $SERVICE_URL"
    print_status "You can test the API with: curl $SERVICE_URL/health"
else
    print_error "Deployment failed!"
    exit 1
fi