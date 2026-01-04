output "bucket_name" {
  description = "Name of the storage bucket"
  value       = module.storage_bucket.bucket_name
}

output "bucket_url" {
  description = "URL of the storage bucket"
  value       = module.storage_bucket.bucket_url
}
