#!/bin/bash

# =============================================================================
# Fix Cloud Build Permissions Script
# =============================================================================
# This script grants the necessary permission to the Cloud Build service account
# to resolve the "missing permission on the build service account" error.
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

# Check if credential file exists
CREDENTIAL_FILE="deploy-credential.json"
if [[ ! -f "$CREDENTIAL_FILE" ]]; then
    print_error "Credential file $CREDENTIAL_FILE not found!"
    exit 1
fi

# Authenticate with service account
print_status "Authenticating with service account..."
gcloud auth activate-service-account --key-file="$CREDENTIAL_FILE"

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID="patient-lens-ai-new"
    gcloud config set project "$PROJECT_ID"
fi

print_status "Working with project: $PROJECT_ID"

# Get project number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
print_status "Project number: $PROJECT_NUMBER"

# Grant the missing permission to the default compute service account
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
print_status "Granting Cloud Build Builder role to: $COMPUTE_SA"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="roles/cloudbuild.builds.builder"

if [[ $? -eq 0 ]]; then
    print_success "Successfully granted Cloud Build Builder role!"
    print_success "You can now run: pnpm run deploy:dev"
else
    print_error "Failed to grant permission"
    exit 1
fi

print_status "Permission fix completed!"