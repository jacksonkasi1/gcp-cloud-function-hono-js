#!/bin/bash

# API testing script for deployed Google Cloud Functions
# Usage: bash scripts/test-api.sh [environment]
# Environment: development (default) or production

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

print_status "Testing API for $ENVIRONMENT environment"

# Set function name based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    FUNCTION_NAME="hono-serverless-api"
else
    FUNCTION_NAME="hono-serverless-api-dev"
fi

# Load environment configuration
ENV_FILE=".env.$ENVIRONMENT"
if [[ ! -f "$ENV_FILE" ]]; then
    print_error "Environment file $ENV_FILE not found!"
    exit 1
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

REGION=${FUNCTION_REGION:-asia-south1}

print_status "Getting function URL..."

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    exit 1
fi

# Get function URL
FUNCTION_URL=$(gcloud functions describe "$FUNCTION_NAME" --region="$REGION" --format="value(serviceConfig.uri)" 2>/dev/null)

if [[ -z "$FUNCTION_URL" ]]; then
    print_error "Could not retrieve function URL for $FUNCTION_NAME in region $REGION"
    print_error "Make sure the function is deployed first"
    exit 1
fi

print_success "Function URL: $FUNCTION_URL"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    print_status "Testing: $test_name"
    
    if [[ -n "$data" ]]; then
        response=$(curl -s -w "%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -o /tmp/test_response.json \
            "$FUNCTION_URL$endpoint" 2>/dev/null || echo "000")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" \
            -o /tmp/test_response.json \
            "$FUNCTION_URL$endpoint" 2>/dev/null || echo "000")
    fi
    
    if [[ "$response" == "$expected_status" ]]; then
        print_success "✅ $test_name - Status: $response"
        if [[ -f /tmp/test_response.json ]]; then
            echo "Response:"
            cat /tmp/test_response.json | jq '.' 2>/dev/null || cat /tmp/test_response.json
        fi
        ((TESTS_PASSED++))
    else
        print_error "❌ $test_name - Expected: $expected_status, Got: $response"
        if [[ -f /tmp/test_response.json ]]; then
            echo "Response:"
            cat /tmp/test_response.json
        fi
        ((TESTS_FAILED++))
    fi
    
    echo ""
    rm -f /tmp/test_response.json
}

# Start testing
print_status "🧪 Starting API tests..."
echo ""

# Test 1: Health check
run_test "Health Check" "GET" "/health" "" "200"

# Test 2: Root endpoint
run_test "Root Endpoint" "GET" "/" "" "200"

# Test 3: Get users (empty list)
run_test "Get Users" "GET" "/api/users" "" "200"

# Test 4: Get users with pagination
run_test "Get Users with Pagination" "GET" "/api/users?page=1&limit=5" "" "200"

# Test 5: Create user
run_test "Create User" "POST" "/api/users" '{"name":"Test User","email":"test@example.com"}' "201"

# Test 6: Get user by ID
run_test "Get User by ID" "GET" "/api/users/1" "" "200"

# Test 7: Update user
run_test "Update User" "PUT" "/api/users/1" '{"name":"Updated User","email":"updated@example.com"}' "200"

# Test 8: Get courses (empty list)
run_test "Get Courses" "GET" "/api/courses" "" "200"

# Test 9: Get courses with filtering
run_test "Get Courses with Filter" "GET" "/api/courses?level=beginner&page=1&limit=5" "" "200"

# Test 10: Create course
run_test "Create Course" "POST" "/api/courses" '{"title":"Test Course","description":"Test Description","instructor":"Test Instructor","duration":30,"level":"beginner"}' "201"

# Test 11: Get course by ID
run_test "Get Course by ID" "GET" "/api/courses/1" "" "200"

# Test 12: Update course
run_test "Update Course" "PUT" "/api/courses/1" '{"title":"Updated Course","description":"Updated Description","instructor":"Updated Instructor","duration":45,"level":"intermediate"}' "200"

# Test 13: Invalid endpoint (404)
run_test "Invalid Endpoint" "GET" "/api/invalid" "" "404"

# Test 14: Invalid user ID
run_test "Invalid User ID" "GET" "/api/users/999" "" "404"

# Test 15: Invalid course ID
run_test "Invalid Course ID" "GET" "/api/courses/999" "" "404"

# Summary
echo ""
print_status "📊 Test Summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Function: $FUNCTION_NAME"
echo "  Region: $REGION"
echo "  Function URL: $FUNCTION_URL"
echo ""
echo "  Tests Passed: $TESTS_PASSED"
echo "  Tests Failed: $TESTS_FAILED"
echo "  Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "🎉 All tests passed!"
    echo ""
    echo "🔗 Available Endpoints:"
    echo "  Health Check: $FUNCTION_URL/health"
    echo "  API Documentation: $FUNCTION_URL/"
    echo "  Users API: $FUNCTION_URL/api/users"
    echo "  Courses API: $FUNCTION_URL/api/courses"
    echo ""
    echo "📝 Example Commands:"
    echo "  curl $FUNCTION_URL/health"
    echo "  curl $FUNCTION_URL/api/users"
    echo "  curl -X POST $FUNCTION_URL/api/users -H 'Content-Type: application/json' -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\"}'"
    exit 0
else
    print_error "❌ Some tests failed. Please check the function deployment and configuration."
    exit 1
fi