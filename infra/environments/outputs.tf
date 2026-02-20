output "bucket_name" {
  description = "Name of the storage bucket"
  value       = module.storage_bucket.bucket_name
}

output "bucket_url" {
  description = "URL of the storage bucket"
  value       = module.storage_bucket.bucket_url
}

output "app_service_url" {
  description = "Cloud Run service URL for the web application"
  value       = module.fullstack_app.service_url
}

output "app_service_name" {
  description = "Name of the Cloud Run service"
  value       = module.fullstack_app.service_name
}

output "app_custom_domain" {
  description = "Custom domain mapped to the application"
  value       = module.fullstack_app.custom_domain
}

output "app_public_url" {
  description = "Public URL for accessing the application"
  value       = module.fullstack_app.public_url
}

output "app_dns_instructions" {
  description = "DNS configuration instructions for custom domain"
  value       = module.fullstack_app.dns_instructions
}

output "mongodb_uri" {
  description = "MongoDB connection URI for Firestore"
  value       = module.fullstack_app.mongodb_uri
  sensitive   = true
}

output "service_account_email" {
  description = "Service account email for local dev impersonation"
  value       = module.fullstack_app.service_account_email
}
