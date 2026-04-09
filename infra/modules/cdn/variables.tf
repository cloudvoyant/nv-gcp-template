variable "project" {
  description = "Project name used for bucket and backend bucket naming"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID (client project where bucket and backend bucket are created)"
  type        = string
}

variable "gcp_region" {
  description = "GCS bucket location"
  type        = string
}

variable "lb_users" {
  description = "IAM members granted roles/compute.loadBalancerServiceUser on the backend bucket. Format: 'user:email@example.com' or 'serviceAccount:sa@project.iam.gserviceaccount.com'"
  type        = set(string)
}
