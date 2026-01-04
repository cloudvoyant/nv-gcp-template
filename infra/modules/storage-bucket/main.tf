resource "google_storage_bucket" "bucket" {
  name          = "${var.project}-${var.environment_name}--bucket"
  project       = var.gcp_project_id
  location      = var.gcp_region
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  labels = {
    project     = var.project
    environment = var.environment_name
    managed_by  = "terraform"
  }
}
