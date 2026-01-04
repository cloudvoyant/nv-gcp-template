module "storage_bucket" {
  source = "../modules/storage-bucket"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name
  force_destroy    = var.environment_name != "prod" && var.environment_name != "stage"
}
