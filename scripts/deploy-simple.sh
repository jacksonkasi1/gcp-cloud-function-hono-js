#!/bin/bash

# =============================================================================
# Simple Cloud Functions Deployment Script with Service Account
# =============================================================================
# This script deploys the Hono.js serverless application to Google Cloud Functions
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

# Set function name based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    FUNCTION_NAME="hono-serverless-api"
else
    FUNCTION_NAME="hono-serverless-api-dev"
fi

# Check if environment file exists
ENV_FILE=".env.$ENVIRONMENT"
if [[ ! -f "$ENV_FILE" ]]; then
    print_error "Environment file $ENV_FILE not found!"
    print_error "Please create $ENV_FILE with the required configuration"
    exit 1
fi

print_status "Loading environment configuration from $ENV_FILE"

# Load environment variables
set -a
source "$ENV_FILE"
set +a

# Set defaults if not specified
REGION=${FUNCTION_REGION:-asia-south1}
MEMORY=${FUNCTION_MEMORY:-1GB}
PROJECT_ID=${GCP_PROJECT_ID:-patient-lens-ai-new}

print_status "Deployment Configuration:"
echo "  Function Name: $FUNCTION_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo "  Memory: $MEMORY"
echo "  Project: $PROJECT_ID"

# Authenticate with service account
print_status "Authenticating with service account..."
gcloud auth activate-service-account --key-file="$CREDENTIAL_FILE"

# Set the project
print_status "Setting project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Install dependencies
print_status "Installing dependencies..."
npm install

# Build TypeScript
print_status "Building TypeScript..."
npm run build

# Get the service account email from the credential file
SERVICE_ACCOUNT_EMAIL=$(python3 -c "import json; print(json.load(open('$CREDENTIAL_FILE'))['client_email'])" 2>/dev/null || \
                       node -e "console.log(JSON.parse(require('fs').readFileSync('$CREDENTIAL_FILE', 'utf8')).client_email)" 2>/dev/null || \
                       echo "terraform-sa@patient-lens-ai-new.iam.gserviceaccount.com")

print_status "Using service account: $SERVICE_ACCOUNT_EMAIL"

# Deploy the function
print_status "Deploying Cloud Function: $FUNCTION_NAME"

gcloud functions deploy "$FUNCTION_NAME" \
    --gen2 \
    --runtime=nodejs20 \
    --region="$REGION" \
    --source=. \
    --entry-point=default \
    --trigger-http \
    --allow-unauthenticated \
    --memory="$MEMORY" \
    --timeout=60s \
    --service-account="$SERVICE_ACCOUNT_EMAIL" \
    --set-env-vars="NODE_ENV=$ENVIRONMENT" \
    --quiet

if [[ $? -eq 0 ]]; then
    print_success "Function deployed successfully!"
    
    # Get function URL
    FUNCTION_URL=$(gcloud functions describe "$FUNCTION_NAME" --region="$REGION" --format="value(serviceConfig.uri)")
    
    print_success "Function URL: $FUNCTION_URL"
    print_status "You can test the API with: curl $FUNCTION_URL/health"
else
    print_error "Deployment failed!"
    exit 1
fi