terraform {
  backend "gcs" {
    # Bucket and prefix will be passed via -backend-config during init
    #
    # Multi-project architecture:
    # - Bucket: ${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage (shared across ALL projects)
    # - Prefix: ${GCP_PROJECT_ID}/${PROJECT} (GCP project + app name)
    # - Workspaces: Environment-specific (dev, stage, prod, preview-*)
    #
    # Example state paths (in bucket devops-466002-terraform-backend-storage):
    #   my-gcp-project/app1/env:/dev/default.tfstate
    #   my-gcp-project/app1/env:/stage/default.tfstate
    #   my-gcp-project/app2/env:/dev/default.tfstate
    #   another-gcp-project/app3/env:/prod/default.tfstate
  }
}
