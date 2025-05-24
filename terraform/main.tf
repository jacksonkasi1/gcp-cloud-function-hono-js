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

# Local values for computed variables
locals {
  # Convert memory format (1GB -> 1024, 2GB -> 2048, etc.)
  memory_mb = var.function_memory != null ? (
    can(regex("GB$", var.function_memory)) ?
    tonumber(regex("^([0-9]+)", var.function_memory)[0]) * 1024 :
    tonumber(regex("^([0-9]+)", var.function_memory)[0])
  ) : var.memory_mb
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
  
  labels = merge(var.labels, {
    component = "storage"
  })
}

# Create source code archive
data "archive_file" "function_source" {
  type             = "zip"
  output_path      = "../dist/function-source.zip"
  output_file_mode = "0644"
  
  source {
    content  = file("../package.json")
    filename = "package.json"
  }
  
  source {
    content  = file("../pnpm-lock.yaml")
    filename = "pnpm-lock.yaml"
  }
  
  dynamic "source" {
    for_each = fileset("../dist", "**/*.js")
    content {
      content  = file("../dist/${source.value}")
      filename = source.value
    }
  }
  
  dynamic "source" {
    for_each = fileset("../src", "**/*.ts")
    content {
      content  = file("../src/${source.value}")
      filename = "src/${source.value}"
    }
  }
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
  
  labels = merge(var.labels, {
    component = "function"
  })
  
  service_config {
    max_instance_count = var.function_max_instances != null ? var.function_max_instances : var.max_instances
    min_instance_count = var.function_min_instances != null ? var.function_min_instances : var.min_instances
    
    available_memory   = "${local.memory_mb}Mi"
    available_cpu      = local.memory_mb >= 1024 ? "1" : "0.083"
    timeout_seconds    = var.function_timeout != null ? var.function_timeout : var.timeout_seconds
    
    environment_variables = merge({
      FUNCTION_VERSION  = var.deployment_version
      FUNCTION_REGION   = var.region
      FUNCTION_MEMORY   = var.function_memory != null ? var.function_memory : "${var.memory_mb}MB"
    }, var.environment_variables)
    
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