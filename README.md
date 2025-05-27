# GCP TypeScript Hono.js Cloud Run Application

A production-ready containerized TypeScript application built with Hono.js framework, featuring CORS support, environment-specific configurations, modular architecture, and hot reload development. Deployed to Google Cloud Platform (GCP) as a Cloud Run service using Docker containers for scalable and efficient deployment.

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
- **Cloud Run Deployment**: Containerized deployment with automatic scaling and traffic management
- **Docker Support**: Multi-stage Docker builds with optimized container images
- **Health Check API**: Built-in health monitoring and status endpoints

## 📁 Project Structure

```
gcp-hono-cloudrun/
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
│   ├── deploy-simple.sh        # Cloud Run deployment script
│   ├── test-api.sh             # API testing script
│   ├── validate.sh             # Project validation script
│   ├── dev.sh                  # Linux/Mac development server
│   └── dev.bat                 # Windows development server
├── Dockerfile                  # Docker container configuration
├── .dockerignore               # Docker build exclusions
├── cloudbuild-cloudrun.yaml    # Google Cloud Build configuration for Cloud Run
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

# Cloud Run metadata (will be overridden by GCP environment)
CLOUD_RUN_VERSION=1.0.0
CLOUD_RUN_REGION=asia-south1
CLOUD_RUN_MEMORY=1Gi
CLOUD_RUN_CPU=1
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
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled --filter="name:(cloudbuild.googleapis.com OR run.googleapis.com OR containerregistry.googleapis.com)"
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

Use the deployment script for manual Cloud Run deployment:

```bash
# Deploy to development environment
npm run deploy:dev

# Deploy to production environment
npm run deploy:prod

# Or use the script directly
bash scripts/deploy-simple.sh development
bash scripts/deploy-simple.sh production
```

### Docker Deployment (Optional)

If you want to test locally with Docker:

```bash
# Build and run locally
docker build -t hono-cloudrun-app .
docker run -p 8080:8080 --env-file .env.development hono-cloudrun-app
curl http://localhost:8080/health
```

### Deployment Process

The deployment script automatically:

1. **Tries Docker-based deployment first** (using the Dockerfile)
2. **Falls back to source-based deployment** if Docker fails (no Docker knowledge required)
3. **Configures Cloud Run** with automatic scaling (0-10 instances)
4. **Sets up proper environment variables** and service account
5. **Validates deployment** and provides the service URL

#### Cloud Run Benefits

- **Automatic Scaling**: Scales from 0 to 10 instances based on traffic
- **Pay-per-use**: Only pay for actual request processing time
- **No Docker knowledge required**: Source-based deployment handles containerization
- **Better performance**: Higher concurrency than Cloud Functions

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