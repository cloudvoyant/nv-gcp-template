# Development Guide

> Developer workflow and usage guide for {{PROJECT_NAME}}

## Getting Started

### Prerequisites

- Git - Version control
- [mise](https://mise.jdx.dev/) - Tool version management and task runner
- Docker - Container runtime (optional)
- gcloud CLI - Google Cloud tools

### Initial Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/YOUR-ORG/{{PROJECT_NAME}}.git
   cd {{PROJECT_NAME}}
   ```

2. Install all dev tools and dependencies:

   ```bash
   mise install
   ```

   mise reads `mise.toml` and installs the correct versions of node, pnpm, terraform, bats, shellcheck, and shfmt.

3. Configure environment:

   ```bash
   # Verify environment variables
   mise env
   echo $PROJECT
   echo $VERSION
   ```

   Override defaults by creating `mise.local.toml` (see `mise.local.toml.example`).

4. Authenticate with GCP:

   ```bash
   mise run gcp-login
   ```

5. Create Terraform backend (one-time setup):
   ```bash
   mise run tf-create-backend
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

Common commands using `mise run`:

```bash
# List all available tasks
mise tasks

# Terraform operations
mise run tf-init          # Initialize backend and workspace
mise run tf-plan          # Preview infrastructure changes
mise run tf-apply         # Apply changes
mise run tf-destroy       # Destroy infrastructure

# Docker operations
mise run docker-build     # Build Docker images
mise run docker-push      # Push to GCP Artifact Registry

# Development
mise run build            # Build project
mise run run              # Run locally
mise run test             # Run tests
mise run format           # Format code
mise run lint             # Lint code
mise run clean            # Clean build artifacts
```

## Web App Development

### Running Locally

```bash
cd apps/web && pnpm dev
```

### Environment Files

Create `apps/web/.env.local` for local secrets — this file is never committed:

```bash
# Kinde OAuth credentials
KINDE_DOMAIN=https://your-app.kinde.com
KINDE_CLIENT_ID=your_client_id
KINDE_CLIENT_SECRET=your_client_secret

# GCP configuration
GCP_PROJECT_ID=your-gcp-project
BASE_DOMAIN=your-domain.com
```

### Routes and Components

- SvelteKit routes live in `apps/web/src/routes/`
- UI components come from `@{{PROJECT_NAME}}/ui` (shadcn-svelte, built on bits-ui + Tailwind)
- Import UI components from the library — do not copy component source into the app

### Authentication

Auth flows are handled entirely by `libs/auth`. Import `@{{PROJECT_NAME}}/auth` in server-side code only (hooks, `+page.server.ts`, `+layout.server.ts`). Never import auth utilities in client-side modules.

## E2E Testing

### Prerequisites

- A test Kinde user account provisioned for E2E
- E2E secrets stored in GCP Secret Manager (`{{PROJECT_NAME}}-e2e-secrets`)

### Setup and Running

```bash
# Fetch E2E secrets from Secret Manager to .env.e2e.local
mise run fetch-e2e-secrets

# Seed Firestore with test data
mise run seed-e2e

# Run the full Playwright suite (fetches secrets automatically if missing)
mise run test-e2e
```

### Adding Tests

1. Create `.spec.ts` files in `apps/web/e2e/`
2. Use `storageState: 'e2e/.auth/p1.json'` to reuse the authenticated session
3. Prefix test-created Firestore records with `[E2E]` — global teardown deletes them automatically

Example test file:

```typescript
import { test, expect } from "@playwright/test";

test.use({ storageState: "e2e/.auth/p1.json" });

test("user can upload an image", async ({ page }) => {
  // ...
});
```

Global teardown runs after every suite and cleans up any Firestore documents whose names or relevant fields are prefixed with `[E2E]`.

## Local Development Workflow

### Making Changes

1. Create a feature branch:

   ```bash
   git checkout -b feature/PROJ-123-your-feature
   ```

2. Make your changes, add tests, update documentation

3. Test locally:

   ```bash
   mise run test
   mise run lint
   mise run format-check
   ```

4. Test infrastructure changes:

   ```bash
   mise run tf-plan
   mise run tf-apply
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
mise run tf-list-workspaces

# Create/select workspace
mise run tf-select-workspace dev

# Auto-infer workspace from branch
mise run tf-select-workspace
```

## Customizing for Your Language

### Docker Image

Update `dockerfiles/base.dockerfile` with your language's build process:

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

Update `build-prod` task in `mise-tasks/build-prod`:

```bash
# Python example
pip install build
python -m build
cp dist/*.whl dist/artifact.txt

# Go example
GOOS=linux GOARCH=amd64 go build -o dist/myapp-linux-amd64
echo "myapp-linux-amd64" > dist/artifact.txt

# Node.js example
pnpm build
pnpm pack --pack-destination=dist/
ls dist/*.tgz > dist/artifact.txt
```

The `publish` task automatically uploads to GCP Artifact Registry:

- Release builds: `app@1.2.3`
- Preview builds: `app@1.0.3-rc.proj-123`

Optionally publish to language-specific registries (npm, PyPI, etc.) by modifying the `publish` task.

## Project Structure

```
{{PROJECT_NAME}}/
├── apps/
│   └── web/               # SvelteKit application
│       ├── src/
│       ├── e2e/           # Playwright E2E tests
│       └── package.json
├── libs/
│   ├── auth/              # @{{PROJECT_NAME}}/auth — Kinde OAuth client
│   ├── storage/           # @{{PROJECT_NAME}}/storage — GCS client + image resize
│   └── ui/                # @{{PROJECT_NAME}}/ui — shadcn-svelte component library
├── infra/
│   ├── shared/            # CDN + public bucket (one-time setup)
│   ├── environments/      # Per-workspace Cloud Run + Firestore + bucket
│   └── modules/           # Reusable Terraform modules
├── mise-tasks/           # All task scripts (auto-discovered by mise)
├── mise.toml              # Tool versions, environment, task runner config
└── README.md
```

## Testing

### Running Tests

```bash
# Run all tests
mise run test
```

After scaffolding, implement your own tests:

1. Create test files in your preferred test directory
2. Update the `test` task in `mise-tasks/test`
3. Tests run automatically in CI

### Viewing Hidden Files (VS Code)

Toggle file visibility to focus on code or see full project structure:

```bash
# Hide infrastructure files
mise run hide

# Show all files
mise run show
```

Limitation: Hidden files won't appear in VS Code search (Cmd+Shift+F) unless you run `mise run show` first.

## Versioning

This project uses semantic versioning (SemVer):

- Major (1.0.0): Breaking changes
- Minor (0.1.0): New features (backwards compatible)
- Patch (0.0.1): Bug fixes

Versions are determined automatically by semantic-release based on commit messages.

Check current version:

```bash
mise run version
```

## Pull Request Process

1. Open PR on GitHub
2. Ensure CI passes (tests, formatting, linting)
3. Request review from team members
4. Address feedback and push updates
5. Merge when approved

## Troubleshooting

### Tools not found after clone

```bash
# Reinstall all tools
mise install

# Verify tool versions
mise list
```

### Terraform state lock

```bash
# Only use if you're certain no other process is running
terraform force-unlock <LOCK_ID>
```

### Docker authentication failed

```bash
mise run gcp-login
gcloud auth configure-docker ${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev
```

### Build failures

```bash
# Clean and rebuild
mise run clean
mise run build
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
