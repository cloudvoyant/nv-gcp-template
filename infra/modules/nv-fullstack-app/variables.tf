variable "project" {
  description = "Project name (used in resource naming, e.g., 'myapp')"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "environment_name" {
  description = "Environment name (dev, stage, prod, or branch-based like 'nv-29')"
  type        = string
}

variable "image" {
  description = "Container image URL from Artifact Registry"
  type        = string
}

variable "commit_sha" {
  description = "Git commit SHA to trigger redeployment (label on Cloud Run service)"
  type        = string
  default     = ""
}

variable "base_domain" {
  description = "Base domain for auto-generated subdomains (e.g., 'example.io')"
  type        = string
  default     = "example.io"
}

variable "custom_domain" {
  description = "Optional custom domain override"
  type        = string
  default     = ""
}

variable "env_vars" {
  description = "Environment variables for the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU allocation for Cloud Run service"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "gcp_devops_project_id" {
  description = "GCP devops project ID containing the Docker registry"
  type        = string
}

variable "docker_registry_name" {
  description = "Docker registry name in Artifact Registry"
  type        = string
}

variable "docker_registry_region" {
  description = "Docker registry region"
  type        = string
}

variable "enable_public_access" {
  description = "Enable public access (allUsers invoker role)"
  type        = bool
  default     = true
}

variable "enable_domain_mapping" {
  description = "Enable custom domain mapping (requires domain verification)"
  type        = bool
  default     = false
}
