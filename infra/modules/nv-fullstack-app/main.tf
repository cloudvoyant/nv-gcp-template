locals {
  service_name = "${var.project}-${var.environment_name}"

  # GCP service account IDs must be 6-30 chars. Truncate to ensure compliance.
  # Format: <project>-<env>-run — trim to 28 chars then add "-r" suffix if needed.
  _sa_raw    = "${var.project}-${var.environment_name}-run"
  sa_id      = length(local._sa_raw) <= 30 ? local._sa_raw : "${substr(local._sa_raw, 0, 27)}-r"

  is_prod    = var.environment_name == "prod"
  is_preview = !contains(["dev", "stage", "prod"], var.environment_name)

  domain = var.custom_domain != "" ? var.custom_domain : (
    local.is_prod ? var.base_domain : "${var.environment_name}.${var.base_domain}"
  )

  labels = {
    environment = var.environment_name
    project     = var.project
    managed_by  = "terraform"
  }

  commit_labels = var.commit_sha != "" ? merge(local.labels, {
    commit_sha = substr(var.commit_sha, 0, 7)
  }) : local.labels
}

data "google_project" "app_project" {
  project_id = var.gcp_project_id
}

# Enable required APIs
resource "google_project_service" "iam" {
  project            = var.gcp_project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.gcp_project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project            = var.gcp_project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project            = var.gcp_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "siteverification" {
  project            = var.gcp_project_id
  service            = "siteverification.googleapis.com"
  disable_on_destroy = false
}

# Firestore database
resource "google_firestore_database" "app" {
  project     = var.gcp_project_id
  name        = local.is_prod ? "(default)" : "${var.project}-${var.environment_name}"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"

  deletion_policy = local.is_preview ? "DELETE" : "ABANDON"

  depends_on = [google_project_service.firestore]
}

# Cloud Run service account
resource "google_service_account" "cloud_run" {
  project      = var.gcp_project_id
  account_id   = local.sa_id
  display_name = "${var.project} ${var.environment_name} Cloud Run"
}

# Allow Cloud Run SA to pull images from Artifact Registry (cross-project)
resource "google_artifact_registry_repository_iam_member" "cloud_run_reader" {
  project    = var.gcp_devops_project_id
  location   = var.docker_registry_region
  repository = var.docker_registry_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Allow Cloud Run service agent to pull images (required for Cloud Run managed)
resource "google_artifact_registry_repository_iam_member" "cloud_run_agent_reader" {
  project    = var.gcp_devops_project_id
  location   = var.docker_registry_region
  repository = var.docker_registry_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.app_project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# Allow Cloud Run SA to access Firestore
resource "google_project_iam_member" "cloud_run_datastore" {
  project = var.gcp_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Cloud Run v2 service (only deployed when an image is provided)
resource "google_cloud_run_v2_service" "app" {
  count    = var.image != "" ? 1 : 0
  project  = var.gcp_project_id
  name     = local.service_name
  location = var.gcp_region
  labels   = local.commit_labels

  template {
    service_account = google_service_account.cloud_run.email

    labels = local.commit_labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment_name
      }
    }

    timeout = "${var.timeout}s"
  }

  depends_on = [
    google_project_service.run,
    google_artifact_registry_repository_iam_member.cloud_run_reader,
    google_artifact_registry_repository_iam_member.cloud_run_agent_reader,
  ]
}

# Public access IAM binding
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = var.enable_public_access && var.image != "" ? 1 : 0
  project  = var.gcp_project_id
  location = var.gcp_region
  name     = google_cloud_run_v2_service.app[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Custom domain mapping (optional)
resource "google_cloud_run_domain_mapping" "app" {
  count    = var.enable_domain_mapping && var.image != "" ? 1 : 0
  project  = var.gcp_project_id
  location = var.gcp_region
  name     = local.domain

  metadata {
    namespace = var.gcp_project_id
    labels    = local.labels
  }

  spec {
    route_name = google_cloud_run_v2_service.app[0].name
  }

  depends_on = [google_project_service.siteverification]
}
