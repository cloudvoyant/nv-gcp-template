locals {
  is_prod = var.environment_name == "prod"
}

module "storage_bucket" {
  source = "../modules/storage-bucket"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name
  force_destroy    = var.environment_name != "prod" && var.environment_name != "stage"
}

# Fullstack web application module
module "fullstack_app" {
  source = "../modules/nv-fullstack-app"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name

  image      = var.app_image
  commit_sha = var.commit_sha

  gcp_devops_project_id  = var.gcp_devops_project_id
  docker_registry_name   = var.gcp_devops_docker_registry_name
  docker_registry_region = var.gcp_devops_project_region

  base_domain   = var.base_domain
  custom_domain = local.is_prod && var.prod_domain != "" ? var.prod_domain : ""

  # Add application environment variables here
  env_vars = {
    LOG_LEVEL = var.environment_name == "prod" ? "warn" : "debug"
  }

  cpu           = var.environment_name == "prod" ? "2" : "1"
  memory        = var.environment_name == "prod" ? "1Gi" : "512Mi"
  min_instances = 0
  max_instances = var.environment_name == "prod" ? 20 : 5
  timeout       = 300

  enable_public_access  = true
  enable_domain_mapping = contains(["dev", "stage", "prod"], var.environment_name)
}

# Grant Cloud Run service account access to storage bucket
resource "google_storage_bucket_iam_member" "bucket_service_account" {
  bucket = module.storage_bucket.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.fullstack_app.service_account_email}"
}
