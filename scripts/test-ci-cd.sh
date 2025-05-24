#!/bin/bash

# CI/CD Test Script
# Tests the deployment pipeline and validates the deployed function

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

# Test configuration
ENVIRONMENT="${1:-development}"
BASE_URL="${2:-}"
TEST_TIMEOUT=30

# Function to test API endpoint
test_endpoint() {
    local endpoint="$1"
    local expected_status="${2:-200}"
    local description="$3"
    
    log_info "Testing: $description"
    log_info "Endpoint: $endpoint"
    
    local response
    local status_code
    
    # Make request and capture response
    response=$(curl -s -w "\n%{http_code}" "$endpoint" --max-time $TEST_TIMEOUT) || {
        log_error "Failed to connect to $endpoint"
        return 1
    }
    
    # Extract status code (last line)
    status_code=$(echo "$response" | tail -n1)
    
    # Extract response body (all but last line)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$status_code" == "$expected_status" ]]; then
        log_success "✅ $description - Status: $status_code"
        
        # Try to pretty print JSON if possible
        if command -v jq >/dev/null 2>&1 && echo "$body" | jq . >/dev/null 2>&1; then
            echo "$body" | jq .
        else
            echo "$body"
        fi
        return 0
    else
        log_error "❌ $description - Expected: $expected_status, Got: $status_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to test API with POST data
test_post_endpoint() {
    local endpoint="$1"
    local data="$2"
    local expected_status="${3:-201}"
    local description="$4"
    
    log_info "Testing: $description"
    log_info "Endpoint: $endpoint"
    log_info "Data: $data"
    
    local response
    local status_code
    
    # Make POST request
    response=$(curl -s -w "\n%{http_code}" -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data" \
        --max-time $TEST_TIMEOUT) || {
        log_error "Failed to connect to $endpoint"
        return 1
    }
    
    # Extract status code and body
    status_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$status_code" == "$expected_status" ]]; then
        log_success "✅ $description - Status: $status_code"
        
        # Pretty print JSON if possible
        if command -v jq >/dev/null 2>&1 && echo "$body" | jq . >/dev/null 2>&1; then
            echo "$body" | jq .
        else
            echo "$body"
        fi
        return 0
    else
        log_error "❌ $description - Expected: $expected_status, Got: $status_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to determine base URL
determine_base_url() {
    if [[ -n "$BASE_URL" ]]; then
        echo "$BASE_URL"
        return
    fi
    
    # Try to get URL from Terraform output
    if [[ -f "terraform/terraform.tfstate" ]]; then
        local tf_url
        tf_url=$(cd terraform && terraform output -raw function_url 2>/dev/null || echo "")
        if [[ -n "$tf_url" ]]; then
            echo "$tf_url"
            return
        fi
    fi
    
    # Construct URL based on environment
    local project_id="${GCP_PROJECT_ID:-your-project-id}"
    local region="${GCP_REGION:-asia-south1}"
    local function_name="hono-serverless-api"
    
    if [[ "$ENVIRONMENT" == "development" ]]; then
        function_name="${function_name}-dev"
    fi
    
    echo "https://${region}-${project_id}.cloudfunctions.net/${function_name}"
}

# Main test suite
run_tests() {
    local base_url
    base_url=$(determine_base_url)
    
    log_info "🧪 Starting API test suite"
    log_info "Environment: $ENVIRONMENT"
    log_info "Base URL: $base_url"
    log_info "Timeout: ${TEST_TIMEOUT}s"
    echo
    
    local failed_tests=0
    local total_tests=0
    
    # Test 1: Health Check
    ((total_tests++))
    if ! test_endpoint "$base_url/health" 200 "Health Check"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 2: Root Endpoint
    ((total_tests++))
    if ! test_endpoint "$base_url/" 200 "Root Endpoint - API Documentation"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 3: Get Users
    ((total_tests++))
    if ! test_endpoint "$base_url/api/users" 200 "Get Users List"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 4: Get Users with Pagination
    ((total_tests++))
    if ! test_endpoint "$base_url/api/users?page=1&limit=3" 200 "Get Users with Pagination"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 5: Get Single User
    ((total_tests++))
    if ! test_endpoint "$base_url/api/users/1" 200 "Get Single User"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 6: Get Non-existent User (should return 404)
    ((total_tests++))
    if ! test_endpoint "$base_url/api/users/999" 404 "Get Non-existent User"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 7: Create User (Valid Data)
    ((total_tests++))
    local valid_user_data='{"name":"Test User","email":"test@example.com"}'
    if ! test_post_endpoint "$base_url/api/users" "$valid_user_data" 201 "Create User - Valid Data"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 8: Create User (Invalid Data - should return 400)
    ((total_tests++))
    local invalid_user_data='{"name":"A","email":"invalid-email"}'
    if ! test_post_endpoint "$base_url/api/users" "$invalid_user_data" 400 "Create User - Invalid Data"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 9: Get Courses
    ((total_tests++))
    if ! test_endpoint "$base_url/api/courses" 200 "Get Courses List"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 10: Get Courses with Filter
    ((total_tests++))
    if ! test_endpoint "$base_url/api/courses?level=beginner" 200 "Get Courses - Filtered by Level"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 11: Get Single Course
    ((total_tests++))
    if ! test_endpoint "$base_url/api/courses/1" 200 "Get Single Course"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 12: Create Course (Valid Data)
    ((total_tests++))
    local valid_course_data='{"title":"Test Course","description":"A test course for validation","instructor":"Test Instructor","duration":30,"level":"beginner"}'
    if ! test_post_endpoint "$base_url/api/courses" "$valid_course_data" 201 "Create Course - Valid Data"; then
        ((failed_tests++))
    fi
    echo
    
    # Test 13: CORS Preflight (OPTIONS request)
    ((total_tests++))
    log_info "Testing: CORS Preflight Request"
    if curl -s -X OPTIONS "$base_url/api/users" \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        --max-time $TEST_TIMEOUT >/dev/null 2>&1; then
        log_success "✅ CORS Preflight Request"
    else
        log_error "❌ CORS Preflight Request"
        ((failed_tests++))
    fi
    echo
    
    # Test Summary
    log_info "📊 Test Summary"
    log_info "Total Tests: $total_tests"
    log_info "Passed: $((total_tests - failed_tests))"
    log_info "Failed: $failed_tests"
    
    if [[ $failed_tests -eq 0 ]]; then
        log_success "🎉 All tests passed!"
        return 0
    else
        log_error "❌ $failed_tests test(s) failed"
        return 1
    fi
}

# Function to test CI/CD pipeline configuration
test_pipeline_config() {
    log_info "🔧 Testing CI/CD Pipeline Configuration"
    
    local config_errors=0
    
    # Check GitLab CI configuration
    if [[ -f ".gitlab-ci.yml" ]]; then
        log_success "✅ GitLab CI configuration found"
        
        # Basic syntax check
        if command -v yamllint >/dev/null 2>&1; then
            if yamllint .gitlab-ci.yml >/dev/null 2>&1; then
                log_success "✅ GitLab CI YAML syntax is valid"
            else
                log_error "❌ GitLab CI YAML syntax errors found"
                ((config_errors++))
            fi
        fi
    else
        log_warning "⚠️ GitLab CI configuration not found"
    fi
    
    # Check GitHub Actions configuration
    if [[ -f ".github/workflows/deploy.yml" ]]; then
        log_success "✅ GitHub Actions configuration found"
        
        # Basic syntax check
        if command -v yamllint >/dev/null 2>&1; then
            if yamllint .github/workflows/deploy.yml >/dev/null 2>&1; then
                log_success "✅ GitHub Actions YAML syntax is valid"
            else
                log_error "❌ GitHub Actions YAML syntax errors found"
                ((config_errors++))
            fi
        fi
    else
        log_warning "⚠️ GitHub Actions configuration not found"
    fi
    
    # Check Terraform configuration
    if [[ -d "terraform" ]]; then
        log_success "✅ Terraform configuration found"
        
        if command -v terraform >/dev/null 2>&1; then
            cd terraform
            if terraform validate >/dev/null 2>&1; then
                log_success "✅ Terraform configuration is valid"
            else
                log_error "❌ Terraform configuration validation failed"
                ((config_errors++))
            fi
            cd ..
        fi
    else
        log_error "❌ Terraform configuration not found"
        ((config_errors++))
    fi
    
    # Check deployment scripts
    local scripts=("scripts/deploy.sh" "scripts/deploy-ci.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            log_success "✅ $script found"
            if [[ -x "$script" ]]; then
                log_success "✅ $script is executable"
            else
                log_warning "⚠️ $script is not executable"
            fi
        else
            log_warning "⚠️ $script not found"
        fi
    done
    
    if [[ $config_errors -eq 0 ]]; then
        log_success "🎉 Pipeline configuration looks good!"
        return 0
    else
        log_error "❌ $config_errors configuration issue(s) found"
        return 1
    fi
}

# Main function
main() {
    echo "🚀 CI/CD Test Suite"
    echo "==================="
    echo
    
    # Test pipeline configuration first
    if ! test_pipeline_config; then
        log_warning "Pipeline configuration issues detected, but continuing with API tests..."
    fi
    echo
    
    # Run API tests
    if ! run_tests; then
        exit 1
    fi
    
    log_success "🎉 All tests completed successfully!"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [environment] [base_url]"
    echo
    echo "Arguments:"
    echo "  environment  Environment to test (development|production) [default: development]"
    echo "  base_url     Base URL of the deployed function [optional, auto-detected if not provided]"
    echo
    echo "Examples:"
    echo "  $0                                                    # Test development environment"
    echo "  $0 production                                         # Test production environment"
    echo "  $0 development https://example.cloudfunctions.net/api # Test with specific URL"
    echo
    echo "Environment Variables:"
    echo "  GCP_PROJECT_ID  Your GCP project ID"
    echo "  GCP_REGION      GCP region [default: asia-south1]"
}

# Handle command line arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"