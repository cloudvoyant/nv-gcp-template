# Development Guide

> Developer workflow and usage guide for {{PROJECT_NAME}}

## Getting Started

### Prerequisites

- Git - Version control
- just - Command runner ([installation](https://github.com/casey/just#installation))
- direnv - Environment management ([installation](https://direnv.net/docs/installation.html))
- Docker - Container runtime (optional)
- gcloud CLI - Google Cloud tools

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR-ORG/{{PROJECT_NAME}}.git
   cd {{PROJECT_NAME}}
   ```

2. Run setup script:
   ```bash
   bash scripts/setup.sh --dev
   ```

   This installs development tools (docker, gcloud, shellcheck, shfmt), Node.js, semantic-release, and optional tools.

3. Configure environment:
   ```bash
   # Allow direnv to load .envrc
   direnv allow

   # Verify environment
   echo $PROJECT
   echo $VERSION
   ```

4. Authenticate with GCP:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

5. Create Terraform backend (one-time setup):
   ```bash
   just tf-create-backend
   ```

## CI/CD Workflows

The project uses automated CI/CD based on git branching.

### Feature Branch Workflow

Branch naming: `feature/ISSUE-ID-description`, `bugfix/ISSUE-ID-description`, `hotfix/ISSUE-ID-description`

What happens when you push:

1. CI runs tests, linting, formatting checks
2. On success, preview job automatically:
   - Builds Docker image tagged with issue ID
   - Publishes pre-release package
   - Creates isolated Terraform workspace
   - Provisions preview infrastructure
   - Deploys application

When PR is merged or branch deleted:
- Cleanup workflow destroys all preview infrastructure
- Removes Terraform workspace

No manual steps required - everything is automated.

### Release Workflow

Trigger: Push to `main` branch

What happens:

1. Runs tests
2. Analyzes conventional commits to determine version bump
3. If new version created:
   - Updates version.txt and CHANGELOG.md
   - Creates git tag
   - Builds production artifacts
   - Publishes package
   - Builds and pushes Docker image
   - Deploys to dev environment
   - Creates GitHub Release

Commit convention:

```bash
git commit -m "feat: add cloud storage module"     # Minor bump
git commit -m "fix: resolve auth timeout"          # Patch bump
git commit -m "docs: update deployment guide"      # Patch bump
git commit -m "feat!: redesign API"                # Major bump
```

### Manual Deployment

For stage/prod deployments:

1. Go to repository → Actions → "Manual Deployment"
2. Click "Run workflow"
3. Enter version tag (e.g., `1.2.3`) and environment (`stage` or `prod`)
4. Click "Run workflow"
5. Approve if required

## Development Commands

Common commands using `just`:

```bash
# List all available commands
just

# Terraform operations
just tf-init          # Initialize backend and workspace
just tf-plan          # Preview infrastructure changes
just tf-apply         # Apply changes
just tf-destroy       # Destroy infrastructure

# Docker operations
just docker-build     # Build Docker images
just docker-push      # Push to GCP Artifact Registry

# Development
just build            # Build project
just run              # Run locally
just test             # Run tests
just format           # Format code
just lint             # Lint code
just clean            # Clean build artifacts
```

## Local Development Workflow

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/PROJ-123-your-feature
   ```

2. Make your changes, add tests, update documentation

3. Test locally:
   ```bash
   just test
   just lint
   just format-check
   ```

4. Test infrastructure changes:
   ```bash
   just tf-plan
   just tf-apply
   ```

5. Commit using conventional commits:
   ```bash
   git commit -m "feat: add new capability"
   ```

6. Push and create pull request:
   ```bash
   git push -u origin feature/PROJ-123-your-feature
   ```

### Workspace Management

Terraform workspace is automatically inferred from your git branch:
- On `main` branch → `dev` workspace
- On `feature/PROJ-123-*` → `proj-123` workspace
- On other branches → `dev` workspace (fallback)

Manual workspace operations:

```bash
# List all workspaces
just tf-list-workspaces

# Create/select workspace
just tf-select-workspace dev

# Auto-infer workspace from branch
just tf-select-workspace
```

## Customizing for Your Language

### Docker Image

Update `Dockerfile` with your language's build process:

```dockerfile
# Python example
FROM python:3.11-slim as base
WORKDIR /workspace
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "src/main.py"]

# Go example
FROM golang:1.21 as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server ./cmd/server

FROM alpine:latest
COPY --from=builder /app/server /server
CMD ["/server"]

# Node.js example
FROM node:20-alpine as base
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
CMD ["node", "src/index.js"]
```

### Package Publishing

Update `build-prod` recipe in `justfile`:

```just
# Python example
build-prod:
    python -m build
    cp dist/*.whl dist/artifact.txt

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

The `publish` recipe automatically uploads to GCP Artifact Registry:
- Release builds: `app@1.2.3`
- Preview builds: `app@1.0.3-rc.proj-123`

Optionally publish to language-specific registries (npm, PyPI, etc.) by modifying the `publish` recipe.

## Project Structure

```
{{PROJECT_NAME}}/
├── .github/           # GitHub Actions workflows
│   ├── actions/       # Composite actions
│   └── workflows/     # CI/CD workflows
├── .claude/           # AI assistant configuration
├── docs/              # Documentation
│   ├── architecture.md
│   ├── user-guide.md
│   └── infrastructure.md
├── infra/             # Terraform infrastructure
│   ├── modules/       # Terraform modules
│   └── environments/  # Environment configuration
├── scripts/           # Build and setup scripts
├── src/               # Source code (customize)
├── test/              # Test files (customize)
├── .envrc             # Environment variables
├── Dockerfile         # Container definition
├── docker-compose.yml # Local development
├── justfile           # Command definitions
└── README.md          # Project overview
```

## Testing

### Running Tests

```bash
# Run all tests
just test
```

After scaffolding, implement your own tests:
1. Create test files in `test/` directory
2. Update `test` recipe in justfile
3. Tests run automatically in CI

### Viewing Hidden Files (VS Code)

Toggle file visibility to focus on code or see full project structure:

```bash
# Hide infrastructure files
just hide

# Show all files
just show
```

Limitation: Hidden files won't appear in VS Code search (Cmd+Shift+F) unless you run `just show` first.

## Versioning

This project uses semantic versioning (SemVer):

- Major (1.0.0): Breaking changes
- Minor (0.1.0): New features (backwards compatible)
- Patch (0.0.1): Bug fixes

Versions are determined automatically by semantic-release based on commit messages.

Check current version:

```bash
just version
```

## Pull Request Process

1. Open PR on GitHub
2. Ensure CI passes (tests, formatting, linting)
3. Request review from team members
4. Address feedback and push updates
5. Merge when approved

## Troubleshooting

### Environment not loading

```bash
# Check direnv status
direnv status

# Re-allow direnv
direnv allow
```

### Terraform state lock

```bash
# Only use if you're certain no other process is running
terraform force-unlock <LOCK_ID>
```

### Docker authentication failed

```bash
gcloud auth login
gcloud auth configure-docker ${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev
```

### Build failures

```bash
# Clean and rebuild
just clean
just build
```

## Contributing Guidelines

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code change (no feature/fix)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

### Code Review

- Be respectful and constructive
- Explain reasoning behind suggestions
- Approve when changes look good

### Documentation

- Update docs with code changes
- Keep README current
- Document new features
- Add ADRs for significant decisions

## Resources

### Documentation

- [Architecture Guide](./architecture.md) - System design details
- [User Guide](./user-guide.md) - CI/CD workflow details
- [Infrastructure Guide](./infrastructure.md) - Terraform operations

### Getting Help

- File an issue in the GitHub repository
- Review documentation
- Contact team members

---

Template: {{TEMPLATE_NAME}} v{{TEMPLATE_VERSION}}
