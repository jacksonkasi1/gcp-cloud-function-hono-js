# Simple GCP Cloud Functions Deployment Guide

## Overview
This project uses a simplified deployment approach with service account credentials for Google Cloud Functions deployment.

## Setup Instructions

### 1. Service Account Credentials
1. Copy your GCP service account JSON key content
2. Paste it into `deploy-credential.json` (replacing the placeholder content)
3. The file is already added to `.gitignore` for security

### 2. Required Permissions
Your service account should have these roles:
- **Cloud Functions Admin** - Deploy and manage functions
- **Cloud Run Admin** - Manage Cloud Run services (for Gen 2 functions)
- **Storage Admin** - Access Cloud Storage for source code
- **Artifact Registry Admin** - Push container images
- **Service Account User** - Use service accounts

### 3. Environment Configuration
Ensure your environment files are configured:
- `.env.development` - Development environment settings
- `.env.production` - Production environment settings

Required variables:
```bash
GCP_PROJECT_ID=your-project-id
FUNCTION_REGION=asia-south1
FUNCTION_MEMORY=1Gi
```

## Deployment Commands

### Development Environment
```bash
npm run deploy:dev
```

### Production Environment
```bash
npm run deploy:prod
```

## What the Script Does

1. **Authentication**: Uses service account key from `deploy-credential.json`
2. **Project Setup**: Sets the GCP project from environment variables
3. **Build**: Installs dependencies and compiles TypeScript
4. **Deploy**: Deploys to Cloud Functions Gen 2 with:
   - Node.js 20 runtime
   - HTTP trigger (unauthenticated)
   - Environment-specific configuration
   - 1GB memory allocation
   - 60-second timeout

## Function URLs

After deployment, you'll get URLs like:
- **Development**: `https://asia-south1-your-project.cloudfunctions.net/hono-serverless-api-dev`
- **Production**: `https://asia-south1-your-project.cloudfunctions.net/hono-serverless-api`

## Testing

Test the deployed function:
```bash
# Health check
curl https://your-function-url/health

# API testing
npm run test:api:dev    # Test development
npm run test:api:prod   # Test production
```

## Security Notes

- ✅ `deploy-credential.json` is in `.gitignore`
- ✅ Never commit credential files to version control
- ✅ Use environment-specific configurations
- ✅ Service account has minimal required permissions

## Troubleshooting

### Common Issues

1. **"Credential file not found"**
   - Ensure `deploy-credential.json` exists with valid JSON content

2. **"Permission denied"**
   - Verify service account has required roles
   - Check project ID in environment file

3. **"Invalid region"**
   - Use valid GCP regions like `asia-south1`, `us-central1`, etc.

4. **"Build failed"**
   - Run `npm install` and `npm run build` locally first
   - Check TypeScript compilation errors

### Getting Help

1. Check deployment logs in GCP Console
2. Verify environment file configuration
3. Test authentication: `gcloud auth activate-service-account --key-file=deploy-credential.json`

## File Structure

```
├── deploy-credential.json     # GCP service account key (not in git)
├── .env.development          # Development environment config
├── .env.production           # Production environment config
├── scripts/
│   └── deploy-simple.sh      # Simplified deployment script
└── src/                      # Application source code
```

This simplified approach eliminates complex IAM permission management and provides a straightforward deployment process using service account credentials.