#!/bin/bash

# =============================================================================
# TypeScript Development Server Script
# =============================================================================
# This script starts the Hono.js TypeScript application in development mode with
# hot reload, CORS support, and environment-specific configuration
# =============================================================================

set -euo pipefail

# Color codes for output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 Starting TypeScript Development Server${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Load development environment
export NODE_ENV=development
source "$SCRIPT_DIR/load-env.sh"

echo -e "${GREEN}Project Root:${NC} $PROJECT_ROOT"
echo -e "${GREEN}Environment:${NC} $NODE_ENV"
echo -e "${GREEN}Port:${NC} $PORT"
echo -e "${GREEN}CORS Origins:${NC} $CORS_ORIGINS"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed or not in PATH${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | sed 's/v//')
MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

if [ "$MAJOR_VERSION" -lt 20 ]; then
    echo -e "${RED}❌ Node.js version 20 or higher is required. Current version: $NODE_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js version:${NC} $NODE_VERSION"

# Check if TypeScript source exists
if [ ! -f "src/index.ts" ]; then
    echo -e "${RED}❌ TypeScript source file 'src/index.ts' not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ TypeScript source found${NC}"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    npm install
fi

# Check if TypeScript dependencies are available
if ! npm list tsx &> /dev/null; then
    echo -e "${YELLOW}📦 Installing TypeScript development dependencies...${NC}"
    npm install
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"

echo ""
echo -e "${GREEN}🌐 Development server will be available at:${NC}"
echo -e "   ${BLUE}http://localhost:$PORT${NC} (Main API)"
echo -e "   ${BLUE}http://localhost:$PORT/health${NC} (Health Check)"
echo -e "   ${BLUE}http://localhost:$PORT/api/users${NC} (Users API)"
echo ""
echo -e "${GREEN}🔧 Development Features:${NC}"
echo -e "   ${BLUE}✅ TypeScript compilation with hot reload${NC}"
echo -e "   ${BLUE}✅ CORS enabled for localhost:3000 and localhost:3001${NC}"
echo -e "   ${BLUE}✅ Enhanced logging and error handling${NC}"
echo -e "   ${BLUE}✅ Environment-specific configuration${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Start the TypeScript development server with hot reload
npm run dev