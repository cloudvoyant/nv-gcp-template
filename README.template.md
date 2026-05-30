# {{PROJECT_NAME}}

> TODO: Add project description

## Features

- Automated preview environments for feature/bugfix/hotfix branches
- Terraform workspace isolation (dev, stage, prod, preview)
- Shared GCS backend for centralized state management
- GitHub Actions workflows for automated deployment
- Docker image builds and publishing to GCP Artifact Registry
- Package publishing to GCP Artifact Registry
- Manual deployment workflows with approval gates
- Semantic versioning with conventional commits

## Requirements

- bash 3.2+
- mise - Dev tool and task runner
- Terraform 1.5+ (managed by mise)
- gcloud CLI
- GCP project with billing enabled

## Quick Start

### Setup

```bash
# Install all dev tools and dependencies
mise install

# Configure GCP project details in mise.local.toml (optional local overrides)
cp mise.local.toml.example mise.local.toml
vim mise.local.toml

# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

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

1. Analyzes conventional commits for version bump
2. Updates version.txt and CHANGELOG.md
3. Creates git tag and GitHub Release
4. Builds and publishes package and Docker image
5. Deploys to dev environment

Commit convention:

```bash
git commit -m "feat: add cloud storage module"     # Minor bump
git commit -m "fix: resolve auth timeout"          # Patch bump
git commit -m "docs: update deployment guide"      # Patch bump
git commit -m "feat!: redesign API"                # Major bump
```

### Manual Deployment

Deploy to stage/prod via GitHub Actions:

1. Go to Actions → Manual Deployment
2. Select version tag and environment
3. Approve deployment (if required)

## Project Structure

```
{{PROJECT_NAME}}/
├── .github/           # GitHub Actions workflows
│   ├── actions/       # Composite actions
│   └── workflows/     # CI/CD workflows
├── infra/             # Terraform infrastructure
│   ├── modules/       # Terraform modules
│   └── environments/  # Environment configuration
├── docs/              # Documentation
├── scripts/           # Build and setup scripts
├── src/               # Source code (customize)
├── test/              # Test files (customize)
├── mise.toml          # Dev tools and environment configuration
├── .mise-tasks/       # Task scripts (mise run <task>)
├── Dockerfile         # Container definition
├── docker-compose.yml # Local development
└── README.md          # Project overview
```

## Customization

Customize Docker and package publishing for your language:

Update `Dockerfile`:

```dockerfile
# Python example
FROM python:3.11-slim as base
WORKDIR /workspace
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "src/main.py"]
```

Update `.mise-tasks/build-prod`:

```bash
#!/usr/bin/env bash
#MISE description="Build production artifact"
set -euo pipefail
# Python example
python -m build
cp dist/*.whl dist/artifact.txt
```

## Documentation

- [User Guide](docs/user-guide.md) - Complete setup and CI/CD workflow guide
- [Architecture](docs/architecture.md) - System design and Terraform structure
- [Infrastructure Guide](docs/infrastructure.md) - Infrastructure operations

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [mise dev tool manager](https://mise.jdx.dev/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)

---

Template: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
