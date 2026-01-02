# Infrastructure Guide

> Infrastructure setup and deployment guide for {{PROJECT_NAME}}

## Overview

This document describes the infrastructure setup, deployment process, and operational considerations for {{PROJECT_NAME}}.

## Architecture

### Components

- **Application**: Core {{PROJECT_NAME}} service
- **Artifact Registry**: GCP Artifact Registry for container/package storage
- **CI/CD**: GitHub Actions for automated builds and deployments

### Deployment Environments

- **Development**: Local development environment (Docker)
- **Staging**: Pre-production testing environment (TODO: Configure as needed)
- **Production**: Live production environment (TODO: Configure as needed)

## Prerequisites

### Required Tools

- [Docker](https://docs.docker.com/get-docker/) - Container runtime
- [just](https://github.com/casey/just) - Command runner
- [direnv](https://direnv.net/) - Environment variable management
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) - Google Cloud tools (if using GCP)

### Cloud Accounts

Configure the following accounts as needed:

- **GitHub**: For repository hosting and CI/CD
- **GCP**: For Artifact Registry and cloud deployments (optional)

## Environment Configuration

### Local Environment

1. Copy `.envrc.template` to `.envrc`:
   ```bash
   cp .envrc.template .envrc
   ```

2. Update `.envrc` with your configuration:
   ```bash
   export PROJECT={{PROJECT_NAME}}
   export VERSION=$(get_version)

   # Registry Configuration (if using GCP)
   export GCP_REGISTRY_PROJECT_ID=your-project-id
   export GCP_REGISTRY_REGION=us-central1
   export GCP_REGISTRY_NAME=your-repository-name
   ```

3. Allow direnv to load the environment:
   ```bash
   direnv allow
   ```

### CI/CD Secrets

Configure these secrets in your GitHub repository settings:

#### Required for Releases

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

#### Optional for GCP Publishing

- `GCP_SA_KEY` - Service account key JSON for GCP authentication
- `GCP_REGISTRY_PROJECT_ID` - GCP project ID
- `GCP_REGISTRY_REGION` - GCP region (e.g., us-east1)
- `GCP_REGISTRY_NAME` - Artifact Registry repository name

> **Note**: Publishing to GCP is conditional. If `GCP_SA_KEY` is not configured, the release workflow will skip GCP publishing.

## Deployment

### Local Deployment

Build and run locally using Docker:

```bash
# Build the project
just build

# Run locally
just run

# Run tests
just test
```

### Production Deployment

Deployments are automated through GitHub Actions:

1. **Commit Changes**: Push commits using conventional commit messages
   ```bash
   git commit -m "feat: add new feature"
   git push
   ```

2. **Automated Release**: On push to `main`:
   - Tests run automatically
   - semantic-release determines the version
   - Release is created with artifacts
   - Artifacts published to registries (if configured)

3. **Manual Deployment**: If needed, deploy manually:
   ```bash
   # Build production artifacts
   just build-prod

   # Publish to registry
   just publish
   ```

## Registry Setup

### GCP Artifact Registry

1. **Create Repository**:
   ```bash
   gcloud artifacts repositories create {{PROJECT_NAME}} \
       --repository-format=docker \
       --location=us-east1 \
       --description="{{PROJECT_NAME}} container images"
   ```

2. **Configure Service Account**:
   ```bash
   # Create service account
   gcloud iam service-accounts create {{PROJECT_NAME}}-publisher \
       --display-name="{{PROJECT_NAME}} Publisher"

   # Grant permissions
   gcloud artifacts repositories add-iam-policy-binding {{PROJECT_NAME}} \
       --location=us-east1 \
       --member="serviceAccount:{{PROJECT_NAME}}-publisher@YOUR-PROJECT.iam.gserviceaccount.com" \
       --role="roles/artifactregistry.writer"

   # Create and download key
   gcloud iam service-accounts keys create key.json \
       --iam-account={{PROJECT_NAME}}-publisher@YOUR-PROJECT.iam.gserviceaccount.com
   ```

3. **Add to GitHub Secrets**:
   - Copy contents of `key.json` to `GCP_SA_KEY` secret
   - Set other GCP-related secrets

## Monitoring

### Health Checks

TODO: Add health check endpoints and monitoring configuration

### Logs

TODO: Add logging configuration and access instructions

### Metrics

TODO: Add metrics collection and dashboard links

## Backup & Recovery

TODO: Add backup procedures and disaster recovery plan

## Security

### Access Control

- Repository access managed through GitHub teams
- Cloud resource access via IAM roles
- Secrets stored in GitHub Secrets (encrypted at rest)

### Best Practices

- Use least-privilege IAM roles
- Rotate service account keys regularly
- Enable audit logging in cloud environments
- Review dependency vulnerabilities regularly

## Troubleshooting

### Common Issues

#### Authentication Failures

```bash
# Re-authenticate with GCP
gcloud auth login
gcloud auth configure-docker us-east1-docker.pkg.dev
```

#### Build Failures

```bash
# Clear Docker build cache
docker system prune -a

# Rebuild from scratch
just clean && just build
```

#### Deployment Failures

Check GitHub Actions logs:
1. Go to repository → Actions tab
2. Select failed workflow run
3. Review step-by-step logs

## Cost Optimization

- Use caching in CI/CD workflows
- Clean up old artifacts regularly
- Right-size cloud resources
- Monitor usage and set budget alerts

## Support

For infrastructure-related questions:
- File an issue in the GitHub repository
- Contact the DevOps team (TODO: Add contact info)

---

**Template**: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
