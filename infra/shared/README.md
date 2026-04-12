# Shared Infrastructure

One-time Terraform root for project-wide resources. Apply once per GCP project — not per workspace.

## What This Creates

1. **Public GCS bucket** (`{project}-public`) — shared across all environments; objects are env-prefixed so preview workspaces cost nothing extra
2. **CDN backend bucket** (`{project}-cdn-backend`) — wired to the public bucket with Cloud CDN caching (1h default TTL, 24h max)
3. **IAM grants** — `roles/iam.serviceAccountTokenCreator` for developers, enabling local signed URL generation without a downloaded key file (impersonation via ADC)

## Usage

```bash
just tf-init-shared
just tf-plan-shared
just tf-apply-shared
```

After applying, note the `backend_bucket_self_link` output — this is referenced by the shared load balancer in `core-infra` to serve CDN URLs.

## Why Separate From Per-Workspace State?

The public bucket has `force_destroy = false`. If it were in workspace state, a `tf-destroy` of any preview workspace would attempt to delete it (and fail, but noisily). Keeping it in its own state file prevents this entirely.
