# GCP TypeScript Hono.js Serverless Application

A production-ready serverless TypeScript application built with Hono.js framework, featuring CORS support, environment-specific configurations, modular architecture, and hot reload development. Deployed to Google Cloud Platform (GCP) as a Cloud Function using Terraform for Infrastructure as Code.

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
│   │   ├── index.ts            # Main routes configuration
│   │   ├── user/
│   │   │   ├── index.ts        # User routes setup
│   │   │   ├── get-user.ts     # Get users functionality
│   │   │   └── user-profile.ts # User profile management
│   │   └── course/
│   │       ├── index.ts        # Course routes setup
│   │       ├── get-course.ts   # Get courses functionality
│   │       └── create-course.ts # Course creation and updates
│   └── index.ts                # Main application entry point
├── dist/                       # Compiled TypeScript output (generated)
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Terraform variables definition
│   ├── outputs.tf              # Terraform outputs
│   └── terraform.tfvars.example # Example configuration file
├── scripts/
│   ├── deploy.sh              # Environment-aware deployment script
│   ├── destroy.sh             # Infrastructure destruction script
│   ├── dev.sh                 # TypeScript development server
│   ├── dev.bat                # Windows development server
│   ├── load-env.sh            # Environment configuration loader
│   └── validate.sh            # Project validation script
├── .env.development           # Development environment variables
├── .env.production            # Production environment variables
├── tsconfig.json              # TypeScript configuration
├── biome.json                 # Biome linting/formatting configuration
├── package.json               # Node.js dependencies and scripts
└── README.md                  # This file
```

## 📋 Prerequisites

Before deploying this application, ensure you have:

1. **Node.js 20+** installed
2. **TypeScript** support (installed via npm dependencies)
3. **Google Cloud SDK (gcloud)** installed and configured
4. **Terraform** installed (version 1.0+)
5. **GCP Project** with billing enabled
6. **Required GCP APIs** enabled (will be enabled automatically during deployment)

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

# Install Terraform
# macOS (using Homebrew)
brew install terraform

# Windows (using Chocolatey)
choco install terraform
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

# Set your default project (optional)
gcloud config set project YOUR_PROJECT_ID
```

### 4. Configure Terraform Variables

```bash
# Copy the example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the configuration with your project details
nano terraform/terraform.tfvars
```

**Required Configuration in `terraform/terraform.tfvars`:**

```hcl
# GCP Project Configuration
project_id = "your-actual-gcp-project-id"  # REQUIRED: Replace with your GCP project ID
region     = "asia-south1"                 # Target region (default)

# Function Configuration
function_name    = "hono-serverless-api"   # Name of your Cloud Function
memory_mb        = "1024"                  # Memory allocation (1GB as required)
timeout_seconds  = 60                     # Function timeout
max_instances    = 100                     # Maximum concurrent instances
min_instances    = 0                      # Minimum instances (0 for cost optimization)

# Version Management
deployment_version    = "v1.0.0"          # Initial version
max_versions_to_keep = 5                  # Number of versions to retain
enable_version_cleanup = true             # Enable automatic cleanup

# Environment
environment = "prod"                      # Environment identifier
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

### Environment-Specific Deployment

```bash
# Deploy to production (default)
npm run deploy:prod

# Deploy to development
npm run deploy:dev

# Or use the script directly with environment
NODE_ENV=production bash scripts/deploy.sh
NODE_ENV=development bash scripts/deploy.sh
```

### Quick Deployment (Production)

```bash
# Deploy the entire application to production
npm run deploy

# Or use the script directly
bash scripts/deploy.sh
```

### TypeScript Deployment Process

The deployment script performs the following steps:

1. **Environment Loading**: Loads environment-specific configuration
2. **Prerequisites Check**: Validates required tools and authentication
3. **TypeScript Setup Check**: Validates TypeScript configuration and source files
4. **Configuration Validation**: Ensures Terraform variables are properly set
5. **CORS Validation**: Validates environment-specific CORS configuration
6. **Dependency Installation**: Installs Node.js and TypeScript dependencies
7. **TypeScript Build**: Compiles TypeScript to JavaScript in dist/ directory
8. **Version Management**: Automatically increments version number
9. **Infrastructure Deployment**: Creates/updates GCP resources using Terraform
10. **Health Check**: Validates the deployed function is working
11. **Cleanup**: Removes temporary files and old versions

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
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "v1.0.1",
  "region": "asia-south1",
  "memory": "1GB",
  "environment": "production",
  "cors_origins": ["https://yourdomain.com"]
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

## 🔧 Environment Management

### Environment Separation

The application maintains strict separation between development and production:

#### Development Configuration
- **CORS**: Permissive for localhost origins (3000, 3001)
- **Logging**: Debug level with detailed output
- **Error Handling**: Detailed error messages for debugging
- **Request Size**: Larger limits for development testing (10mb)
- **Hot Reload**: Enabled with tsx

#### Production Configuration
- **CORS**: Restrictive, requires explicit origin configuration
- **Logging**: Info level, production-appropriate
- **Error Handling**: Generic error messages for security
- **Request Size**: Conservative limits for security (5mb)
- **Performance**: Optimized for production workloads

### Environment Variables Validation

The application includes comprehensive environment validation:

```typescript
// Automatic validation on startup
- NODE_ENV: Must be 'development' or 'production'
- PORT: Must be valid port number (1-65535)
- CORS_ORIGINS: Validated format and accessibility
- LOG_LEVEL: Must be valid log level
- MAX_REQUEST_SIZE: Must be valid size format
```

## 🔒 Security Considerations

- **Environment Separation**: Strict separation prevents dev settings in production
- **CORS Validation**: Environment-specific origin validation with localhost:3000 and localhost:3001 support
- **Input Validation**: Enhanced validation with TypeScript types and comprehensive error handling
- **Error Handling**: Environment-appropriate error messages (detailed in dev, generic in prod)
- **Request Limits**: Configurable request size limits based on environment
- **Logging**: Secure logging that doesn't expose sensitive data
- **Type Safety**: TypeScript ensures type safety across the entire application

## 📊 Version Management

The application includes automatic version management:

- **Automatic Versioning**: Each deployment increments the patch version
- **Version Tracking**: Current version stored in `.deployment-version`
- **Storage Cleanup**: Automatically removes old function source archives
- **Bucket Lifecycle**: Configured to retain only the latest 5 versions

### Manual Version Control

```bash
# Check current version
cat .deployment-version

# Deploy specific version
cd terraform
terraform apply -var="deployment_version=v2.0.0"
```

## 🗑 Cleanup and Removal

### Complete Infrastructure Removal

```bash
# Remove all infrastructure
npm run destroy

# Or use the script directly
bash scripts/destroy.sh
```

### Advanced Cleanup Options

```bash
# Force removal without confirmation
bash scripts/destroy.sh --force

# Remove all local files (state, versions, logs)
bash scripts/destroy.sh --clean-all

# Remove only Terraform state
bash scripts/destroy.sh --clean-state
```

## 🐛 Troubleshooting

### Common Issues

1. **NODE_ENV Error**
   ```bash
   # Fixed with cross-env in package.json
   npm run dev  # Now works correctly
   ```

2. **TypeScript Build Errors**
   ```bash
   # Check TypeScript configuration
   npm run build
   # Fix any type errors before deployment
   ```

3. **CORS Issues**
   - Verify CORS_ORIGINS in environment files
   - Check browser console for CORS errors
   - Ensure origins match exactly (including protocol)

4. **Authentication Error**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

5. **Terraform State Issues**
   ```bash
   cd terraform
   terraform init -reconfigure
   ```

### Getting Help

- Check deployment logs: `cat deployment-production.log` or `cat deployment-development.log`
- View GCP function logs in the Console
- Verify Terraform state: `terraform show`
- Check development server logs in terminal

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the modular architecture
4. Test thoroughly with both `npm run dev` and `npm run dev:prod`
5. Run linting and formatting: `npm run check:fix`
6. Submit a pull request

---

**Note**: This application features a clean, modular architecture with comprehensive TypeScript support, environment separation, and production-ready deployment processes. The codebase is organized by domain (users, courses) with shared utilities and types for maximum maintainability and scalability.