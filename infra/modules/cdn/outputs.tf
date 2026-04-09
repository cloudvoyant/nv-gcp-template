output "public_bucket_name" {
  description = "Shared public GCS bucket name. Objects prefixed by env: dev/, prod/"
  value       = google_storage_bucket.public.name
}

output "backend_bucket_self_link" {
  description = "Fully-qualified self-link to paste into core-infra projects.auto.tfvars"
  value       = google_compute_backend_bucket.cdn.self_link
}
