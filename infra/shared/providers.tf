provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  default_labels = {
    project    = var.project
    managed_by = "terraform"
    scope      = "shared"
  }
}
