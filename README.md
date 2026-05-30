# mise-app-template

![Version](https://img.shields.io/github/v/release/cloudvoyant/mise-app-template?label=version)
![Release](https://github.com/cloudvoyant/mise-app-template/workflows/Release/badge.svg)

A GCP infrastructure template using Terraform for multi-environment deployments with automated CI/CD pipelines.

## Features

- Automated preview environments for feature/bugfix/hotfix branches
- Terraform workspace isolation (dev, stage, prod, preview)
- Shared GCS backend for centralized state management
- GitHub Actions workflows for automated deployment
- Semantic versioning with conventional commits
- Docker image builds and publishing to GCP Artifact Registry
- Package publishing to GCP Artifact Registry (generic and Docker)
- Manual deployment workflows with approval gates
- Branch-based infrastructure provisioning and cleanup

## Requirements

- bash 3.2+
- mise - Dev tool and task runner
- Terraform 1.5+ (managed by mise)
- gcloud CLI
- GCP project with billing enabled

## Quick Start

### Create Your Project

```bash
# Option 1: Nedavellir CLI
nv create your-project --template mise-app-template

# Option 2: GitHub template + scaffold
git clone <your-new-repo>
cd <your-new-repo>
mise run scaffold -- --project your-project
```

### Setup

```bash
# Install all dev tools and dependencies
mise install

# Configure GCP project details in mise.local.toml (optional local overrides)
cp mise.local.toml.example mise.local.toml
vim mise.local.toml

# Authenticate with GCP
mise run gcp-login

# Create Terraform backend (one-time)
mise run tf-create-backend
```

### Deploy Infrastructure

```bash
mise run tf-init          # Initialize Terraform
mise run tf-plan          # Preview changes
mise run tf-apply         # Apply changes
```

### Available Commands

List all available tasks:

```bash
mise tasks
```

## CI/CD Workflows

### Feature Branch Workflow

Push to `feature/*`, `bugfix/*`, or `hotfix/*` branches:

1. CI runs tests, linting, formatting
2. Builds Docker image tagged with issue ID
3. Publishes pre-release package
4. Creates isolated Terraform workspace
5. Provisions preview infrastructure
6. Deploys application
7. Cleans up when PR is merged or branch deleted

### Release Workflow

Push to `main` branch:

1. Analyzes conventional commits
2. Bumps version and creates git tag
3. Publishes package and Docker image
4. Deploys to dev environment
5. Creates GitHub Release

### Manual Deployment

Deploy to stage/prod via GitHub Actions:

1. Go to Actions → Manual Deployment
2. Select version tag and environment
3. Approve deployment (if required)

## Documentation

- [User Guide](docs/user-guide.md) - Complete setup and CI/CD workflow guide
- [Architecture](docs/architecture.md) - System design and Terraform structure
- [Infrastructure Guide](docs/infrastructure.template.md) - Infrastructure operations
- [Development Guide](docs/development-guide.template.md) - Developer workflows

## Customization

Customize for your language:

```bash
# After scaffolding, install tools and customize Docker and package publishing
mise install
claude /adapt    # Guided customization (requires Claude CLI)
```

Update `Dockerfile` and `.mise-tasks/build-prod` for your language/framework.

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [mise dev tool manager](https://mise.jdx.dev/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
