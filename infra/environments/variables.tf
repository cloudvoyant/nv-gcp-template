variable "project" {
  description = "Project name (used in resource naming and labels, e.g., 'myapp')"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID for infrastructure resources"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
}

variable "environment_name" {
  description = "Environment name (dev, stage, prod, or issue-id)"
  type        = string
}

variable "app_image" {
  description = "Docker image for the web application (set via TF_VAR_app_image in CI)"
  type        = string
  default     = ""
}

variable "commit_sha" {
  description = "Git commit SHA to force Cloud Run redeployment"
  type        = string
  default     = ""
}

variable "gcp_devops_project_id" {
  description = "GCP devops project ID containing the Docker registry"
  type        = string
}

variable "gcp_devops_docker_registry_name" {
  description = "Docker registry name in Artifact Registry"
  type        = string
}

variable "gcp_devops_project_region" {
  description = "Docker registry region"
  type        = string
}

variable "base_domain" {
  description = "Base domain for all environments"
  type        = string
  default     = "cloudvoyant.io"
}

variable "prod_domain" {
  description = "Optional custom domain for production"
  type        = string
  default     = ""
}
