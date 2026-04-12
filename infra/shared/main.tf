resource "google_project_service" "iam_credentials" {
  project                    = var.gcp_project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Secret Manager API in the devops project
resource "google_project_service" "secret_manager" {
  project                    = var.gcp_devops_project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Secret containers for Kinde application credentials.
# These resources are declared here so they are tracked in Terraform state and
# destroyed cleanly. Secret versions (the actual credentials) are written by
# `just setup-secrets ENV` after apply.
resource "google_secret_manager_secret" "app_secrets_nonprod" {
  project   = var.gcp_devops_project_id
  secret_id = "${var.project}-secrets-nonprod"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret" "app_secrets_prod" {
  project   = var.gcp_devops_project_id
  secret_id = "${var.project}-secrets-prod"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret" "e2e_secrets" {
  project   = var.gcp_devops_project_id
  secret_id = "${var.project}-e2e-secrets"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

# Grant developers roles/iam.serviceAccountTokenCreator so they can impersonate
# the Cloud Run SA to generate v4 signed URLs locally without a key file.
resource "google_project_iam_member" "developer_sa_impersonation" {
  for_each = var.developer_emails

  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "user:${each.value}"
}

module "cdn" {
  source = "../modules/cdn"

  project        = var.project
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  lb_users       = toset([for email in var.developer_emails : "user:${email}"])
}
