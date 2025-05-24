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

## 🛠 Prerequisites

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