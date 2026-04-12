output "public_bucket_name" {
  description = "Shared public GCS bucket name"
  value       = module.cdn.public_bucket_name
}

output "backend_bucket_self_link" {
  description = "CDN backend bucket self-link for cross-project URL map reference"
  value       = module.cdn.backend_bucket_self_link
}
