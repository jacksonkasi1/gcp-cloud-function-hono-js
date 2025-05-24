# Configure the Google Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "cloud_functions_api" {
  service = "cloudfunctions.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create a Cloud Storage bucket for storing function source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-${var.function_name}-source"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = var.max_versions_to_keep
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Create source code archive
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "../"
  output_path = "../dist/function-source.zip"
  excludes = [
    "terraform/",
    "scripts/",
    "dist/",
    ".git/",
    ".gitignore",
    "README.md",
    "*.md",
    ".terraform/",
    "*.tfstate*",
    "*.tfvars"
  ]
}

# Upload source code to bucket
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${var.deployment_version}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_source.output_path
  
  depends_on = [data.archive_file.function_source]
}

# Create Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "hono_function" {
  name     = var.function_name
  location = var.region
  
  build_config {
    runtime     = "nodejs20"
    entry_point = "default"
    
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }
  
  service_config {
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
    
    available_memory   = var.memory_mb
    timeout_seconds    = var.timeout_seconds
    
    environment_variables = {
      NODE_ENV          = "production"
      FUNCTION_VERSION  = var.deployment_version
      FUNCTION_REGION   = var.region
      FUNCTION_MEMORY   = "${var.memory_mb}MB"
    }
    
    ingress_settings               = "ALLOW_ALL"
    all_traffic_on_latest_revision = true
  }
  
  depends_on = [
    google_project_service.cloud_functions_api,
    google_project_service.cloud_build_api,
    google_project_service.cloud_run_api,
    google_storage_bucket_object.function_source
  ]
}

# Create IAM policy to allow unauthenticated access
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.hono_function.name
  role           = "roles/run.invoker"
  member         = "allUsers"
}

# Data source to get information about old function versions for cleanup
data "google_cloudfunctions2_function" "existing_functions" {
  count    = var.enable_version_cleanup ? 1 : 0
  name     = var.function_name
  location = var.region
  
  depends_on = [google_cloudfunctions2_function.hono_function]
}