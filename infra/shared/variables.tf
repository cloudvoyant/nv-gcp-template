variable "project" {
  description = "Project name (used for resource naming)"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID where shared resources are provisioned"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
}

variable "gcp_devops_project_id" {
  description = "GCP devops project ID — used to construct the terraform backend bucket name"
  type        = string
}

variable "developer_emails" {
  description = "Developer email addresses granted SA impersonation (for local signed URL generation)"
  type        = set(string)
  default     = []
}
