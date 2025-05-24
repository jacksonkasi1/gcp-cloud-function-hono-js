#!/bin/bash

# =============================================================================
# Project Validation Script
# =============================================================================
# This script validates that all components of the serverless application
# are properly configured and ready for deployment
# =============================================================================

set -euo pipefail

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

# Validation counters
PASSED=0
FAILED=0

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        "PASS")
            echo -e "${GREEN}✅ $message${NC}"
            PASSED=$((PASSED + 1))
            ;;
        "FAIL")
            echo -e "${RED}❌ $message${NC}"
            FAILED=$((FAILED + 1))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_project_structure() {
    log "INFO" "Validating project structure..."
    
    local required_files=(
        "package.json"
        "src/index.ts"
        "terraform/main.tf"
        "terraform/variables.tf"
        "terraform/outputs.tf"
        "terraform/terraform.tfvars.example"
        "scripts/deploy.sh"
        "scripts/destroy.sh"
        "README.md"
        ".gitignore"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log "PASS" "Required file exists: $file"
        else
            log "FAIL" "Missing required file: $file"
        fi
    done
}

validate_nodejs_setup() {
    log "INFO" "Validating Node.js setup..."
    
    # Check Node.js installation
    if command -v node &> /dev/null; then
        local node_version=$(node --version | sed 's/v//')
        local major_version=$(echo "$node_version" | cut -d. -f1)
        
        if [ "$major_version" -ge 20 ]; then
            log "PASS" "Node.js version $node_version (>= 20 required)"
        else
            log "FAIL" "Node.js version $node_version (>= 20 required)"
        fi
    else
        log "FAIL" "Node.js not installed or not in PATH"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        log "PASS" "npm version $npm_version"
    else
        log "FAIL" "npm not installed or not in PATH"
    fi
    
    # Check package.json
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if cd "$PROJECT_ROOT" && node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" &> /dev/null; then
            log "PASS" "package.json is valid JSON"
        else
            log "FAIL" "package.json is invalid JSON"
        fi
    fi
}

validate_dependencies() {
    log "INFO" "Validating dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [ -f "package.json" ]; then
        # Check if dependencies are listed
        if node -e "const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8')); console.log(pkg.dependencies?.hono ? 'found' : 'missing')" | grep -q "found"; then
            log "PASS" "Hono.js dependency listed in package.json"
        else
            log "FAIL" "Hono.js dependency missing from package.json"
        fi
        
        if node -e "const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8')); console.log(pkg.dependencies?.['@hono/node-server'] ? 'found' : 'missing')" | grep -q "found"; then
            log "PASS" "@hono/node-server dependency listed in package.json"
        else
            log "FAIL" "@hono/node-server dependency missing from package.json"
        fi
        
        # Check if node_modules exists
        if [ -d "node_modules" ]; then
            log "PASS" "node_modules directory exists"
            
            if [ -d "node_modules/hono" ]; then
                log "PASS" "Hono.js installed in node_modules"
            else
                log "FAIL" "Hono.js not installed (run npm install)"
            fi
        else
            log "WARN" "node_modules not found (run npm install)"
        fi
    fi
}

validate_terraform_setup() {
    log "INFO" "Validating Terraform setup..."
    
    # Check Terraform installation
    if command -v terraform &> /dev/null; then
        local tf_version=$(terraform version | head -n1 | cut -d' ' -f2)
        log "PASS" "Terraform version $tf_version"
    else
        log "FAIL" "Terraform not installed or not in PATH"
    fi
    
    # Check Terraform files
    cd "$TERRAFORM_DIR"
    
    # Validate Terraform syntax
    if terraform validate &> /dev/null; then
        log "PASS" "Terraform configuration is valid"
    else
        log "FAIL" "Terraform configuration has syntax errors"
    fi
    
    # Check for terraform.tfvars
    if [ -f "terraform.tfvars" ]; then
        local project_id=$(grep '^project_id' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
        
        if [ "$project_id" != "your-gcp-project-id" ] && [ -n "$project_id" ]; then
            log "PASS" "terraform.tfvars configured with project_id: $project_id"
        else
            log "FAIL" "terraform.tfvars not properly configured (set project_id)"
        fi
    else
        log "WARN" "terraform.tfvars not found (copy from terraform.tfvars.example)"
    fi
}

validate_gcp_setup() {
    log "INFO" "Validating GCP setup..."
    
    # Check gcloud installation
    if command -v gcloud &> /dev/null; then
        local gcloud_version=$(gcloud version --format="value(Google Cloud SDK)" 2>/dev/null || echo "unknown")
        log "PASS" "gcloud CLI installed (version: $gcloud_version)"
        
        # Check authentication
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
            local active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
            log "PASS" "gcloud authenticated as: $active_account"
        else
            log "FAIL" "gcloud not authenticated (run 'gcloud auth login')"
        fi
        
        # Check default project
        local default_project=$(gcloud config get-value project 2>/dev/null || echo "")
        if [ -n "$default_project" ]; then
            log "PASS" "Default GCP project: $default_project"
        else
            log "WARN" "No default GCP project set"
        fi
    else
        log "FAIL" "gcloud CLI not installed or not in PATH"
    fi
}

validate_source_code() {
    log "INFO" "Validating source code..."
    
    # Check main application file (TypeScript)
    if [ -f "$PROJECT_ROOT/src/index.ts" ]; then
        # Check for required imports
        if grep -q "from 'hono'" "$PROJECT_ROOT/src/index.ts" || grep -q "from \"hono\"" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "Hono.js import found in src/index.ts"
        else
            log "FAIL" "Hono.js import missing from src/index.ts"
        fi
        
        if grep -q "from '@hono/node-server'" "$PROJECT_ROOT/src/index.ts" || grep -q "from \"@hono/node-server\"" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "@hono/node-server import found in src/index.ts"
        else
            log "FAIL" "@hono/node-server import missing from src/index.ts"
        fi
        
        # Check for required routes
        if grep -q "/health" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "Health check route found"
        else
            log "FAIL" "Health check route missing"
        fi
        
        if grep -q "/api/users" "$PROJECT_ROOT/src/index.ts" || grep -q "/users" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "Users API route found"
        else
            log "FAIL" "Users API route missing"
        fi
        
        # Check for export
        if grep -q "export default" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "Default export found for Cloud Functions"
        else
            log "FAIL" "Default export missing (required for Cloud Functions)"
        fi
    fi
}

validate_scripts() {
    log "INFO" "Validating deployment scripts..."
    
    local scripts=("deploy.sh" "destroy.sh" "dev.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/scripts/$script" ]; then
            log "PASS" "Script exists: $script"
            
            # Check if script has shebang
            if head -n1 "$PROJECT_ROOT/scripts/$script" | grep -q "#!/bin/bash"; then
                log "PASS" "Script has proper shebang: $script"
            else
                log "WARN" "Script missing shebang: $script"
            fi
        else
            log "FAIL" "Script missing: $script"
        fi
    done
}

# =============================================================================
# Main Validation Process
# =============================================================================

main() {
    echo -e "${BLUE}🔍 GCP Hono.js Serverless Application Validation${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    validate_project_structure
    echo ""
    
    validate_nodejs_setup
    echo ""
    
    validate_dependencies
    echo ""
    
    validate_terraform_setup
    echo ""
    
    validate_gcp_setup
    echo ""
    
    validate_source_code
    echo ""
    
    validate_scripts
    echo ""
    
    # Summary
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo -e "${BLUE}====================${NC}"
    echo -e "${GREEN}✅ Passed: $PASSED${NC}"
    echo -e "${RED}❌ Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed! Your project is ready for deployment.${NC}"
        echo -e "${GREEN}Run 'npm run deploy' or 'bash scripts/deploy.sh' to deploy.${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Some validations failed. Please fix the issues above before deploying.${NC}"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "This script validates the complete serverless application setup."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main validation
main "$@"