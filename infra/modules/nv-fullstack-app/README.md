# nv-fullstack-app Terraform Module

A complete GCP fullstack application module providing Cloud Run, Firestore, domain mapping, and IAM configuration.

## Features

- Cloud Run v2 service with configurable scaling, CPU/memory, and environment variables
- Firestore Native mode database (per-environment naming for non-prod)
- Cross-project Artifact Registry IAM for pulling Docker images from a devops project
- Optional public access via `allUsers` IAM binding
- Optional custom domain mapping
- Commit SHA label for forced redeployment without tag changes
- Service account with Firestore access

## Usage

```hcl
module "fullstack_app" {
  source = "../modules/nv-fullstack-app"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name

  image      = var.app_image
  commit_sha = var.commit_sha

  gcp_devops_project_id  = var.gcp_devops_project_id
  docker_registry_name   = var.gcp_devops_docker_registry_name
  docker_registry_region = var.gcp_devops_project_region

  base_domain   = var.base_domain
  custom_domain = local.is_prod && var.prod_domain != "" ? var.prod_domain : ""

  env_vars = {
    LOG_LEVEL = var.environment_name == "prod" ? "warn" : "debug"
  }

  cpu           = var.environment_name == "prod" ? "2" : "1"
  memory        = var.environment_name == "prod" ? "1Gi" : "512Mi"
  min_instances = 0
  max_instances = var.environment_name == "prod" ? 20 : 5
  timeout       = 300

  enable_public_access  = true
  enable_domain_mapping = contains(["dev", "stage", "prod"], var.environment_name)
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name for resource naming | string | — | yes |
| gcp_project_id | GCP project ID | string | — | yes |
| gcp_region | GCP region | string | us-central1 | no |
| environment_name | Environment (dev/stage/prod/preview-id) | string | — | yes |
| image | Container image URL | string | — | yes |
| commit_sha | Git commit SHA for forced redeployment | string | "" | no |
| base_domain | Base domain for subdomains | string | example.io | no |
| custom_domain | Custom domain override | string | "" | no |
| env_vars | App environment variables | map(string) | {} | no |
| cpu | CPU allocation | string | 1 | no |
| memory | Memory allocation | string | 512Mi | no |
| min_instances | Minimum instances | number | 0 | no |
| max_instances | Maximum instances | number | 10 | no |
| timeout | Request timeout (seconds) | number | 300 | no |
| gcp_devops_project_id | DevOps project with Docker registry | string | — | yes |
| docker_registry_name | Artifact Registry repository name | string | — | yes |
| docker_registry_region | Artifact Registry region | string | — | yes |
| enable_public_access | Allow public unauthenticated access | bool | true | no |
| enable_domain_mapping | Enable custom domain mapping | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| service_url | Cloud Run service URL |
| service_name | Cloud Run service name |
| custom_domain | Mapped custom domain |
| public_url | Public-facing URL (domain or Cloud Run URL) |
| mongodb_uri | Firestore MongoDB connection URI (sensitive) |
| dns_instructions | DNS configuration instructions |
| environment | Environment name |
| region | GCP region |
| service_account_email | Service account email for impersonation |

## Notes

- **Firestore indexes**: This module creates the Firestore database but not composite indexes. Add indexes in the calling module for your data model.
- **Domain mapping**: Requires domain verification in GCP. Set `enable_domain_mapping = false` for preview environments.
- **Preview environments**: Firestore database uses `deletion_policy = "DELETE"` for non-stable environments (dev/stage/prod use `ABANDON`).
