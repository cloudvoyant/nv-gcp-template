output "service_url" {
  description = "Cloud Run service URL (empty if no image provided)"
  value       = var.image != "" ? google_cloud_run_v2_service.app[0].uri : ""
}

output "service_name" {
  description = "Cloud Run service name"
  value       = local.service_name
}

output "custom_domain" {
  description = "Custom domain mapped to the application"
  value       = var.enable_domain_mapping && var.image != "" ? local.domain : ""
}

output "public_url" {
  description = "Public URL for accessing the application (custom domain or Cloud Run URL)"
  value = (
    var.image != "" ? (
      var.enable_domain_mapping ? "https://${local.domain}" : google_cloud_run_v2_service.app[0].uri
    ) : ""
  )
}

output "mongodb_uri" {
  description = "MongoDB-compatible connection URI for Firestore"
  sensitive   = true
  value       = "mongodb+srv://${var.gcp_project_id}.firestore.googleapis.com:443/${google_firestore_database.app.name}"
}

output "domain_mapping_status" {
  description = "DNS records required for domain mapping (empty if domain mapping disabled)"
  value       = var.enable_domain_mapping && var.image != "" ? google_cloud_run_domain_mapping.app[0].status : []
}

output "dns_instructions" {
  description = "Human-readable DNS configuration instructions for custom domain"
  value = var.enable_domain_mapping && var.image != "" ? (
    "Point ${local.domain} to Cloud Run: add CNAME record targeting ghs.googlehosted.com"
  ) : "Domain mapping disabled for environment: ${var.environment_name}"
}

output "environment" {
  description = "Environment name"
  value       = var.environment_name
}

output "region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "service_account_email" {
  description = "Service account email for local dev impersonation"
  value       = google_service_account.cloud_run.email
}
