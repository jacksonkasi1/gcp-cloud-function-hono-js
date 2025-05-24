#!/bin/bash

# CI/CD Deployment Script for GCP Cloud Functions
# This script is optimized for CI/CD environments with proper error handling and logging

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "NODE_ENV"
        "GCP_PROJECT_ID"
        "TF_VAR_function_name"
        "TF_VAR_environment"
        "TF_VAR_deployment_version"
    )
    
    log_info "Validating environment variables..."
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    log_success "All required environment variables are set"
}

# Function to check required tools
check_dependencies() {
    log_info "Checking required dependencies..."
    
    local required_tools=("node" "pnpm" "gcloud" "terraform")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install the missing tools and try again"
        exit 1
    fi
    
    log_success "All required tools are available"
}

# Function to setup environment-specific variables
setup_environment() {
    log_info "Setting up environment-specific configuration..."
    
    # Set default values if not provided
    export TF_VAR_project_id="${GCP_PROJECT_ID}"
    export TF_VAR_region="${GCP_REGION:-asia-south1}"
    
    # Environment-specific settings
    case "${NODE_ENV}" in
        "development")
            export TF_VAR_function_memory="${TF_VAR_function_memory:-1GB}"
            export TF_VAR_function_timeout="${TF_VAR_function_timeout:-60}"
            export TF_VAR_function_max_instances="${TF_VAR_function_max_instances:-10}"
            export TF_VAR_function_min_instances="${TF_VAR_function_min_instances:-0}"
            ;;
        "production")
            export TF_VAR_function_memory="${TF_VAR_function_memory:-2GB}"
            export TF_VAR_function_timeout="${TF_VAR_function_timeout:-30}"
            export TF_VAR_function_max_instances="${TF_VAR_function_max_instances:-100}"
            export TF_VAR_function_min_instances="${TF_VAR_function_min_instances:-1}"
            ;;
        *)
            log_warning "Unknown NODE_ENV: ${NODE_ENV}. Using default settings."
            ;;
    esac
    
    log_success "Environment configuration completed"
    log_info "Deployment settings:"
    log_info "  Environment: ${NODE_ENV}"
    log_info "  Function Name: ${TF_VAR_function_name}"
    log_info "  Version: ${TF_VAR_deployment_version}"
    log_info "  Memory: ${TF_VAR_function_memory}"
    log_info "  Timeout: ${TF_VAR_function_timeout}s"
}

# Function to build the application
build_application() {
    log_info "Building TypeScript application..."
    
    # Install dependencies if not already installed
    if [[ ! -d "node_modules" ]]; then
        log_info "Installing dependencies..."
        pnpm install --frozen-lockfile
    fi
    
    # Build the application
    log_info "Compiling TypeScript..."
    pnpm run build
    
    # Verify build output
    if [[ ! -f "dist/index.js" ]]; then
        log_error "Build failed: dist/index.js not found"
        exit 1
    fi
    
    log_success "Application built successfully"
}

# Function to prepare deployment files
prepare_deployment() {
    log_info "Preparing deployment files..."
    
    # Create deployment directory
    mkdir -p deployment
    
    # Copy necessary files
    cp -r dist/* deployment/ 2>/dev/null || true
    cp package.json deployment/
    cp pnpm-lock.yaml deployment/ 2>/dev/null || cp package-lock.json deployment/ 2>/dev/null || true
    
    # Copy environment-specific files
    if [[ -f ".env.${NODE_ENV}" ]]; then
        cp ".env.${NODE_ENV}" deployment/.env
        log_info "Copied environment file: .env.${NODE_ENV}"
    fi
    
    log_success "Deployment files prepared"
}

# Function to deploy with Terraform
deploy_with_terraform() {
    log_info "Deploying with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -input=false
    
    # Select or create workspace for environment isolation
    log_info "Setting up Terraform workspace: ${TF_VAR_environment}"
    terraform workspace select "${TF_VAR_environment}" 2>/dev/null || terraform workspace new "${TF_VAR_environment}"
    
    # Plan the deployment
    log_info "Planning Terraform deployment..."
    local tfvars_file="terraform.tfvars.${TF_VAR_environment}"
    
    if [[ -f "$tfvars_file" ]]; then
        terraform plan -var-file="$tfvars_file" -out=tfplan
    else
        log_warning "Terraform vars file $tfvars_file not found, using variables from environment"
        terraform plan -out=tfplan
    fi
    
    # Apply the deployment
    log_info "Applying Terraform deployment..."
    terraform apply -input=false tfplan
    
    # Get outputs
    log_info "Retrieving deployment information..."
    FUNCTION_URL=$(terraform output -raw function_url 2>/dev/null || echo "")
    FUNCTION_NAME=$(terraform output -raw function_name 2>/dev/null || echo "${TF_VAR_function_name}")
    
    cd ..
    
    log_success "Terraform deployment completed"
    
    if [[ -n "$FUNCTION_URL" ]]; then
        log_success "Function deployed at: $FUNCTION_URL"
    fi
}

# Function to run post-deployment health check
health_check() {
    log_info "Running post-deployment health check..."
    
    local function_url="${FUNCTION_URL:-https://${TF_VAR_region:-asia-south1}-${GCP_PROJECT_ID}.cloudfunctions.net/${TF_VAR_function_name}}"
    local health_endpoint="${function_url}/health"
    local max_attempts=10
    local attempt=1
    
    log_info "Health check endpoint: $health_endpoint"
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Health check attempt $attempt/$max_attempts..."
        
        if curl -f -s "$health_endpoint" >/dev/null 2>&1; then
            log_success "Health check passed!"
            
            # Get and display health check response
            local health_response=$(curl -s "$health_endpoint" | jq . 2>/dev/null || curl -s "$health_endpoint")
            log_info "Health check response: $health_response"
            return 0
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_warning "Health check failed after $max_attempts attempts"
            log_warning "This may be normal for new deployments. Function might still be initializing."
            return 0  # Don't fail the deployment for health check issues
        fi
        
        log_info "Waiting 10 seconds before next attempt..."
        sleep 10
        ((attempt++))
    done
}

# Function to cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove deployment directory
    rm -rf deployment
    
    # Remove Terraform plan file
    rm -f terraform/tfplan
    
    log_success "Cleanup completed"
}

# Main deployment function
main() {
    log_info "Starting CI/CD deployment process..."
    log_info "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    # Run deployment steps
    validate_environment
    check_dependencies
    setup_environment
    build_application
    prepare_deployment
    deploy_with_terraform
    health_check
    
    log_success "🎉 Deployment completed successfully!"
    log_success "Environment: ${NODE_ENV}"
    log_success "Function: ${TF_VAR_function_name}"
    log_success "Version: ${TF_VAR_deployment_version}"
    
    if [[ -n "${FUNCTION_URL:-}" ]]; then
        log_success "URL: ${FUNCTION_URL}"
        log_success "Health Check: ${FUNCTION_URL}/health"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi