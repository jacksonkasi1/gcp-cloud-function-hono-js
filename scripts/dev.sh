#!/bin/bash

# =============================================================================
# Local Development Server Script
# =============================================================================
# This script starts the Hono.js application in development mode with
# automatic reloading and helpful development features
# =============================================================================

set -euo pipefail

# Color codes for output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PORT=${PORT:-8080}

echo -e "${BLUE}🚀 Starting Hono.js Development Server${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "${GREEN}Project Root:${NC} $PROJECT_ROOT"
echo -e "${GREEN}Port:${NC} $PORT"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js is not installed or not in PATH${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | sed 's/v//')
MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

if [ "$MAJOR_VERSION" -lt 20 ]; then
    echo -e "${YELLOW}⚠️  Node.js version 20 or higher is required. Current version: $NODE_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js version:${NC} $NODE_VERSION"

# Change to project root
cd "$PROJECT_ROOT"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    npm install
fi

echo ""
echo -e "${GREEN}🌐 Server will be available at:${NC}"
echo -e "   ${BLUE}http://localhost:$PORT${NC}"
echo -e "   ${BLUE}http://localhost:$PORT/health${NC} (Health Check)"
echo -e "   ${BLUE}http://localhost:$PORT/api/users${NC} (Users API)"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Set environment variables for development
export NODE_ENV=development
export PORT=$PORT

# Start the development server
npm run dev