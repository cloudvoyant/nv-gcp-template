# Infrastructure Guide

> Infrastructure architecture and deployment guide for {{PROJECT_NAME}}

## Overview

{{PROJECT_NAME}} uses Terraform for infrastructure-as-code with automated CI/CD through GitHub Actions. The system provides isolated preview environments for feature branches and a structured promotion workflow (dev → stage → prod) with approval gates.

## Terraform Infrastructure

### Branch-to-Environment Mapping

Branch names determine Terraform workspaces and environments:

| Branch Pattern            | Environment | Workspace  | Action                                  |
| ------------------------- | ----------- | ---------- | --------------------------------------- |
| `feature/XXXX-NNN-*`      | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `bugfix/XXXX-NNN-*`       | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `hotfix/XXXX-NNN-*`       | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `main`                    | dev         | `dev`      | Update on merge                         |
| Tag via workflow_dispatch | stage       | `stage`    | Manual deploy + approval gate           |
| Approved stage            | prod        | `prod`     | Manual deploy after approval            |

### Issue ID Extraction

Preview environments extract issue IDs from branch names:

- Pattern: `feature/PROJ-12345-description` → workspace: `proj-12345`
- Pattern: `bugfix/BUG-1-fix` → workspace: `bug-1`
- Supports any tracker format: `[LETTERS]-[DIGITS]`
- Automatically normalized to lowercase for GCP compliance

### Terraform Backend

All Terraform state is stored in a shared GCS bucket with this structure:

```
${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage/
└── ${GCP_PROJECT_ID}/
    └── {{PROJECT_NAME}}/
        ├── env:/dev/default.tfstate       # dev workspace
        ├── env:/stage/default.tfstate     # stage workspace
        ├── env:/prod/default.tfstate      # prod workspace
        └── env:/proj-123/default.tfstate  # preview workspace
```

Configuration:

- Bucket: `${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage`
- Prefix: `${GCP_PROJECT_ID}/{{PROJECT_NAME}}`
- Workspace: `dev`, `stage`, `prod`, or `${issue-id}`

Benefits:

- Multi-project support in single bucket
- Clear hierarchy: GCP Project → Application → Environment
- Complete state isolation per application
- Centralized management and backup
- Cost efficient operation

### Resource Naming

All GCP resources follow this convention:

Naming Pattern: `${project}-${environment}--${resource-name}`

Examples:
- Preview: `{{PROJECT_NAME}}-proj-123--bucket`
- Dev: `{{PROJECT_NAME}}-dev--bucket`
- Stage: `{{PROJECT_NAME}}-stage--bucket`
- Prod: `{{PROJECT_NAME}}-prod--bucket`

The double-dash (`--`) separator distinguishes environment from resource name.

Standard labels applied to all resources:

```hcl
labels = {
  project     = "{{PROJECT_NAME}}"
  environment = var.environment_name
  managed_by  = "terraform"
}
```

### Environment Strategy

Workspaces:

- preview-* (dynamic): No approvals, short-lived, auto-created per branch
- dev: No approvals, auto-deploy on merge to main
- stage: Requires manual approval before deploy
- prod: Requires manual approval before deploy

Naming Rules:

- Lowercase only (GCP requirement)
- Alphanumeric plus hyphens
- No special characters except dash
- Maximum 63 characters

## CI/CD Workflows

### Preview Environment Workflow

Trigger: Push to `feature/*`, `bugfix/*`, `hotfix/*` branches

Steps:
1. Extract issue ID from branch name
2. Run tests, linting, formatting checks
3. Build Docker image tagged with issue ID
4. Publish pre-release package
5. Create/select Terraform workspace
6. Provision infrastructure
7. Deploy application
8. Comment on PR with deployment details

Cleanup: When PR is merged or branch deleted, workflow destroys infrastructure and removes workspace.

### Release Workflow

Trigger: Push to `main` branch

Steps:
1. Run tests
2. Analyze conventional commits for version bump
3. Update version.txt and CHANGELOG.md
4. Create git tag
5. Build production artifacts
6. Publish package
7. Build and push Docker image
8. Deploy to dev environment
9. Create GitHub Release

### Manual Deployment Workflow

Trigger: Manual workflow dispatch

Steps:
1. Checkout specific git tag
2. Select environment (stage or prod)
3. Run Terraform plan/apply
4. Deploy application using pre-built image
5. Notify approvers if required

## Environment Configuration

### Local Development

Edit `.envrc` with your configuration:

```bash
export PROJECT={{PROJECT_NAME}}
export VERSION=$(get_version)

# DevOps project (hosts tfstate, artifact registry, docker registry)
export GCP_DEVOPS_PROJECT_ID=my-devops-project
export GCP_DEVOPS_PROJECT_REGION=us-east1
export GCP_DEVOPS_REGISTRY_NAME=my-artifact-registry
export GCP_DEVOPS_DOCKER_REGISTRY_NAME=my-docker-registry

# Infrastructure project (where resources are provisioned)
export GCP_PROJECT_ID=my-app-project
export GCP_REGION=us-east1
```

Allow direnv:

```bash
direnv allow
```

### CI/CD Secrets

Configure these secrets in GitHub repository settings (Settings → Secrets → Actions):

- `GCP_SA_KEY`: Service account key JSON for GCP authentication

### GCP Service Account Setup

Create service account with appropriate permissions:

```bash
# Create service account in DevOps project
gcloud iam service-accounts create github-actions \
  --project=${GCP_DEVOPS_PROJECT_ID}

# Grant organization-level editor role (or specific project roles as needed)
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="serviceAccount:github-actions@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com
```

Add to GitHub Secrets:
1. Go to repository Settings → Secrets → Actions
2. Create secret `GCP_SA_KEY` with contents of `github-actions-key.json`
3. Delete local key: `rm github-actions-key.json`

### Environment Protection

Configure approval requirements in GitHub Settings → Environments:

1. Create environments: `dev`, `stage`, `prod`
2. For `stage` and `prod`:
   - Add "Required reviewers"
   - Set branch restriction to `main`
3. For `dev`: No approvals needed

## Terraform Operations

### Local Operations

```bash
# Initialize backend and workspace
just tf-init

# Preview infrastructure changes
just tf-plan

# Apply changes
just tf-apply

# Destroy infrastructure (with confirmation)
just tf-destroy
```

### Workspace Management

```bash
# List all workspaces
just tf-list-workspaces

# Create/select workspace
just tf-select-workspace dev

# Auto-infer workspace from branch
just tf-select-workspace
```

Workspace is automatically inferred from git branch:
- On `main` branch → `dev` workspace
- On `feature/PROJ-123-*` → `proj-123` workspace
- On other branches → `dev` workspace (fallback)

## Docker Operations

### Local Build and Push

```bash
# Build with current version from version.txt
just docker-build

# Build with custom tag
just docker-build my-feature-tag

# Push to registry (requires gcloud auth)
just docker-push

# Push with custom tag
just docker-push my-feature-tag
```

Image naming pattern:
```
${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}:${TAG}
```

### Artifact Publishing

```bash
# Publish release version (uses version.txt)
just publish

# Publish pre-release with tag
just publish my-test-tag
# Creates version: 1.0.3-rc.my-test-tag
```

## Troubleshooting

### Terraform State Lock

If operations fail with state lock error:

```bash
# Only use if you're certain no other process is running
terraform force-unlock <LOCK_ID>
```

### Preview Environment Not Cleaning Up

Check cleanup workflow logs in GitHub Actions. Common issues:
- Workflow didn't trigger (check branch name pattern)
- Terraform destroy failed (check permissions)

Manually clean up:

```bash
just tf-destroy proj-123 --auto-approve
```

### Docker Push Authentication Failed

Ensure gcloud is authenticated:

```bash
gcloud auth login
gcloud auth configure-docker ${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev
```

### Permission Denied Errors

Verify service account has necessary roles:

```bash
# Check IAM policy for DevOps project
gcloud projects get-iam-policy ${GCP_DEVOPS_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions@*"

# Check IAM policy for Infrastructure project
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions@*"
```

## Monitoring and Operations

TODO: Add monitoring, logging, and alerting configuration specific to your application.

### Health Checks

TODO: Add health check endpoints and monitoring setup.

### Logs

TODO: Add logging configuration and access instructions.

### Metrics

TODO: Add metrics collection and dashboard links.

## Security Best Practices

- Use least-privilege IAM roles
- Rotate service account keys regularly
- Enable audit logging in cloud environments
- Review dependency vulnerabilities regularly
- Store secrets in GitHub Secrets (encrypted at rest)
- Use environment protection rules for production

## Cost Optimization

- Use caching in CI/CD workflows
- Clean up old artifacts and preview environments regularly
- Right-size cloud resources based on actual usage
- Monitor usage and set budget alerts
- Delete stale Terraform workspaces

## Support

For infrastructure-related questions:
- File an issue in the GitHub repository
- Review [user-guide.md](./user-guide.md) for CI/CD workflow details
- Review [architecture.md](./architecture.md) for system design

---

Template: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
