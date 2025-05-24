#!/bin/bash

# Load environment variables based on NODE_ENV
# This script loads the appropriate .env file for the current environment

set -e

# Default to development if NODE_ENV is not set
NODE_ENV=${NODE_ENV:-development}

# Determine which environment file to load
case "$NODE_ENV" in
  "development")
    ENV_FILE=".env.development"
    ;;
  "production")
    ENV_FILE=".env.production"
    ;;
  *)
    echo "❌ Error: Unknown NODE_ENV '$NODE_ENV'. Must be 'development' or 'production'"
    exit 1
    ;;
esac

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: Environment file '$ENV_FILE' not found"
  exit 1
fi

# Load environment variables
echo "📋 Loading environment from $ENV_FILE"
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)

# Validate required environment variables
if [ -z "$NODE_ENV" ]; then
  echo "❌ Error: NODE_ENV is not set"
  exit 1
fi

if [ -z "$PORT" ]; then
  echo "❌ Error: PORT is not set"
  exit 1
fi

echo "✅ Environment loaded successfully"
echo "   NODE_ENV: $NODE_ENV"
echo "   PORT: $PORT"
echo "   LOG_LEVEL: $LOG_LEVEL"

# Export all variables for use in other scripts
export NODE_ENV
export PORT
export LOG_LEVEL
export MAX_REQUEST_SIZE
export TIMEOUT_MS
export CORS_ORIGINS
export FUNCTION_VERSION
export FUNCTION_REGION
export FUNCTION_MEMORY