# GCP TypeScript Hono.js Serverless Application

A production-ready serverless TypeScript application built with Hono.js framework, featuring CORS support, environment-specific configurations, modular architecture, and hot reload development. Deployed to Google Cloud Platform (GCP) as a Cloud Function using Google Cloud Build for automated CI/CD.

## 🚀 Features

- **TypeScript Support**: Full TypeScript implementation with hot reload development
- **Modular Architecture**: Clean, scalable code organization with domain-separated routes
- **CORS Configuration**: Environment-specific CORS setup for localhost:3000 and localhost:3001
- **Environment Separation**: Distinct development and production configurations
- **Enhanced Logging**: Structured logging with different levels and request tracking
- **Type Safety**: Comprehensive TypeScript types for all API responses and requests
- **Hot Reload**: Development server with automatic TypeScript compilation using tsx
- **Code Quality**: Biome linting/formatting for .ts and .js files
- **Security**: Environment-specific CORS validation and comprehensive error handling
- **Cloud Build CI/CD**: Branch-based deployment automation with Google Cloud Build
- **Health Check API**: Built-in health monitoring and status endpoints

## 📁 Project Structure

```
gcp-hono-serverless/
├── src/
│   ├── config/
│   │   └── environment.ts       # Environment configuration and validation
│   ├── types/
│   │   ├── common.ts           # Common type definitions
│   │   ├── user.ts             # User-related types
│   │   └── course.ts           # Course-related types
│   ├── utils/
│   │   ├── logs/
│   │   │   └── logger.ts       # Enhanced logging utility
│   │   └── formatters/
│   │       └── index.ts        # Data formatting and validation utilities
│   ├── routes/
│   │   ├── index.ts            # Main routes configuration with health check
│   │   ├── user/
│   │   │   ├── index.ts        # User routes setup
│   │   │   ├── get.ts          # Get users functionality
│   │   │   ├── get-by-id.ts    # Get user by ID
│   │   │   ├── create.ts       # User creation
│   │   │   └── update.ts       # User updates
│   │   └── course/
│   │       ├── index.ts        # Course routes setup
│   │       ├── get.ts          # Get courses functionality
│   │       ├── get-by-id.ts    # Get course by ID
│   │       ├── create.ts       # Course creation
│   │       └── update.ts       # Course updates
│   ├── schema/
│   │   ├── user/               # User validation schemas
│   │   └── course/             # Course validation schemas
│   └── index.ts                # Main application entry point
├── dist/                       # Compiled TypeScript output (generated)
├── scripts/
│   ├── deploy-local.sh         # Local deployment script
│   ├── test-api.sh             # API testing script
│   ├── validate.sh             # Project validation script
│   ├── dev.sh                  # Linux/Mac development server
│   └── dev.bat                 # Windows development server
├── cloudbuild.yaml             # Google Cloud Build configuration
├── .env.development            # Development environment variables
├── .env.production             # Production environment variables
├── tsconfig.json               # TypeScript configuration
├── biome.json                  # Biome linting/formatting configuration
├── package.json                # Node.js dependencies and scripts
└── README.md                   # This file
```

## 📋 Prerequisites

Before deploying this application, ensure you have:

1. **Node.js 20+** installed
2. **TypeScript** support (installed via npm dependencies)
3. **Google Cloud SDK (gcloud)** installed and configured
4. **GCP Project** with billing enabled
5. **Required GCP APIs** enabled (see manual setup section below)

### Install Prerequisites

```bash
# Install Node.js 20+ (using nvm)
nvm install 20
nvm use 20

# Install Google Cloud SDK
# macOS (using Homebrew)
brew install --cask google-cloud-sdk

# Windows (using Chocolatey)
choco install gcloudsdk

# Linux (using package manager)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

## 🔧 Setup

### 1. Clone and Install Dependencies

```bash
# Install Node.js dependencies (includes TypeScript and development tools)
npm install
# or
pnpm install
```

### 2. Configure Environment Variables

The application uses environment-specific configuration files:

#### Development Environment (Pre-configured)
The `.env.development` file is already configured with:
- CORS origins for localhost:3000 and localhost:3001
- Debug logging level
- Development-appropriate settings

#### Production Environment (Requires Configuration)
Edit `.env.production` for your production environment:

```bash
# Production Environment Configuration
NODE_ENV=production
PORT=8080
LOG_LEVEL=info
MAX_REQUEST_SIZE=5mb

# Production CORS origins (add your domains)
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Function metadata (will be overridden by GCP environment)
FUNCTION_VERSION=1.0.0
FUNCTION_REGION=asia-south1
FUNCTION_MEMORY=1GB
```

### 3. Configure GCP Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set your default project
gcloud config set project YOUR_PROJECT_ID
```

### 4. Enable Required GCP APIs (Manual Setup)

**IMPORTANT**: The following APIs must be enabled manually before deployment:

```bash
# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled --filter="name:(cloudfunctions.googleapis.com OR cloudbuild.googleapis.com OR run.googleapis.com)"
```

## 🚀 Development

### Development Scripts

```bash
# Start development server with hot reload (development environment)
npm run dev

# Start development server with production environment variables
npm run dev:prod

# Build TypeScript to JavaScript
npm run build

# Watch mode for TypeScript compilation
npm run build:watch

# Lint TypeScript and JavaScript files
npm run lint

# Format code with Biome
npm run format:fix

# Check and fix all code issues
npm run check:fix

# Validate project configuration
npm run validate
```

### Development Environment Features

The development environment includes:

- **Hot Reload**: Automatic restart on TypeScript file changes using tsx
- **CORS Support**: Pre-configured for localhost:3000 and localhost:3001
- **Debug Logging**: Detailed structured logging for development
- **Environment Validation**: Automatic validation of environment variables
- **TypeScript Compilation**: Real-time TypeScript compilation
- **Request Logging**: Detailed HTTP request/response logging

### Test Endpoints

```bash
# Health check with environment information
curl http://localhost:8080/health

# Users API with pagination
curl http://localhost:8080/api/users?page=1&limit=5

# Get specific user
curl http://localhost:8080/api/users/1

# Create user (POST request)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Update user
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"John Updated","email":"john.updated@example.com"}'

# Courses API with filtering
curl http://localhost:8080/api/courses?level=beginner&page=1&limit=5

# Create course
curl -X POST http://localhost:8080/api/courses \
  -H "Content-Type: application/json" \
  -d '{"title":"New Course","description":"Course description","instructor":"Jane Doe","duration":40,"level":"intermediate"}'

# Test CORS (from allowed origins)
# Open browser console on http://localhost:3000 and run:
# fetch('http://localhost:8080/health').then(r => r.json()).then(console.log)
```

## 🚀 Deployment

### Local Deployment

Use the local deployment scripts for manual deployment:

```bash
# Deploy to development environment
npm run deploy:dev

# Deploy to production environment
npm run deploy:prod

# Or use the script directly
bash scripts/deploy-local.sh development
bash scripts/deploy-local.sh production
```

### Cloud Build Deployment (Automated CI/CD)

The application uses Google Cloud Build for automated deployment based on Git branches:

#### Branch-Based Deployment Strategy

1. **Development Environment**: Push to `dev` branch
   - Deploys to `hono-serverless-api-dev` function
   - Uses `.env.development` configuration
   - Fallback to GitHub Secrets with `_DEV_*` prefix

2. **Production Environment**: Push to `production` branch
   - Deploys to `hono-serverless-api` function
   - Uses `.env.production` configuration
   - Fallback to GitHub Secrets with `_PROD_*` prefix

#### Setting up Cloud Build Triggers

1. **Connect Repository to Cloud Build**:
   ```bash
   # Enable Cloud Build API (if not already done)
   gcloud services enable cloudbuild.googleapis.com
   
   # Connect your repository (GitHub/GitLab/Bitbucket)
   # This is done through the Cloud Console UI
   ```

2. **Create Build Triggers**:
   
   **Development Trigger**:
   - Name: `deploy-development`
   - Event: Push to branch
   - Branch: `^dev$`
   - Configuration: Cloud Build configuration file
   - Cloud Build configuration file location: `cloudbuild.yaml`

   **Production Trigger**:
   - Name: `deploy-production`
   - Event: Push to branch
   - Branch: `^production$`
   - Configuration: Cloud Build configuration file
   - Cloud Build configuration file location: `cloudbuild.yaml`

3. **Configure GitHub Secrets (Optional Fallback)**:
   
   If environment files are not present, the system falls back to these substitution variables:
   
   ```yaml
   # Development secrets
   _DEV_CORS_ORIGINS: 'http://localhost:3000,http://localhost:3001'
   _DEV_FUNCTION_VERSION: 'dev-${SHORT_SHA}'
   _DEV_FUNCTION_REGION: 'asia-south1'
   _DEV_FUNCTION_MEMORY: '1GB'
   
   # Production secrets
   _PROD_CORS_ORIGINS: 'https://yourdomain.com'
   _PROD_FUNCTION_VERSION: 'prod-${SHORT_SHA}'
   _PROD_FUNCTION_REGION: 'asia-south1'
   _PROD_FUNCTION_MEMORY: '1GB'
   ```

### Deployment Process

The Cloud Build deployment performs the following steps:

1. **Environment Detection**: Determines target environment based on branch name
2. **Configuration Loading**: Loads environment-specific configuration with fallback to secrets
3. **Dependency Installation**: Installs Node.js dependencies
4. **TypeScript Build**: Compiles TypeScript to JavaScript
5. **Package Preparation**: Creates deployment package with necessary files
6. **Function Deployment**: Deploys to Google Cloud Functions (Gen 2)
7. **Health Check**: Validates the deployed function is working correctly

## 🔗 API Endpoints

After successful deployment, your application will expose the following endpoints:

### Core Endpoints

#### Root Endpoint
```
GET /
```
Returns API information and available endpoints.

#### Health Check
```
GET /health
```
Returns application health status, version, and configuration details.

**Example Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "v1.0.1",
    "region": "asia-south1",
    "memory": "1GB",
    "environment": "production",
    "cors_origins": ["https://yourdomain.com"]
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### User Management API

#### Get Users
```
GET /api/users?page=1&limit=10
```

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created": "2024-01-15"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 5,
    "totalPages": 1
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### Get User by ID
```
GET /api/users/:id
```

#### Create User
```
POST /api/users
```

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com"
}
```

#### Update User
```
PUT /api/users/:id
```

### Course Management API

#### Get Courses
```
GET /api/courses?page=1&limit=10&level=beginner
```

#### Get Course by ID
```
GET /api/courses/:id
```

#### Create Course
```
POST /api/courses
```

**Request Body:**
```json
{
  "title": "Introduction to TypeScript",
  "description": "Learn TypeScript fundamentals",
  "instructor": "John Smith",
  "duration": 40,
  "level": "beginner"
}
```

#### Update Course
```
PUT /api/courses/:id
```

## 🧪 Testing

### API Testing

Use the built-in API testing script to validate your deployment:

```bash
# Test development environment
npm run test:api:dev

# Test production environment
npm run test:api:prod

# Or use the script directly
bash scripts/test-api.sh development
bash scripts/test-api.sh production
```

The test script performs comprehensive API testing including:
- Health check validation
- CRUD operations for users and courses
- Error handling verification
- Response format validation

### Project Validation

Validate your project configuration before deployment:

```bash
# Run complete project validation
npm run validate

# Or use the script directly
bash scripts/validate.sh
```

The validation script checks:
- Project structure and required files
- Node.js and dependency setup
- Google Cloud Build configuration
- GCP authentication and API enablement
- Environment configuration
- Source code structure
- TypeScript compilation

## 🛠️ Development Tools

### TypeScript Configuration

The project uses TypeScript with strict configuration for type safety:

```json
// tsconfig.json highlights
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### Biome Linting and Formatting

Biome is configured to handle both TypeScript and JavaScript files:

```bash
# Lint all files
npm run lint

# Fix linting issues
npm run lint:fix

# Format code
npm run format:fix

# Check and fix all issues
npm run check:fix
```

#### Biome Features
- **TypeScript Support**: Full .ts and .js file support
- **Import Organization**: Automatic import sorting and cleanup
- **Code Formatting**: Consistent code style enforcement
- **Error Detection**: Advanced linting rules for code quality
- **Performance**: Fast linting and formatting

### Enhanced Logging

The application includes a sophisticated logging system:

```typescript
import { logger } from './utils/logs/logger.js'

// Structured logging with metadata
logger.info('User created', { userId: 123, email: 'user@example.com' })
logger.error('Database error', error, { operation: 'user_create' })
logger.request('GET', '/api/users', 200, 150) // HTTP request logging
```

## 🌐 CORS Configuration

### Environment-Specific CORS Setup

The application includes comprehensive CORS support with environment-specific origins:

#### Development Environment
```bash
# Automatically configured in .env.development
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000,http://127.0.0.1:3001
```

#### Production Environment
```bash
# Configure in .env.production
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com,https://app.yourdomain.com
```

### CORS Features

- **Origin Validation**: Strict origin checking based on environment
- **Credentials Support**: Enabled for authenticated requests
- **Method Control**: Supports GET, POST, PUT, DELETE, OPTIONS
- **Header Management**: Configurable allowed and exposed headers
- **Caching**: Environment-specific cache control (no cache in dev, 24h in prod)

### Testing CORS

```javascript
// Test from allowed origin (e.g., http://localhost:3000)
fetch('http://localhost:8080/api/users')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('CORS Error:', error))
```

## 🔧 Configuration Management

### Environment Configuration Priority

The deployment system uses the following priority order for configuration:

1. **Local Environment Files** (`.env.development`, `.env.production`)
2. **GitHub Secrets/Cloud Build Substitutions** (fallback)
3. **Default Values** (final fallback)

### Cloud Build Configuration

The `cloudbuild.yaml` file includes:

- **Branch Detection**: Automatic environment detection based on Git branch
- **Environment Loading**: Smart configuration loading with fallback mechanisms
- **Build Optimization**: Efficient caching and parallel processing
- **Health Checks**: Automatic deployment validation
- **File Ignoring**: Optimized source upload excluding unnecessary files

### Function Configuration

Cloud Functions are configured with:

- **Runtime**: Node.js 20
- **Memory**: Configurable (default: 1GB)
- **Timeout**: 60 seconds
- **Scaling**: 0-100 instances (configurable)
- **Trigger**: HTTP with unauthenticated access
- **Environment Variables**: Automatic injection of configuration

## 🚨 Troubleshooting

### Common Issues

1. **Deployment Fails with API Not Enabled**:
   ```bash
   # Enable required APIs
   gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com run.googleapis.com
   ```

2. **Authentication Errors**:
   ```bash
   # Re-authenticate
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **TypeScript Compilation Errors**:
   ```bash
   # Clean and rebuild
   rm -rf dist node_modules
   npm install
   npm run build
   ```

4. **CORS Issues**:
   - Check CORS_ORIGINS in environment files
   - Verify origin matches exactly (including protocol and port)
   - Test from allowed origins only

5. **Function Not Responding**:
   - Check Cloud Function logs: `gcloud functions logs read FUNCTION_NAME`
   - Verify health check endpoint: `curl FUNCTION_URL/health`
   - Check environment variables in Cloud Console

### Debug Commands

```bash
# Check function status
gcloud functions describe FUNCTION_NAME --region=REGION

# View function logs
gcloud functions logs read FUNCTION_NAME --region=REGION --limit=50

# Test local deployment
bash scripts/deploy-local.sh development

# Validate project setup
bash scripts/validate.sh

# Test API endpoints
bash scripts/test-api.sh development
```

## 📚 Additional Resources

- [Google Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Google Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Hono.js Documentation](https://hono.dev/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Jackson Kasi**

---

**Note**: This project has been completely refactored to eliminate Terraform dependencies and use Google Cloud Build for deployment. All Terraform-related files and references have been removed and replaced with a modern, simplified Cloud Build-based deployment system.