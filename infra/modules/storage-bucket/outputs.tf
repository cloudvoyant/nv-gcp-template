output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.bucket.name
}

output "bucket_url" {
  description = "URL of the created storage bucket"
  value       = google_storage_bucket.bucket.url
}
