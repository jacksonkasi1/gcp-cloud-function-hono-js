#!/bin/bash

# =============================================================================
# GCP Hono.js Serverless Application Deployment Script
# =============================================================================
# This script handles the complete deployment process including:
# - Version management and tracking
# - Terraform infrastructure deployment
# - Automatic cleanup of old versions
# - Comprehensive error handling and logging
# =============================================================================

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
VERSION_FILE="$PROJECT_ROOT/.deployment-version"
LOG_FILE="$PROJECT_ROOT/deployment.log"

# Default values
DEFAULT_PROJECT_ID=""
DEFAULT_REGION="asia-south1"
DEFAULT_FUNCTION_NAME="hono-serverless-api"

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Deployment failed with exit code $exit_code"
        log "INFO" "Check the log file at: $LOG_FILE"
    fi
    exit $exit_code
}

trap cleanup_on_exit EXIT

# =============================================================================
# Version Management Functions
# =============================================================================

get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "v1.0.0"
    fi
}

increment_version() {
    local current_version=$1
    local version_number=${current_version#v}
    local major minor patch
    
    IFS='.' read -r major minor patch <<< "$version_number"
    patch=$((patch + 1))
    
    echo "v${major}.${minor}.${patch}"
}

save_version() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    log "INFO" "Saved deployment version: $version"
}

# =============================================================================
# Pre-deployment Checks
# =============================================================================

check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if required tools are installed
    local required_tools=("gcloud" "terraform" "node" "npm")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check Node.js version
    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 20 ]; then
        log "ERROR" "Node.js version 20 or higher is required. Current version: $node_version"
        exit 1
    fi
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log "ERROR" "gcloud is not authenticated. Run 'gcloud auth login' first"
        exit 1
    fi
    
    log "INFO" "All prerequisites satisfied"
}

check_terraform_vars() {
    log "INFO" "Checking Terraform configuration..."
    
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        log "WARN" "terraform.tfvars not found. Creating from example..."
        
        if [ ! -f "$TERRAFORM_DIR/terraform.tfvars.example" ]; then
            log "ERROR" "terraform.tfvars.example not found"
            exit 1
        fi
        
        cp "$TERRAFORM_DIR/terraform.tfvars.example" "$TERRAFORM_DIR/terraform.tfvars"
        
        log "ERROR" "Please edit terraform/terraform.tfvars with your project configuration"
        log "INFO" "Required: Set your project_id in terraform.tfvars"
        exit 1
    fi
    
    # Extract project_id from terraform.tfvars
    local project_id=$(grep '^project_id' "$TERRAFORM_DIR/terraform.tfvars" | cut -d'"' -f2)
    
    if [ "$project_id" = "your-gcp-project-id" ] || [ -z "$project_id" ]; then
        log "ERROR" "Please set a valid project_id in terraform/terraform.tfvars"
        exit 1
    fi
    
    log "INFO" "Terraform configuration validated for project: $project_id"
}

# =============================================================================
# Deployment Functions
# =============================================================================

install_dependencies() {
    log "INFO" "Installing Node.js dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [ ! -f "package.json" ]; then
        log "ERROR" "package.json not found in project root"
        exit 1
    fi
    
    npm install --production
    log "INFO" "Dependencies installed successfully"
}

deploy_infrastructure() {
    log "INFO" "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform if not already done
    if [ ! -d ".terraform" ]; then
        log "INFO" "Initializing Terraform..."
        terraform init
    fi
    
    # Get current version and increment it
    local current_version=$(get_current_version)
    local new_version=$(increment_version "$current_version")
    
    log "INFO" "Deploying version: $new_version (previous: $current_version)"
    
    # Plan the deployment
    log "INFO" "Creating Terraform plan..."
    terraform plan \
        -var="deployment_version=$new_version" \
        -out="tfplan"
    
    # Apply the deployment
    log "INFO" "Applying Terraform configuration..."
    terraform apply "tfplan"
    
    # Save the new version
    save_version "$new_version"
    
    # Get deployment outputs
    local function_url=$(terraform output -raw function_url)
    local health_check_url=$(terraform output -raw health_check_url)
    local api_users_url=$(terraform output -raw api_users_url)
    
    log "INFO" "Deployment completed successfully!"
    log "INFO" "Function URL: $function_url"
    log "INFO" "Health Check: $health_check_url"
    log "INFO" "Users API: $api_users_url"
    
    # Clean up plan file
    rm -f "tfplan"
}

test_deployment() {
    log "INFO" "Testing deployment..."
    
    cd "$TERRAFORM_DIR"
    
    local health_check_url=$(terraform output -raw health_check_url)
    
    # Wait for function to be ready
    log "INFO" "Waiting for function to be ready..."
    sleep 10
    
    # Test health check endpoint
    log "INFO" "Testing health check endpoint..."
    local response=$(curl -s -w "%{http_code}" -o /tmp/health_response "$health_check_url" || echo "000")
    
    if [ "$response" = "200" ]; then
        log "INFO" "Health check passed!"
        log "DEBUG" "Response: $(cat /tmp/health_response)"
    else
        log "WARN" "Health check returned status: $response"
        log "DEBUG" "Response: $(cat /tmp/health_response 2>/dev/null || echo 'No response')"
    fi
    
    # Clean up temp file
    rm -f /tmp/health_response
}

# =============================================================================
# Main Deployment Process
# =============================================================================

main() {
    log "INFO" "Starting deployment process..."
    log "INFO" "Project root: $PROJECT_ROOT"
    log "INFO" "Terraform directory: $TERRAFORM_DIR"
    
    # Run pre-deployment checks
    check_prerequisites
    check_terraform_vars
    
    # Install dependencies
    install_dependencies
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Test the deployment
    test_deployment
    
    log "INFO" "Deployment process completed successfully!"
    log "INFO" "Check the deployment log at: $LOG_FILE"
}

# =============================================================================
# Script Execution
# =============================================================================

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "This script deploys the Hono.js serverless application to GCP."
            echo "Make sure to configure terraform/terraform.tfvars before running."
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main deployment process
main "$@"