# {{PROJECT_NAME}}

> GCP infrastructure project scaffolded from {{TEMPLATE_NAME}} (v{{TEMPLATE_VERSION}})

## Overview

This project manages GCP infrastructure using Terraform with automated preview environments for feature branches and a structured deployment workflow (dev → stage → prod).

### Features

- **Branch-Based Infrastructure**: Feature/bugfix/hotfix branches automatically create isolated preview environments
- **Terraform Workspaces**: State isolation for dev, stage, prod, and preview environments
- **GCS Backend**: Centralized state management with versioning
- **Automated Deployments**: GitHub Actions workflows for preview creation, dev updates, and manual stage/prod deployments
- **Approval Gates**: GitHub environments with required approvals for production

### Project Structure

```
.
├── infra/                    # Terraform infrastructure
│   ├── modules/              # Reusable Terraform modules
│   │   └── storage-bucket/   # Example module
│   └── environments/         # Root Terraform configuration
├── docs/                     # Documentation
├── scripts/                  # Utility scripts and CI/CD hooks
├── justfile                  # Infrastructure management recipes
├── .envrc                    # GCP project configuration
└── version.txt               # Project version
```

## Prerequisites

- bash 3.2+
- just
- Terraform 1.5+
- gcloud CLI
- GCP project with billing enabled

## Setup

1. **Install dependencies**:
   ```bash
   just setup              # Install just and direnv
   # or: just setup --dev  # Install development tools
   ```

2. **Configure GCP projects** in `.envrc`:
   ```bash
   # DevOps Project (hosts tfstate, registries)
   export GCP_DEVOPS_PROJECT_ID=my-devops-project
   export GCP_DEVOPS_PROJECT_REGION=us-east1
   export GCP_DEVOPS_REGISTRY_NAME=my-registry

   # Infrastructure Project (where resources are provisioned)
   export GCP_PROJECT_ID=my-app-project
   export GCP_REGION=us-east1
   ```

3. **Authenticate with GCP**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

4. **Create Terraform backend** (one-time):
   ```bash
   just tf-create-backend
   ```

## Quick Start

Type `just` to see all available commands:

```bash
❯ just
Available recipes:
    [terraform]
    tf-create-backend  # Create GCS backend bucket
    tf-init           # Initialize Terraform backend
    tf-plan           # Run Terraform plan
    tf-apply          # Apply Terraform changes
    tf-destroy        # Destroy infrastructure

    [ci]
    docker-push       # Push Docker image to GCR
    deploy            # Deploy application

[ OUTPUT TRUNCATED ]
```

Deploy infrastructure:

```bash
just tf-init          # Initialize Terraform
just tf-plan          # Preview changes
just tf-apply         # Apply changes
```

## Infrastructure Workflows

### Preview Environments

Preview environments are automatically created for feature/bugfix/hotfix branches:

1. **Create a branch** with issue tracker ID:
   ```bash
   git checkout -b feature/PROJ-123-add-monitoring
   ```

2. **Push to GitHub**:
   ```bash
   git push origin feature/PROJ-123-add-monitoring
   ```

3. **GitHub Actions automatically**:
   - Extracts issue ID (`proj-123`)
   - Creates Terraform workspace
   - Provisions infrastructure
   - Comments on PR with details

4. **When merged/deleted**: Infrastructure is automatically destroyed

### Deployments

**Dev Environment**: Automatically updated on merge to main

**Stage/Prod**: Manual deployment via GitHub Actions:
1. Go to Actions → Manual Deployment
2. Select version tag and environment
3. Approve deployment (if required)

### Release Process

Use conventional commits for automatic versioning:

1. **Make changes** on a feature branch
2. **Commit with conventional commits**:
   - `feat: add cloud run module` → minor version bump
   - `fix: resolve bucket policy` → patch version bump
   - `feat!: breaking change` → major version bump
3. **Push to GitHub** and create a pull request
4. **Merge to main** - the CI/CD pipeline will:
   - Create new release with changelog
   - Build and push Docker image (optional)
   - Update dev environment infrastructure

See the [{{TEMPLATE_NAME}} User Guide](https://github.com/your-org/{{TEMPLATE_NAME}}/blob/main/docs/user-guide.md) for detailed workflow instructions.

## Documentation

To learn more about using this template, read the docs:

- [User Guide](docs/user-guide.md) - Complete setup and usage guide
- [Architecture](docs/architecture.md) - Design and implementation details

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [GCP Provider for Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Cloud Storage Backend](https://developer.hashicorp.com/terraform/language/backend/gcs)
