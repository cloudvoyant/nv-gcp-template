# Storage Bucket Module

Creates a single GCS bucket for per-workspace private or general storage.

## Usage

```hcl
module "storage" {
  source = "../modules/storage-bucket"

  project          = "myproject"
  gcp_project_id   = "gcp-project-id"
  gcp_region       = "us-east1"
  environment_name = "dev"
  force_destroy    = true
}
```

## Design

Per-workspace storage (not CDN-backed). Used for private originals and any other workspace-scoped
files. `force_destroy = true` is set for non-prod/stage environments so preview workspaces clean
up completely on `tf-destroy`.

## Inputs

| Name               | Type     | Description                        |
| ------------------ | -------- | ---------------------------------- |
| `project`          | `string` | Project name                       |
| `gcp_project_id`   | `string` | GCP project ID                     |
| `gcp_region`       | `string` | Bucket region                      |
| `environment_name` | `string` | Environment suffix for bucket name |
| `force_destroy`    | `bool`   | Allow non-empty bucket destruction |

## Outputs

| Name          | Description     |
| ------------- | --------------- |
| `bucket_name` | GCS bucket name |
