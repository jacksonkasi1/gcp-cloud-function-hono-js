#!/bin/bash

# =============================================================================
# GCP Hono.js Serverless Application Destruction Script
# =============================================================================
# This script handles the complete removal of the deployed infrastructure
# including cleanup of storage buckets and version tracking
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
LOG_FILE="$PROJECT_ROOT/destruction.log"

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
        log "ERROR" "Destruction failed with exit code $exit_code"
        log "INFO" "Check the log file at: $LOG_FILE"
    fi
    exit $exit_code
}

trap cleanup_on_exit EXIT

# =============================================================================
# Confirmation Functions
# =============================================================================

confirm_destruction() {
    local project_id=""
    local function_name=""
    
    if [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        project_id=$(grep '^project_id' "$TERRAFORM_DIR/terraform.tfvars" | cut -d'"' -f2 2>/dev/null || echo "unknown")
        function_name=$(grep '^function_name' "$TERRAFORM_DIR/terraform.tfvars" | cut -d'"' -f2 2>/dev/null || echo "hono-serverless-api")
    fi
    
    echo -e "${RED}WARNING: This will destroy the following resources:${NC}"
    echo "  - Cloud Function: $function_name"
    echo "  - Storage Bucket and all versions"
    echo "  - IAM bindings"
    echo "  - Project: $project_id"
    echo ""
    
    if [ "$FORCE_DESTROY" != "true" ]; then
        read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
        
        if [ "$confirmation" != "yes" ]; then
            log "INFO" "Destruction cancelled by user"
            exit 0
        fi
    fi
    
    log "INFO" "Proceeding with infrastructure destruction..."
}

# =============================================================================
# Pre-destruction Checks
# =============================================================================

check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if required tools are installed
    local required_tools=("gcloud" "terraform")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log "ERROR" "gcloud is not authenticated. Run 'gcloud auth login' first"
        exit 1
    fi
    
    # Check if Terraform directory exists
    if [ ! -d "$TERRAFORM_DIR" ]; then
        log "ERROR" "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    # Check if Terraform is initialized
    if [ ! -d "$TERRAFORM_DIR/.terraform" ]; then
        log "ERROR" "Terraform not initialized. Run 'terraform init' in the terraform directory first"
        exit 1
    fi
    
    log "INFO" "All prerequisites satisfied"
}

# =============================================================================
# Cleanup Functions
# =============================================================================

cleanup_storage_bucket() {
    log "INFO" "Cleaning up storage bucket contents..."
    
    cd "$TERRAFORM_DIR"
    
    # Get bucket name from Terraform state
    local bucket_name=$(terraform output -raw storage_bucket 2>/dev/null || echo "")
    
    if [ -n "$bucket_name" ]; then
        log "INFO" "Found storage bucket: $bucket_name"
        
        # List and delete all objects in the bucket
        log "INFO" "Removing all objects from bucket..."
        if gcloud storage rm "gs://$bucket_name/**" --recursive 2>/dev/null || true; then
            log "INFO" "Bucket contents cleared successfully"
        else
            log "WARN" "Failed to clear bucket contents or bucket was already empty"
        fi
    else
        log "WARN" "Could not determine storage bucket name from Terraform state"
    fi
}

destroy_infrastructure() {
    log "INFO" "Destroying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Create destruction plan
    log "INFO" "Creating Terraform destruction plan..."
    if terraform plan -destroy -out="destroy.tfplan"; then
        log "INFO" "Destruction plan created successfully"
    else
        log "ERROR" "Failed to create destruction plan"
        exit 1
    fi
    
    # Apply the destruction
    log "INFO" "Applying Terraform destruction..."
    if terraform apply "destroy.tfplan"; then
        log "INFO" "Infrastructure destroyed successfully"
    else
        log "ERROR" "Failed to destroy infrastructure"
        exit 1
    fi
    
    # Clean up plan file
    rm -f "destroy.tfplan"
}

cleanup_terraform_state() {
    log "INFO" "Cleaning up Terraform state and cache..."
    
    cd "$TERRAFORM_DIR"
    
    # Remove Terraform state files (optional - comment out if you want to keep state)
    if [ "$CLEAN_STATE" = "true" ]; then
        log "WARN" "Removing Terraform state files..."
        rm -f terraform.tfstate*
        rm -f .terraform.lock.hcl
        rm -rf .terraform/
        log "INFO" "Terraform state cleaned"
    else
        log "INFO" "Keeping Terraform state files (use --clean-state to remove)"
    fi
}

cleanup_version_tracking() {
    log "INFO" "Cleaning up version tracking..."
    
    if [ -f "$VERSION_FILE" ]; then
        if [ "$CLEAN_VERSIONS" = "true" ]; then
            rm -f "$VERSION_FILE"
            log "INFO" "Version tracking file removed"
        else
            log "INFO" "Keeping version tracking file (use --clean-versions to remove)"
        fi
    fi
}

cleanup_logs() {
    log "INFO" "Cleaning up log files..."
    
    if [ "$CLEAN_LOGS" = "true" ]; then
        rm -f "$PROJECT_ROOT/deployment.log"
        log "INFO" "Deployment logs cleaned"
    else
        log "INFO" "Keeping log files (use --clean-logs to remove)"
    fi
}

# =============================================================================
# Main Destruction Process
# =============================================================================

main() {
    log "INFO" "Starting destruction process..."
    log "INFO" "Project root: $PROJECT_ROOT"
    log "INFO" "Terraform directory: $TERRAFORM_DIR"
    
    # Run pre-destruction checks
    check_prerequisites
    
    # Confirm destruction
    confirm_destruction
    
    # Clean up storage bucket contents first
    cleanup_storage_bucket
    
    # Destroy infrastructure
    destroy_infrastructure
    
    # Clean up Terraform state if requested
    cleanup_terraform_state
    
    # Clean up version tracking if requested
    cleanup_version_tracking
    
    # Clean up logs if requested
    cleanup_logs
    
    log "INFO" "Destruction process completed successfully!"
    log "INFO" "All resources have been removed from GCP"
}

# =============================================================================
# Script Execution
# =============================================================================

# Default values
FORCE_DESTROY="false"
CLEAN_STATE="false"
CLEAN_VERSIONS="false"
CLEAN_LOGS="false"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_DESTROY="true"
            shift
            ;;
        --clean-state)
            CLEAN_STATE="true"
            shift
            ;;
        --clean-versions)
            CLEAN_VERSIONS="true"
            shift
            ;;
        --clean-logs)
            CLEAN_LOGS="true"
            shift
            ;;
        --clean-all)
            CLEAN_STATE="true"
            CLEAN_VERSIONS="true"
            CLEAN_LOGS="true"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -f, --force          Skip confirmation prompt"
            echo "  --clean-state        Remove Terraform state files"
            echo "  --clean-versions     Remove version tracking file"
            echo "  --clean-logs         Remove log files"
            echo "  --clean-all          Remove all local files (state, versions, logs)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "This script destroys the Hono.js serverless application from GCP."
            echo "Use with caution as this action cannot be undone."
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main destruction process
main "$@"