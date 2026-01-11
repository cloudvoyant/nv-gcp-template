# nv-gcp-template

![Version](https://img.shields.io/github/v/release/cloudvoyant/nv-gcp-template?label=version)
![Release](https://github.com/cloudvoyant/nv-gcp-template/workflows/Release/badge.svg)

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
- just - Command runner
- Terraform 1.5+
- gcloud CLI
- GCP project with billing enabled

## Quick Start

### Create Your Project

```bash
# Option 1: Nedavellir CLI
nv create your-project --template nv-gcp-template

# Option 2: GitHub template + scaffold script
git clone <your-new-repo>
cd <your-new-repo>
bash scripts/scaffold.sh --project your-project
```

### Setup

```bash
# Install dependencies
just setup --dev

# Configure .envrc with your GCP project details
vim .envrc

# Allow direnv
direnv allow

# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Create Terraform backend (one-time)
just tf-create-backend
```

### Deploy Infrastructure

```bash
just tf-init          # Initialize Terraform
just tf-plan          # Preview changes
just tf-apply         # Apply changes
```

### Available Commands

Type `just` to see all available commands:

```bash
❯ just
Available recipes:
    [terraform]
    tf-create-backend  # Create GCS backend bucket
    tf-init           # Initialize backend and workspace
    tf-plan           # Preview infrastructure changes
    tf-apply          # Apply Terraform changes
    tf-destroy        # Destroy infrastructure

    [docker]
    docker-build      # Build Docker images
    docker-push       # Push to GCP Artifact Registry

    [ci]
    publish           # Publish package
    deploy            # Deploy application
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
# After scaffolding, customize Docker and package publishing
just setup --dev
claude /adapt    # Guided customization (requires Claude CLI)
```

Update `Dockerfile` and `justfile` build-prod recipe for your language/framework.

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
