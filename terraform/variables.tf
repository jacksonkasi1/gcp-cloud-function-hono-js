variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for deployment"
  type        = string
  default     = "asia-south1"
}

variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "hono-serverless-api"
}

variable "memory_mb" {
  description = "Memory allocation for the function in MB"
  type        = string
  default     = "1024"
  
  validation {
    condition = contains([
      "128", "256", "512", "1024", "2048", "4096", "8192"
    ], var.memory_mb)
    error_message = "Memory must be one of: 128, 256, 512, 1024, 2048, 4096, 8192 MB."
  }
}

variable "timeout_seconds" {
  description = "Function timeout in seconds"
  type        = number
  default     = 60
  
  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 540
    error_message = "Timeout must be between 1 and 540 seconds."
  }
}

variable "max_instances" {
  description = "Maximum number of function instances"
  type        = number
  default     = 100
}

variable "min_instances" {
  description = "Minimum number of function instances"
  type        = number
  default     = 0
}

variable "deployment_version" {
  description = "Version identifier for this deployment"
  type        = string
  default     = "v1.0.0"
}

variable "max_versions_to_keep" {
  description = "Maximum number of versions to keep in storage bucket"
  type        = number
  default     = 5
}

variable "enable_version_cleanup" {
  description = "Enable automatic cleanup of old function versions"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}