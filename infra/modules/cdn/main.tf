resource "google_project_service" "compute" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Shared public GCS bucket for all environments of this project.
# Objects stored with env prefix so all environments share one bucket:
#   dev/alice/avatar.webp, prod/alice/avatar.webp
# Preview environments work without infra changes — just use a different env prefix.
resource "google_storage_bucket" "public" {
  name          = "${var.project}-public"
  project       = var.gcp_project_id
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true

  labels = {
    project    = var.project
    managed_by = "terraform"
    visibility = "public"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "DELETE"]
    response_header = ["Content-Type", "Content-Length", "Authorization", "x-goog-resumable"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "public_viewer" {
  bucket = google_storage_bucket.public.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend bucket lives in the client project alongside the GCS bucket.
# GCP requires the backend bucket and its GCS bucket to be in the same project.
# The shared load balancer in core-infra references this cross-project via self_link.
resource "google_compute_backend_bucket" "cdn" {
  project     = var.gcp_project_id
  name        = "${var.project}-cdn-backend"
  bucket_name = google_storage_bucket.public.name
  enable_cdn  = true
  depends_on  = [google_project_service.compute]

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl           = 86400
    client_ttl        = 3600
    negative_caching  = true
    serve_while_stale = 86400
  }
}

# Grant the principal(s) running tf-apply-shared in core-infra permission to
# reference this backend bucket from a URL map in a different GCP project.
# See: https://cloud.google.com/load-balancing/docs/https/setup-cross-project-backend-service-backend-bucket
# Note: google_compute_backend_bucket_iam_member requires google provider v6+.
# Using google_project_iam_member instead (same role, project scope) for v5 compatibility.
resource "google_project_iam_member" "lb_users" {
  for_each = var.lb_users

  project = var.gcp_project_id
  role    = "roles/compute.loadBalancerServiceUser"
  member  = each.value
}
