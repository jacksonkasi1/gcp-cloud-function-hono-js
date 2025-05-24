# CI/CD Setup Guide for GCP TypeScript Hono.js Serverless Application

This guide provides step-by-step instructions for setting up Continuous Integration and Continuous Deployment (CI/CD) pipelines using both GitLab CI/CD and GitHub Actions.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [GitLab CI/CD Setup](#gitlab-cicd-setup)
4. [GitHub Actions Setup](#github-actions-setup)
5. [Environment Configuration](#environment-configuration)
6. [Deployment Workflow](#deployment-workflow)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## 🎯 Overview

Our CI/CD pipeline supports:
- **Automatic validation** on all branches and pull requests
- **Development deployment** when pushing to `dev` branch
- **Production deployment** when pushing to `main` branch
- **Environment separation** with different configurations
- **Manual approval** for production deployments (GitLab)
- **Health checks** after deployment
- **Artifact management** and caching

### Pipeline Stages

1. **Validate** - Code linting and formatting checks
2. **Build** - TypeScript compilation
3. **Test** - Run test suite (placeholder for now)
4. **Deploy** - Environment-specific deployment to GCP

## 🔧 Prerequisites

Before setting up CI/CD, ensure you have:

### Google Cloud Platform Setup
1. **GCP Project** with billing enabled
2. **Service Account** with appropriate permissions
3. **Required APIs** enabled:
   - Cloud Functions API
   - Cloud Build API
   - Cloud Storage API
   - IAM API

### Required GCP Permissions
Your service account needs these roles:
- `Cloud Functions Admin`
- `Storage Admin`
- `Cloud Build Editor`
- `Service Account User`

### Local Development Setup
- Node.js 20+
- pnpm package manager
- Terraform 1.6+
- Google Cloud SDK

## 🦊 GitLab CI/CD Setup

### Step 1: Create Service Accounts

1. **Navigate to GCP Console** → IAM & Admin → Service Accounts
2. **Create Development Service Account**:
   ```bash
   gcloud iam service-accounts create gitlab-ci-dev \
     --display-name="GitLab CI Development" \
     --description="Service account for GitLab CI development deployments"
   ```

3. **Create Production Service Account**:
   ```bash
   gcloud iam service-accounts create gitlab-ci-prod \
     --display-name="GitLab CI Production" \
     --description="Service account for GitLab CI production deployments"
   ```

4. **Assign Roles**:
   ```bash
   # Development service account
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:gitlab-ci-dev@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/cloudfunctions.admin"
   
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:gitlab-ci-dev@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/storage.admin"
   
   # Production service account (repeat with gitlab-ci-prod)
   ```

5. **Generate Service Account Keys**:
   ```bash
   # Development key
   gcloud iam service-accounts keys create gitlab-ci-dev-key.json \
     --iam-account=gitlab-ci-dev@YOUR_PROJECT_ID.iam.gserviceaccount.com
   
   # Production key
   gcloud iam service-accounts keys create gitlab-ci-prod-key.json \
     --iam-account=gitlab-ci-prod@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

### Step 2: Configure GitLab Variables

1. **Navigate to** your GitLab project → Settings → CI/CD → Variables
2. **Add the following variables**:

| Variable Name | Value | Protected | Masked | Environment |
|---------------|-------|-----------|---------|-------------|
| `GCP_PROJECT_ID` | your-gcp-project-id | ✅ | ❌ | All |
| `GCP_SERVICE_ACCOUNT_KEY_DEV` | Base64 encoded dev key JSON | ✅ | ✅ | development |
| `GCP_SERVICE_ACCOUNT_KEY_PROD` | Base64 encoded prod key JSON | ✅ | ✅ | production |

**To encode service account keys**:
```bash
# For development
base64 -i gitlab-ci-dev-key.json | tr -d '\n' | pbcopy

# For production
base64 -i gitlab-ci-prod-key.json | tr -d '\n' | pbcopy
```

### Step 3: Configure Terraform Variables

1. **Create** `terraform/terraform.tfvars.dev`:
   ```hcl
   project_id = "your-gcp-project-id"
   region     = "asia-south1"
   function_name = "hono-serverless-api-dev"
   environment = "dev"
   deployment_version = "dev-latest"
   ```

2. **Create** `terraform/terraform.tfvars.prod`:
   ```hcl
   project_id = "your-gcp-project-id"
   region     = "asia-south1"
   function_name = "hono-serverless-api"
   environment = "prod"
   deployment_version = "v1.0.0"
   ```

### Step 4: Enable GitLab Environments

1. **Navigate to** Operations → Environments
2. **Create environments**:
   - `development` (auto-deploy from `dev` branch)
   - `production` (manual deploy from `main` branch)

### Step 5: Test the Pipeline

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/test-pipeline
   git push origin feature/test-pipeline
   ```

2. **Create a merge request** to `dev` branch
3. **Verify** validation pipeline runs
4. **Merge to `dev`** to trigger development deployment
5. **Merge to `main`** to trigger production deployment (manual approval required)

## 🐙 GitHub Actions Setup

### Step 1: Create Service Accounts

Follow the same steps as GitLab for creating GCP service accounts, but name them:
- `github-actions-dev`
- `github-actions-prod`

### Step 2: Configure GitHub Secrets

1. **Navigate to** your GitHub repository → Settings → Secrets and variables → Actions
2. **Add Repository Secrets**:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `GCP_PROJECT_ID` | your-gcp-project-id | Your GCP project ID |
| `GCP_SERVICE_ACCOUNT_KEY_DEV` | Dev service account JSON | Development deployment key |
| `GCP_SERVICE_ACCOUNT_KEY_PROD` | Prod service account JSON | Production deployment key |

**Service account JSON format**:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

### Step 3: Configure GitHub Environments

1. **Navigate to** Settings → Environments
2. **Create `development` environment**:
   - No protection rules needed
   - Auto-deploys from `dev` branch

3. **Create `production` environment**:
   - Add protection rule: Required reviewers
   - Add protection rule: Wait timer (optional)
   - Deploys from `main` branch

### Step 4: Test the Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/test-github-actions
   git push origin feature/test-github-actions
   ```

2. **Create a pull request** to `dev` branch
3. **Verify** validation workflow runs
4. **Merge to `dev`** to trigger development deployment
5. **Merge to `main`** to trigger production deployment

## ⚙️ Environment Configuration

### Development Environment (.env.development)
```bash
NODE_ENV=development
PORT=8080
LOG_LEVEL=debug
MAX_REQUEST_SIZE=10mb
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000,http://127.0.0.1:3001
FUNCTION_VERSION=dev-latest
FUNCTION_REGION=asia-south1
FUNCTION_MEMORY=1GB
```

### Production Environment (.env.production)
```bash
NODE_ENV=production
PORT=8080
LOG_LEVEL=info
MAX_REQUEST_SIZE=5mb
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
FUNCTION_VERSION=1.0.0
FUNCTION_REGION=asia-south1
FUNCTION_MEMORY=1GB
```

## 🚀 Deployment Workflow

### Branch Strategy

```
main (production)
├── dev (development)
│   ├── feature/new-feature-1
│   ├── feature/new-feature-2
│   └── hotfix/urgent-fix
└── hotfix/critical-production-fix
```

### Deployment Flow

1. **Feature Development**:
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/your-feature
   # Make changes
   git commit -m "feat: add new feature"
   git push origin feature/your-feature
   # Create PR/MR to dev
   ```

2. **Development Deployment**:
   ```bash
   # After PR/MR is merged to dev
   git checkout dev
   git pull origin dev
   # Automatic deployment to development environment
   ```

3. **Production Deployment**:
   ```bash
   # After testing in development
   git checkout main
   git pull origin main
   git merge dev
   git push origin main
   # Manual approval required for production deployment
   ```

### Deployment URLs

- **Development**: `https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/hono-serverless-api-dev`
- **Production**: `https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/hono-serverless-api`

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Errors
**Problem**: `Error: Could not load the default credentials`

**Solution**:
```bash
# Verify service account key is correctly encoded
echo $GCP_SERVICE_ACCOUNT_KEY_DEV | base64 -d | jq .

# Check if service account has required permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:YOUR_SERVICE_ACCOUNT_EMAIL"
```

#### 2. Terraform State Issues
**Problem**: `Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
cd terraform
terraform force-unlock LOCK_ID
```

#### 3. Function Deployment Timeout
**Problem**: Function deployment takes too long

**Solution**:
- Increase timeout in deployment script
- Check function memory allocation
- Verify all dependencies are properly cached

#### 4. CORS Issues After Deployment
**Problem**: CORS errors in browser

**Solution**:
- Verify CORS_ORIGINS environment variable
- Check function logs for CORS configuration
- Test with curl to isolate browser issues

### Debugging Commands

```bash
# Check function logs
gcloud functions logs read hono-serverless-api --limit=50

# Test function locally
curl https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/hono-serverless-api/health

# Check function configuration
gcloud functions describe hono-serverless-api --region=asia-south1

# View Terraform state
cd terraform
terraform show
```

## 📚 Best Practices

### Security
1. **Use separate service accounts** for dev and prod
2. **Limit service account permissions** to minimum required
3. **Rotate service account keys** regularly
4. **Never commit secrets** to version control
5. **Use environment-specific variables**

### Performance
1. **Cache dependencies** in CI/CD pipelines
2. **Use artifacts** to share build outputs between jobs
3. **Optimize Docker images** if using custom runners
4. **Implement health checks** after deployment

### Monitoring
1. **Set up alerts** for deployment failures
2. **Monitor function performance** after deployment
3. **Track deployment metrics** (success rate, duration)
4. **Implement rollback procedures**

### Code Quality
1. **Run linting** and formatting checks
2. **Implement comprehensive tests**
3. **Use semantic versioning** for releases
4. **Document all configuration changes**

## 🔄 Rollback Procedures

### GitLab Rollback
1. **Navigate to** Operations → Environments
2. **Click on** the environment (development/production)
3. **Find** the previous successful deployment
4. **Click** "Re-deploy" button

### GitHub Rollback
1. **Navigate to** Actions tab
2. **Find** the previous successful workflow run
3. **Click** "Re-run jobs" to redeploy previous version

### Manual Rollback
```bash
# Revert to previous commit
git revert HEAD
git push origin main

# Or reset to specific commit (use with caution)
git reset --hard PREVIOUS_COMMIT_HASH
git push --force origin main
```

## 📞 Support

For issues with CI/CD setup:

1. **Check pipeline logs** for specific error messages
2. **Verify all secrets/variables** are correctly configured
3. **Test deployment script locally** before pushing
4. **Review GCP quotas and limits**
5. **Check service account permissions**

### Useful Resources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Note**: Replace `YOUR_PROJECT_ID` and `your-gcp-project-id` with your actual GCP project ID throughout this guide.