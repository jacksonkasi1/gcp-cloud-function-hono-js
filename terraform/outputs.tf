output "function_url" {
  description = "URL of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.hono_function.service_config[0].uri
}

output "function_name" {
  description = "Name of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.hono_function.name
}

output "function_region" {
  description = "Region where the function is deployed"
  value       = google_cloudfunctions2_function.hono_function.location
}

output "function_memory" {
  description = "Memory allocation of the function"
  value       = "${google_cloudfunctions2_function.hono_function.service_config[0].available_memory}MB"
}

output "deployment_version" {
  description = "Current deployment version"
  value       = var.deployment_version
}

output "storage_bucket" {
  description = "Storage bucket used for function source code"
  value       = google_storage_bucket.function_bucket.name
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "${google_cloudfunctions2_function.hono_function.service_config[0].uri}/health"
}

output "api_users_url" {
  description = "Users API endpoint URL"
  value       = "${google_cloudfunctions2_function.hono_function.service_config[0].uri}/api/users"
}