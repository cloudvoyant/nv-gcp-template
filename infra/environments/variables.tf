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
