terraform {
  backend "gcs" {
    # Bucket name must match GCP_DEVOPS_PROJECT_ID-terraform-backend-storage
    # Set via TF_BACKEND_BUCKET env var or -backend-config flag
  }
}
