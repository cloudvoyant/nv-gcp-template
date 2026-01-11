# User Guide

A GCP infrastructure template using Terraform for multi-environment deployments with automated CI/CD pipelines.

## Getting Started

### 1. Create Your Project

```bash
# Option 1: Using Nedavellir CLI
nv create your-project --template nv-gcp-template

# Option 2: Manual setup
git clone <your-repo>
cd <your-repo>
bash scripts/scaffold.sh --project your-project
```

### 2. Configure GCP Projects

Edit `.envrc`:

```bash
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

### 3. Set Up GCP Authentication

Authenticate locally:

```bash
gcloud auth login
gcloud auth application-default login
```

Create CI/CD service account:

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

### 4. Create Terraform Backend

One-time setup:

```bash
just tf-create-backend
```

### 5. Deploy Infrastructure

```bash
just tf-init
just tf-plan
just tf-apply
```

## CI/CD Workflows

The template provides three deployment workflows based on git branching.

### Feature Branch Workflow (Preview Environments)

Branch naming: `feature/ISSUE-ID-description`, `bugfix/ISSUE-ID-description`, `hotfix/ISSUE-ID-description`

Examples:
- `feature/PROJ-123-add-storage` → workspace `proj-123`
- `bugfix/BUG-42-fix-auth` → workspace `bug-42`

What happens:

1. Push to feature branch triggers CI workflow
2. CI runs tests, linting, formatting checks
3. On success, preview job:
   - Builds Docker image tagged with issue ID (e.g., `registry/app:proj-123`)
   - Publishes pre-release package (e.g., `app@1.0.3-rc.proj-123`)
   - Creates isolated Terraform workspace
   - Provisions preview infrastructure
   - Deploys application

4. When PR is merged or branch deleted:
   - Cleanup workflow destroys all preview infrastructure
   - Removes Terraform workspace

No manual steps required - everything is automated.

### Release Workflow (Dev Deployment)

Trigger: Push to `main` branch

What happens:

1. Runs tests
2. Analyzes conventional commits to determine version bump:
   - `feat:` → minor bump (1.0.0 → 1.1.0)
   - `fix:`, `docs:`, `refactor:`, etc. → patch bump (1.0.0 → 1.0.1)
   - `feat!:` or `BREAKING CHANGE:` → major bump (1.0.0 → 2.0.0)

3. If new version created:
   - Updates `version.txt` and `CHANGELOG.md`
   - Creates git tag (e.g., `v1.2.3`)
   - Builds production artifacts
   - Publishes package (e.g., `app@1.2.3`)
   - Builds Docker image tagged with version (e.g., `registry/app:1.2.3`)
   - Pushes Docker image to registry
   - Deploys to dev environment
   - Creates GitHub Release

Commit convention:

```bash
git commit -m "feat: add cloud storage module"     # Minor bump
git commit -m "fix: resolve auth timeout"          # Patch bump
git commit -m "docs: update deployment guide"      # Patch bump
git commit -m "feat!: redesign API"                # Major bump
```

### Manual Deployment (Stage/Prod)

Trigger: Manual workflow dispatch

Steps:

1. Go to repository → Actions → "Manual Deployment"
2. Click "Run workflow"
3. Enter:
   - Version: Version tag to deploy (e.g., `1.2.3`)
   - Environment: `stage` or `prod`
4. Click "Run workflow"
5. If environment requires approval, designated reviewers will be notified

What happens:

- Checks out git tag `v1.2.3`
- Uses version from that tag's `version.txt`
- Runs Terraform plan/apply for selected workspace
- Deploys application using pre-built Docker image from registry

Note: Image must already exist in registry (created during release workflow).

### Environment Protection

Configure approval requirements:

1. Go to Settings → Environments
2. Create environments: `dev`, `stage`, `prod`
3. For `stage` and `prod`:
   - Add "Required reviewers"
   - Set branch restriction to `main`
4. For `dev`: No approvals needed

## Language-Specific Customization

The template includes placeholder Docker and artifact publishing that you'll customize for your language.

### Customizing Docker Image

Step 1: Update Dockerfile

The default `Dockerfile` is a minimal example. Replace it with your language's build process:

```dockerfile
# Python Example
FROM python:3.11-slim as base
WORKDIR /workspace
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "src/main.py"]

# Go Example
FROM golang:1.21 as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server ./cmd/server

FROM alpine:latest
COPY --from=builder /app/server /server
CMD ["/server"]

# Node.js Example
FROM node:20-alpine as base
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
CMD ["node", "src/index.js"]
```

Step 2: Update docker-compose.yml (optional)

The `docker-compose.yml` file is for local development. Modify the services as needed:

```yaml
services:
  runner:
    build:
      context: .
      dockerfile: Dockerfile
      target: base
    image: ${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}:${VERSION}
    container_name: ${PROJECT}-runner
    volumes:
      - .:/workspace
    working_dir: /workspace
    command: bash -c "just run"  # Customize this command
```

Step 3: Image is automatically built and pushed by CI

No changes needed to workflows - they use:
- `just docker-build` → runs `docker compose build`
- `just docker-push` → authenticates and pushes to GCP Artifact Registry

### Customizing Package Publishing

Step 1: Update build-prod recipe

Edit `justfile` to build your language's artifacts:

```just
# Python example
build-prod:
    python -m build
    cp dist/*.whl dist/artifact.txt  # or whatever your artifact is

# Go example
build-prod:
    GOOS=linux GOARCH=amd64 go build -o dist/myapp-linux-amd64
    echo "myapp-linux-amd64" > dist/artifact.txt

# Node.js example
build-prod:
    npm run build
    npm pack --pack-destination=dist/
    ls dist/*.tgz > dist/artifact.txt
```

Step 2: Package is automatically published by CI

The `publish` recipe uploads to GCP Artifact Registry:
- Release builds: `app@1.2.3`
- Preview builds: `app@1.0.3-rc.proj-123`

Step 3: Optional - Publish to language-specific registries

Modify the `publish` recipe to also publish to npm, PyPI, etc.:

```just
publish TAG="":
    # ... existing GCP artifact registry upload ...

    # Publish to npm
    if [ -z "{{TAG}}" ]; then
        npm publish
    fi

    # Publish to PyPI
    if [ -z "{{TAG}}" ]; then
        python -m twine upload dist/*
    fi
```

## Local Development

### Viewing Hidden Files (VS Code)

Toggle file visibility to focus on code or see full project structure:

```bash
# Hide infrastructure files, show only: docs/, src/, test/, .claude/, .envrc, justfile, README.md
just hide

# Show all files including .github/, .vscode/, Dockerfile, scripts/, etc.
just show
```

Limitation: Hidden files won't appear in VS Code search (Cmd+Shift+F) unless you run `just show` first.

### Local Docker Operations

Build and push Docker images locally:

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

The image name follows this pattern:
```
${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}:${TAG}
```

### Local Artifact Publishing

Publish packages locally:

```bash
# Publish release version (uses version.txt)
just publish

# Publish pre-release with tag
just publish my-test-tag
# Creates version: 1.0.3-rc.my-test-tag
```

### Running Tests

```bash
just test
```

After scaffolding, implement your own tests:
1. Create test files in `test/` directory
2. Update `test` recipe in justfile
3. Tests run automatically in CI

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

### Package Upload Failed

Check service account has `artifactregistry.writer` role on DevOps project.

## Next Steps

- Review [architecture.md](architecture.md) for system design details
- Customize `infra/modules/` for your infrastructure needs
- Update `justfile` deploy recipe for your deployment method
- Set up monitoring and alerting for your resources
