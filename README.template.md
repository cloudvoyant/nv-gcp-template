# {{PROJECT_NAME}}

> GCP infrastructure project scaffolded from {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}

A GCP infrastructure project using Terraform for multi-environment deployments with automated CI/CD pipelines.

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
- just - Command runner
- Terraform 1.5+
- gcloud CLI
- GCP project with billing enabled

## Quick Start

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
├── .envrc             # Environment variables
├── Dockerfile         # Container definition
├── docker-compose.yml # Local development
├── justfile           # Command definitions
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

Update `justfile` build-prod recipe:

```just
# Python example
build-prod:
    python -m build
    cp dist/*.whl dist/artifact.txt
```

## Documentation

- [User Guide](docs/user-guide.md) - Complete setup and CI/CD workflow guide
- [Architecture](docs/architecture.md) - System design and Terraform structure
- [Infrastructure Guide](docs/infrastructure.md) - Infrastructure operations

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)

---

Template: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
