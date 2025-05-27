#!/bin/bash

# =============================================================================
# Project Validation Script - Cloud Build Version
# =============================================================================
# This script validates that all components of the serverless application
# are properly configured and ready for deployment using Google Cloud Build
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
        "cloudbuild.yaml"
        "scripts/deploy-local.sh"
        "scripts/test-api.sh"
        ".env.development"
        ".env.production"
        "README.md"
        ".gitignore"
        "tsconfig.json"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log "PASS" "Required file exists: $file"
        else
            log "FAIL" "Missing required file: $file"
        fi
    done
    
    # Check that Terraform files are removed
    if [ -d "$PROJECT_ROOT/terraform" ]; then
        log "FAIL" "Terraform directory still exists - should be removed"
    else
        log "PASS" "Terraform directory properly removed"
    fi
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
            
            # Check that Terraform references are removed
            if grep -q "terraform" "$PROJECT_ROOT/package.json"; then
                log "FAIL" "package.json still contains Terraform references"
            else
                log "PASS" "package.json cleaned of Terraform references"
            fi
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

validate_cloud_build_setup() {
    log "INFO" "Validating Google Cloud Build setup..."
    
    # Check cloudbuild.yaml
    if [ -f "$PROJECT_ROOT/cloudbuild.yaml" ]; then
        log "PASS" "cloudbuild.yaml exists"
        
        # Check for required sections
        if grep -q "steps:" "$PROJECT_ROOT/cloudbuild.yaml"; then
            log "PASS" "cloudbuild.yaml contains build steps"
        else
            log "FAIL" "cloudbuild.yaml missing build steps"
        fi
        
        if grep -q "gcloud functions deploy" "$PROJECT_ROOT/cloudbuild.yaml"; then
            log "PASS" "cloudbuild.yaml contains function deployment"
        else
            log "FAIL" "cloudbuild.yaml missing function deployment step"
        fi
        
        if grep -q "nodejs20" "$PROJECT_ROOT/cloudbuild.yaml"; then
            log "PASS" "cloudbuild.yaml configured for Node.js 20"
        else
            log "FAIL" "cloudbuild.yaml missing Node.js 20 runtime"
        fi
        
        if grep -q "health" "$PROJECT_ROOT/cloudbuild.yaml"; then
            log "PASS" "cloudbuild.yaml includes health check"
        else
            log "WARN" "cloudbuild.yaml missing health check step"
        fi
    else
        log "FAIL" "cloudbuild.yaml missing"
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
            log "WARN" "No default GCP project set (run 'gcloud config set project PROJECT_ID')"
        fi
        
        # Check required APIs (if project is set)
        if [ -n "$default_project" ]; then
            local required_apis=("cloudfunctions.googleapis.com" "cloudbuild.googleapis.com" "run.googleapis.com")
            
            for api in "${required_apis[@]}"; do
                if gcloud services list --enabled --filter="name:$api" --format="value(name)" 2>/dev/null | grep -q "$api"; then
                    log "PASS" "Required API enabled: $api"
                else
                    log "WARN" "Required API not enabled: $api (enable with: gcloud services enable $api)"
                fi
            done
        fi
    else
        log "FAIL" "gcloud CLI not installed or not in PATH"
    fi
}

validate_environment_files() {
    log "INFO" "Validating environment configuration..."
    
    # Check development environment
    if [ -f "$PROJECT_ROOT/.env.development" ]; then
        log "PASS" ".env.development exists"
        
        if grep -q "NODE_ENV=development" "$PROJECT_ROOT/.env.development"; then
            log "PASS" ".env.development has correct NODE_ENV"
        else
            log "FAIL" ".env.development missing NODE_ENV=development"
        fi
        
        if grep -q "CORS_ORIGINS=" "$PROJECT_ROOT/.env.development"; then
            log "PASS" ".env.development has CORS_ORIGINS configured"
        else
            log "FAIL" ".env.development missing CORS_ORIGINS"
        fi
        
        # Validate development region
        if grep -q "FUNCTION_REGION=" "$PROJECT_ROOT/.env.development"; then
            local dev_region=$(grep "FUNCTION_REGION=" "$PROJECT_ROOT/.env.development" | cut -d'=' -f2)
            if validate_gcp_region "$dev_region"; then
                log "PASS" ".env.development has valid GCP region: $dev_region"
            else
                log "FAIL" ".env.development has invalid GCP region: $dev_region"
            fi
        else
            log "FAIL" ".env.development missing FUNCTION_REGION"
        fi
    else
        log "FAIL" ".env.development missing"
    fi
    
    # Check production environment
    if [ -f "$PROJECT_ROOT/.env.production" ]; then
        log "PASS" ".env.production exists"
        
        if grep -q "NODE_ENV=production" "$PROJECT_ROOT/.env.production"; then
            log "PASS" ".env.production has correct NODE_ENV"
        else
            log "FAIL" ".env.production missing NODE_ENV=production"
        fi
        
        if grep -q "CORS_ORIGINS=" "$PROJECT_ROOT/.env.production"; then
            log "PASS" ".env.production has CORS_ORIGINS configured"
        else
            log "FAIL" ".env.production missing CORS_ORIGINS"
        fi
        
        # Validate production region
        if grep -q "FUNCTION_REGION=" "$PROJECT_ROOT/.env.production"; then
            local prod_region=$(grep "FUNCTION_REGION=" "$PROJECT_ROOT/.env.production" | cut -d'=' -f2)
            if validate_gcp_region "$prod_region"; then
                log "PASS" ".env.production has valid GCP region: $prod_region"
            else
                log "FAIL" ".env.production has invalid GCP region: $prod_region"
            fi
        else
            log "FAIL" ".env.production missing FUNCTION_REGION"
        fi
    else
        log "FAIL" ".env.production missing"
    fi
}

# Function to validate GCP regions
validate_gcp_region() {
    local region="$1"
    local valid_regions=(
        "us-central1" "us-east1" "us-east4" "us-west1" "us-west2" "us-west3" "us-west4"
        "europe-west1" "europe-west2" "europe-west3" "europe-west4" "europe-west6"
        "europe-central2" "europe-north1"
        "asia-east1" "asia-east2" "asia-northeast1" "asia-northeast2" "asia-northeast3"
        "asia-south1" "asia-southeast1" "asia-southeast2"
        "australia-southeast1" "australia-southeast2"
        "southamerica-east1"
    )
    
    for valid_region in "${valid_regions[@]}"; do
        if [[ "$region" == "$valid_region" ]]; then
            return 0
        fi
    done
    
    return 1
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
        
        # Check for export
        if grep -q "export default" "$PROJECT_ROOT/src/index.ts"; then
            log "PASS" "Default export found for Cloud Functions"
        else
            log "FAIL" "Default export missing (required for Cloud Functions)"
        fi
    fi
    
    # Check routes file
    if [ -f "$PROJECT_ROOT/src/routes/index.ts" ]; then
        if grep -q "/health" "$PROJECT_ROOT/src/routes/index.ts"; then
            log "PASS" "Health check route found"
        else
            log "FAIL" "Health check route missing"
        fi
        
        if grep -q "/api/users" "$PROJECT_ROOT/src/routes/index.ts" || grep -q "userRoutes" "$PROJECT_ROOT/src/routes/index.ts"; then
            log "PASS" "Users API route found"
        else
            log "FAIL" "Users API route missing"
        fi
    fi
}

validate_scripts() {
    log "INFO" "Validating deployment scripts..."
    
    local scripts=("deploy-local.sh" "test-api.sh" "validate.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/scripts/$script" ]; then
            log "PASS" "Script exists: $script"
            
            # Check if script has shebang
            if head -n1 "$PROJECT_ROOT/scripts/$script" | grep -q "#!/bin/bash"; then
                log "PASS" "Script has proper shebang: $script"
            else
                log "WARN" "Script missing shebang: $script"
            fi
            
            # Check if script is executable
            if [ -x "$PROJECT_ROOT/scripts/$script" ]; then
                log "PASS" "Script is executable: $script"
            else
                log "WARN" "Script not executable: $script (run: chmod +x scripts/$script)"
            fi
        else
            log "FAIL" "Script missing: $script"
        fi
    done
    
    # Check that old Terraform scripts are removed
    local old_scripts=("deploy.sh" "destroy.sh" "deploy-ci.sh" "test-ci-cd.sh" "load-env.sh")
    
    for script in "${old_scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/scripts/$script" ]; then
            log "FAIL" "Old Terraform script still exists: $script (should be removed)"
        else
            log "PASS" "Old Terraform script properly removed: $script"
        fi
    done
}

validate_typescript_config() {
    log "INFO" "Validating TypeScript configuration..."
    
    if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
        log "PASS" "tsconfig.json exists"
        
        if cd "$PROJECT_ROOT" && node -e "JSON.parse(require('fs').readFileSync('tsconfig.json', 'utf8'))" &> /dev/null; then
            log "PASS" "tsconfig.json is valid JSON"
        else
            log "FAIL" "tsconfig.json is invalid JSON"
        fi
        
        # Check if TypeScript can compile
        if cd "$PROJECT_ROOT" && npm run build &> /dev/null; then
            log "PASS" "TypeScript compilation successful"
        else
            log "FAIL" "TypeScript compilation failed (run: npm run build)"
        fi
    else
        log "FAIL" "tsconfig.json missing"
    fi
}

# =============================================================================
# Main Validation Process
# =============================================================================

main() {
    echo -e "${BLUE}🔍 GCP Cloud Build Serverless Application Validation${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo ""
    
    validate_project_structure
    echo ""
    
    validate_nodejs_setup
    echo ""
    
    validate_dependencies
    echo ""
    
    validate_cloud_build_setup
    echo ""
    
    validate_gcp_setup
    echo ""
    
    validate_environment_files
    echo ""
    
    validate_source_code
    echo ""
    
    validate_scripts
    echo ""
    
    validate_typescript_config
    echo ""
    
    # Summary
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo -e "${BLUE}====================${NC}"
    echo -e "${GREEN}✅ Passed: $PASSED${NC}"
    echo -e "${RED}❌ Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed! Your project is ready for deployment.${NC}"
        echo ""
        echo -e "${GREEN}📋 Next Steps:${NC}"
        echo -e "${GREEN}  Local Deployment:${NC}"
        echo -e "${GREEN}    npm run deploy:dev    # Deploy to development${NC}"
        echo -e "${GREEN}    npm run deploy:prod   # Deploy to production${NC}"
        echo ""
        echo -e "${GREEN}  Cloud Build Deployment:${NC}"
        echo -e "${GREEN}    Push to 'dev' branch for development deployment${NC}"
        echo -e "${GREEN}    Push to 'production' branch for production deployment${NC}"
        echo ""
        echo -e "${GREEN}  API Testing:${NC}"
        echo -e "${GREEN}    npm run test:api:dev   # Test development API${NC}"
        echo -e "${GREEN}    npm run test:api:prod  # Test production API${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Some validations failed. Please fix the issues above before deploying.${NC}"
        echo ""
        echo -e "${YELLOW}📋 Common Fixes:${NC}"
        echo -e "${YELLOW}  • Run 'npm install' to install dependencies${NC}"
        echo -e "${YELLOW}  • Run 'gcloud auth login' to authenticate${NC}"
        echo -e "${YELLOW}  • Run 'gcloud config set project PROJECT_ID' to set project${NC}"
        echo -e "${YELLOW}  • Enable required APIs: gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com run.googleapis.com${NC}"
        echo -e "${YELLOW}  • Make scripts executable: chmod +x scripts/*.sh${NC}"
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
            echo "This script validates the complete serverless application setup for Google Cloud Build deployment."
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