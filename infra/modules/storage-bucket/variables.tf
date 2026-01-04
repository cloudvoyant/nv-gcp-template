variable "project" {
  description = "Project name (used in resource naming and labels)"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID (where resources are provisioned)"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
}

variable "environment_name" {
  description = "Environment name (dev, stage, prod, or issue-id for previews)"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket destruction even if not empty (useful for preview environments)"
  type        = bool
  default     = false
}
