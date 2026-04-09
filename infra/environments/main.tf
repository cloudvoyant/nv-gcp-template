locals {
  is_prod = var.environment_name == "prod"
}

locals {
  secret_name = local.is_prod ? "${var.project}-secrets-prod" : "${var.project}-secrets-nonprod"
}

# Read Kinde credentials from Secret Manager at deploy time.
# Credentials are stored in ENV format by `just setup-secrets ENV`.
data "google_secret_manager_secret_version" "app_secrets" {
  project = var.gcp_devops_project_id
  secret  = local.secret_name
  version = "latest"
}

locals {
  secret_lines = split("\n", data.google_secret_manager_secret_version.app_secrets.secret_data)
  secrets_map = {
    for line in local.secret_lines :
    trimspace(split("=", line)[0]) => trimspace(join("=", slice(split("=", line), 1, length(split("=", line)))))
    if length(regexall("^[A-Z_]+=.+", trimspace(line))) > 0
  }
  kinde_domain        = lookup(local.secrets_map, "KINDE_DOMAIN", "")
  kinde_client_id     = lookup(local.secrets_map, "KINDE_CLIENT_ID", "")
  kinde_client_secret = lookup(local.secrets_map, "KINDE_CLIENT_SECRET", "")
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

  env_vars = {
    # Kinde Authentication (from Secret Manager via locals)
    VITE_KINDE_DOMAIN    = local.kinde_domain
    VITE_KINDE_CLIENT_ID = local.kinde_client_id
    KINDE_CLIENT_SECRET  = local.kinde_client_secret

    # GCP Cloud Storage
    GCS_PUBLIC_BUCKET_NAME  = "${var.project}-public" # shared bucket, lives in infra/shared/
    GCS_PRIVATE_BUCKET_NAME = module.storage_bucket.private_bucket_name
    GCP_PROJECT_ID          = var.gcp_project_id

    # Logging
    LOG_LEVEL = var.environment_name == "prod" ? "warn" : "debug"

    # CDN
    CDN_BASE_URL   = var.cdn_base_url
    CDN_ENV_SUFFIX = var.environment_name
  }

  cpu           = var.environment_name == "prod" ? "2" : "1"
  memory        = var.environment_name == "prod" ? "1Gi" : "512Mi"
  min_instances = 0
  max_instances = var.environment_name == "prod" ? 20 : 5
  timeout       = 300

  enable_public_access  = true
  enable_domain_mapping = contains(["dev", "stage", "prod"], var.environment_name)
}

# Grant Cloud Run SA access to the shared public CDN bucket (managed by infra/shared)
resource "google_storage_bucket_iam_member" "public_bucket_service_account" {
  bucket = "${var.project}-public" # shared bucket, lives in infra/shared/
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.fullstack_app.service_account_email}"
}

# Grant Cloud Run SA access to private bucket
resource "google_storage_bucket_iam_member" "private_bucket_service_account" {
  bucket = module.storage_bucket.private_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.fullstack_app.service_account_email}"
}
