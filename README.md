# GCP Hono.js Serverless Application

A production-ready serverless Node.js application built with Hono.js framework, deployed to Google Cloud Platform (GCP) as a Cloud Function using Terraform for Infrastructure as Code.

## 🚀 Features

- **Hono.js Framework**: Fast, lightweight web framework for Node.js 20+
- **Two API Routes**: Health check and User management endpoints
- **GCP Cloud Functions**: Serverless deployment with 1GB memory allocation
- **Terraform IaC**: Complete infrastructure management and version control
- **Automatic Version Management**: Tracks deployments and prunes old versions
- **Asia South Region**: Optimized for `asia-south1` deployment
- **Production Ready**: Comprehensive error handling and security considerations

## 📁 Project Structure

```
gcp-hono-serverless/
├── src/
│   └── index.js                 # Main Hono.js application with 2 API routes
├── terraform/
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Terraform variables definition
│   ├── outputs.tf               # Terraform outputs
│   └── terraform.tfvars.example # Example configuration file
├── scripts/
│   ├── deploy.sh               # Comprehensive deployment script
│   └── destroy.sh              # Infrastructure destruction script
├── package.json                # Node.js dependencies and scripts
└── README.md                   # This file
```
## 📜 Scripts Overview

The `scripts/` directory contains essential automation tools for managing your serverless application lifecycle. Each script serves a specific purpose in the development and deployment workflow:

### 🚀 [`deploy.sh`](scripts/deploy.sh:1) - Comprehensive Deployment Script
**Purpose**: Automates the complete deployment process to GCP Cloud Functions with version management.

**What it does:**
- **Prerequisites Check**: Validates Node.js 20+, Terraform, gcloud CLI installation and authentication
- **Configuration Validation**: Ensures `terraform.tfvars` is properly configured with valid project ID
- **Dependency Management**: Installs Node.js dependencies automatically
- **Version Management**: Auto-increments version numbers and tracks deployments in `.deployment-version`
- **Infrastructure Deployment**: Creates/updates GCP resources using Terraform
- **Health Validation**: Tests deployed function endpoints to ensure they're working
- **Cleanup**: Removes temporary files and prunes old deployment versions
- **Comprehensive Logging**: Detailed logs saved to `deployment.log` for troubleshooting

**Usage:**
```bash
npm run deploy
# or
bash scripts/deploy.sh
```

### 🗑️ [`destroy.sh`](scripts/destroy.sh:1) - Infrastructure Destruction Script
**Purpose**: Safely removes all GCP infrastructure and cleans up resources to prevent ongoing costs.

**What it does:**
- **Safety Confirmation**: Prompts for confirmation before destroying resources (unless `--force` used)
- **Storage Cleanup**: Empties Cloud Storage buckets before deletion
- **Infrastructure Removal**: Uses Terraform to destroy all GCP resources
- **State Management**: Optionally cleans up Terraform state files
- **Version Cleanup**: Optionally removes version tracking files
- **Log Cleanup**: Optionally removes deployment logs
- **Cost Prevention**: Ensures no resources are left running to incur charges

**Usage:**
```bash
npm run destroy
# or
bash scripts/destroy.sh

# Advanced options:
bash scripts/destroy.sh --force --clean-all  # Skip confirmation, clean everything
```

### ✅ [`validate.sh`](scripts/validate.sh:1) - Project Validation Script
**Purpose**: Pre-deployment health check that validates your entire setup is ready for deployment.

**What it validates:**
- **Project Structure**: Ensures all required files exist in correct locations
- **Node.js Environment**: Checks Node.js 20+ version and npm installation
- **Dependencies**: Verifies Hono.js dependencies are installed and configured
- **Terraform Configuration**: Tests syntax and validates variable configuration
- **GCP Setup**: Confirms gcloud authentication and project access
- **Source Code**: Validates Hono.js imports, required routes, and Cloud Function exports
- **Scripts**: Checks deployment scripts are properly configured

**Why use it:**
- **Prevents Deployment Failures**: Catches issues before expensive deployment attempts
- **Saves Time**: Identifies configuration problems early in the process
- **Production Safety**: Ensures critical settings like memory allocation are correct

**Usage:**
```bash
bash scripts/validate.sh
```

### 🔧 [`dev.sh`](scripts/dev.sh:1) - Local Development Server (Unix/Linux/macOS)
**Purpose**: Starts the Hono.js application locally for development and testing.

**What it does:**
- **Environment Setup**: Configures development environment variables
- **Dependency Check**: Ensures Node.js 20+ and dependencies are installed
- **Auto-install**: Installs dependencies if `node_modules` is missing
- **Development Server**: Starts server with hot-reload on port 8080
- **Endpoint Information**: Displays available API endpoints for testing

**Usage:**
```bash
npm run dev
# or
bash scripts/dev.sh
```

### 🔧 [`dev.bat`](scripts/dev.bat:1) - Local Development Server (Windows)
**Purpose**: Windows batch file equivalent of `dev.sh` for Windows users.

**What it does:**
- Same functionality as `dev.sh` but optimized for Windows Command Prompt
- **Windows Compatibility**: Uses Windows-specific commands and path handling
- **Visual Feedback**: Provides clear console output with Windows-friendly formatting

**Usage:**
```cmd
npm run dev
REM or
scripts\dev.bat
```

## 🔄 Script Workflow

**Typical Development Workflow:**
1. **Validate Setup**: `bash scripts/validate.sh` - Ensure everything is configured
2. **Local Development**: `npm run dev` - Test changes locally
3. **Deploy**: `npm run deploy` - Deploy to GCP when ready
4. **Cleanup**: `npm run destroy` - Remove infrastructure when done

**Production Deployment:**
1. **Pre-deployment Check**: `bash scripts/validate.sh`
2. **Deploy**: `bash scripts/deploy.sh`
3. **Monitor**: Check deployment logs and function URLs

##  Prerequisites

Before deploying this application, ensure you have:

1. **Node.js 20+** installed
2. **Google Cloud SDK (gcloud)** installed and configured
3. **Terraform** installed (version 1.0+)
4. **GCP Project** with billing enabled
5. **Required GCP APIs** enabled (will be enabled automatically during deployment)

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
# Install Node.js dependencies
npm install
```

### 2. Configure GCP Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set your default project (optional)
gcloud config set project YOUR_PROJECT_ID
```

### 3. Configure Terraform Variables

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

## 🚀 Deployment

### Quick Deployment

```bash
# Deploy the entire application
npm run deploy

# Or use the script directly
bash scripts/deploy.sh
```

### Manual Deployment Steps

```bash
# 1. Initialize Terraform
npm run tf-init

# 2. Plan the deployment
npm run tf-plan

# 3. Apply the infrastructure
npm run tf-apply
```

### Deployment Process

The deployment script performs the following steps:

1. **Prerequisites Check**: Validates required tools and authentication
2. **Configuration Validation**: Ensures Terraform variables are properly set
3. **Dependency Installation**: Installs Node.js dependencies
4. **Version Management**: Automatically increments version number
5. **Infrastructure Deployment**: Creates/updates GCP resources using Terraform
6. **Health Check**: Validates the deployed function is working
7. **Cleanup**: Removes temporary files and old versions

## 🔗 API Endpoints

After successful deployment, your application will expose the following endpoints:

### 1. Root Endpoint
```
GET /
```
Returns API information and available endpoints.

### 2. Health Check
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
  "memory": "1GB"
}
```

### 3. Users API
```
GET /api/users?page=1&limit=10
POST /api/users
```

**GET Example Response:**
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
    "total": 3,
    "totalPages": 1
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**POST Example Request:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com"
}
```

## 🧪 Local Development

```bash
# Run the application locally
npm run dev

# The server will start on http://localhost:8080
# Test endpoints:
# - http://localhost:8080/health
# - http://localhost:8080/api/users
```

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

## 🔧 Configuration Options

### Memory and Performance

The application is configured for 1GB memory allocation as required. You can modify this in `terraform/terraform.tfvars`:

```hcl
memory_mb = "1024"  # Options: 128, 256, 512, 1024, 2048, 4096, 8192
```

### Scaling Configuration

```hcl
max_instances = 100  # Maximum concurrent instances
min_instances = 0    # Minimum instances (0 for cost optimization)
timeout_seconds = 60 # Function timeout (1-540 seconds)
```

### Region Configuration

```hcl
region = "asia-south1"  # Target deployment region
```

## 📝 Logs and Monitoring

### Deployment Logs

```bash
# View deployment logs
cat deployment.log

# View destruction logs
cat destruction.log
```

### GCP Logs

```bash
# View function logs
gcloud functions logs read hono-serverless-api --region=asia-south1

# Follow live logs
gcloud functions logs tail hono-serverless-api --region=asia-south1
```

## 🔒 Security Considerations

- **IAM Configuration**: Function allows unauthenticated access (configurable)
- **CORS**: Not configured by default (add if needed for web clients)
- **Input Validation**: Basic validation implemented for user creation
- **Error Handling**: Comprehensive error handling with proper HTTP status codes

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Terraform State Issues**
   ```bash
   cd terraform
   terraform init -reconfigure
   ```

3. **Function Not Responding**
   - Check GCP Console for function logs
   - Verify function is deployed in correct region
   - Check IAM permissions

4. **Version Conflicts**
   ```bash
   # Reset version tracking
   rm .deployment-version
   ```

### Getting Help

- Check deployment logs: `cat deployment.log`
- View GCP function logs in the Console
- Verify Terraform state: `terraform show`

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Note**: This application is production-ready but uses mock data for demonstration. In a real-world scenario, you would integrate with actual databases and external services.