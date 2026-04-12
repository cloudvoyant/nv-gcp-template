# CDN Module

Creates a shared public GCS bucket and a Google Cloud CDN backend bucket for a project.

## Design

All environments (dev, stage, prod, preview) share **one** public GCS bucket, using an
environment-prefix on every object path (`dev/alice/avatar.webp`, `prod/alice/avatar.webp`).
This means preview environments require no Terraform changes — they just use a different path
prefix without touching shared state.

The CDN backend bucket sits in the client project (same as the GCS bucket). A shared load
balancer in a separate `core-infra` project references it cross-project via `self_link`.
GCP requires the backend bucket and its GCS bucket to be in the same project.

## Usage

```hcl
module "cdn" {
  source = "../modules/cdn"

  project        = "myproject"
  gcp_project_id = "gcp-project-id"
  gcp_region     = "us-east1"
  lb_users       = toset(["user:dev@example.com"])
}
```

## Inputs

| Name             | Type          | Description                                                                           |
| ---------------- | ------------- | ------------------------------------------------------------------------------------- |
| `project`        | `string`      | Project name (used in bucket/backend names)                                           |
| `gcp_project_id` | `string`      | GCP project ID                                                                        |
| `gcp_region`     | `string`      | GCS bucket region                                                                     |
| `lb_users`       | `set(string)` | IAM members granted `roles/compute.loadBalancerServiceUser` for cross-project URL map |

## Outputs

| Name                       | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| `public_bucket_name`       | Name of the shared public GCS bucket                         |
| `backend_bucket_self_link` | Self-link for the CDN backend bucket (paste into core-infra) |

## CORS

The bucket allows `GET`, `HEAD`, `PUT`, `DELETE` from any origin to support direct browser uploads
via signed PUT URLs.
