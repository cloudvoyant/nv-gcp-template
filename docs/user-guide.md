# User Guide

A practical guide for developers building on a project scaffolded from mise-app-template.

---

## Getting Started

### 1. Create Your Project

```bash
# Option 1: Using Nedavellir CLI
nv create your-project --template mise-app-template

# Option 2: Manual scaffold
git clone <your-repo>
cd <your-repo>
mise run scaffold --project your-project
```

### 2. Configure GCP Projects

Edit `mise.local.toml` (copy from `mise.local.toml.example`) with your project IDs and region:

```toml
[env]
GCP_DEVOPS_PROJECT_ID = "my-devops-project"
GCP_DEVOPS_PROJECT_REGION = "us-east1"
GCP_DEVOPS_REGISTRY_NAME = "my-artifact-registry"
GCP_DEVOPS_DOCKER_REGISTRY_NAME = "my-docker-registry"

GCP_PROJECT_ID = "my-app-project"
GCP_REGION = "us-east1"
```

Then install dev tools:

```bash
mise install
```

### 3. Set Up Kinde Authentication

Kinde is used for authentication. You need a Kinde account and application before deploying.

1. Go to [app.kinde.com](https://app.kinde.com) and create an account
2. Create a new business
3. Create a **Back-end web** application
4. Note your:
   - Domain (e.g. `yourapp.kinde.com`)
   - Client ID
   - Client Secret
5. Under **Redirect URLs**, add:
   - `https://your-domain/auth/callback` (production)
   - `http://localhost:5173/auth/callback` (local dev)
6. Under **Logout redirect URLs**, add:
   - `https://your-domain`
   - `http://localhost:5173`
7. Create `.env.local` in `apps/web/` for local development (never commit this file):

```bash
KINDE_DOMAIN=https://yourapp.kinde.com
KINDE_CLIENT_ID=your-client-id
KINDE_CLIENT_SECRET=your-client-secret
```

For deployed environments, store these values in GCP Secret Manager (see step 5).

### 4. Set Up GCP Authentication

Authenticate locally:

```bash
gcloud auth login
gcloud auth application-default login
```

Create a CI/CD service account and add it to GitHub:

```bash
# Create service account in DevOps project
gcloud iam service-accounts create github-actions \
  --project=${GCP_DEVOPS_PROJECT_ID}

# Grant necessary roles (adjust to least-privilege as needed)
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="serviceAccount:github-actions@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com
```

Then in GitHub:

1. Go to repository Settings → Secrets → Actions
2. Create secret `GCP_SA_KEY` with the contents of `github-actions-key.json`
3. Delete the local key file: `rm github-actions-key.json`

### 5. Configure GCP Secret Manager

For each deployed environment (`dev`, `stage`, `prod`), create a secret named `{PROJECT}-{ENV}` containing newline-separated key=value pairs:

```
KINDE_DOMAIN=https://yourapp.kinde.com
KINDE_CLIENT_ID=your-client-id
KINDE_CLIENT_SECRET=your-client-secret
BASE_DOMAIN=your-domain.com
```

You can create secrets via the GCP console or CLI:

```bash
echo "KINDE_DOMAIN=https://yourapp.kinde.com
KINDE_CLIENT_ID=your-client-id
KINDE_CLIENT_SECRET=your-client-secret
BASE_DOMAIN=your-domain.com" | \
  gcloud secrets create my-project-dev \
    --data-file=- \
    --project=${GCP_PROJECT_ID}
```

### 6. Create Terraform Backend

One-time setup to provision the GCS bucket used for Terraform state:

```bash
mise run tf-create-backend
```

### 7. Deploy Infrastructure

```bash
mise run tf-init
mise run tf-plan
mise run tf-apply
```

### 8. Run Locally

```bash
cd apps/web
pnpm dev
```

The app is available at `http://localhost:5173`.

---

## CI/CD Workflows

The template provides three deployment workflows based on git branching.

### Feature Branch Workflow (Preview Environments)

Branch naming: `feature/ISSUE-ID-description`, `bugfix/ISSUE-ID-description`, `hotfix/ISSUE-ID-description`

Examples:

- `feature/PROJ-123-add-storage` → workspace `proj-123`
- `bugfix/BUG-42-fix-auth` → workspace `bug-42`

What happens when you push:

1. CI runs tests, linting, and formatting checks
2. On success, the preview job:
   - Builds a Docker image tagged with the issue ID (e.g. `registry/app:proj-123`)
   - Publishes a pre-release package (e.g. `app@1.0.3-rc.proj-123`)
   - Creates an isolated Terraform workspace
   - Provisions preview infrastructure and deploys the application

When the PR is merged or the branch is deleted, the cleanup workflow automatically destroys all preview infrastructure and removes the Terraform workspace.

### Release Workflow (Dev Deployment)

Trigger: push to `main`

What happens:

1. Runs tests
2. Analyzes conventional commits to determine the version bump:
   - `feat:` → minor bump (1.0.0 → 1.1.0)
   - `fix:`, `docs:`, `refactor:`, etc. → patch bump (1.0.0 → 1.0.1)
   - `feat!:` or `BREAKING CHANGE:` → major bump (1.0.0 → 2.0.0)
3. If a new version is created:
   - Updates `version.txt` and `CHANGELOG.md`
   - Creates a git tag (e.g. `v1.2.3`)
   - Builds and publishes the package and Docker image
   - Deploys to the dev environment
   - Creates a GitHub Release

Commit convention:

```bash
git commit -m "feat: add cloud storage module"     # Minor bump
git commit -m "fix: resolve auth timeout"          # Patch bump
git commit -m "docs: update deployment guide"      # Patch bump
git commit -m "feat!: redesign API"                # Major bump
```

### Manual Deployment (Stage/Prod)

Trigger: manual workflow dispatch from the GitHub Actions UI

Steps:

1. Go to repository → Actions → "Manual Deployment"
2. Click "Run workflow"
3. Enter:
   - **Version**: the tag to deploy (e.g. `1.2.3`)
   - **Environment**: `stage` or `prod`
4. Click "Run workflow"
5. If the environment requires approval, designated reviewers will be notified

The workflow checks out git tag `v1.2.3`, runs Terraform plan/apply for the selected workspace, and deploys using the pre-built Docker image from the registry. The image must already exist (created during the release workflow).

### Environment Protection

1. Go to Settings → Environments
2. Create environments: `dev`, `stage`, `prod`
3. For `stage` and `prod`:
   - Add "Required reviewers"
   - Set branch restriction to `main`
4. For `dev`: no approvals needed

---

## E2E Tests

End-to-end tests use Playwright and run against a real authenticated user session.

### Prerequisites

- Playwright installed via `pnpm install` in `apps/web/`
- A test user created in your Kinde dashboard
- E2E secrets stored in GCP Secret Manager as `{PROJECT}-e2e-secrets`:
  ```
  E2E_P1_PASSWORD=the-test-user-password
  E2E_P1_USER_ID=kinde-user-id
  ```
- `apps/web/.env.e2e.local` with the test user's email (never commit this file):
  ```
  E2E_P1_EMAIL=test@example.com
  ```

### Running E2E Tests

```bash
# Fetch secrets from GCP Secret Manager (one-time, or after rotation)
mise run fetch-e2e-secrets

# Run tests against the local dev server
mise run test-e2e

# Run tests against a specific deployed environment
mise run test-e2e stage
```

### How It Works

- **Global setup** logs in as the test user and saves browser auth state to `apps/web/e2e/.auth/p1.json`
- **Tests** use `test.use({ storageState })` to reuse the saved session — no repeated logins
- **Global teardown** deletes all Firestore records whose `filename` starts with `[E2E]`
- **Seed data** for upload-related tests can be created via `just seed-e2e`

### Adding E2E Tests

1. Create a new `.spec.ts` file in `apps/web/e2e/`
2. Import the authenticated context at the top of the file:

```ts
import { test, expect } from "@playwright/test";
test.use({ storageState: "e2e/.auth/p1.json" });
```

3. Prefix any filenames created during the test with `[E2E]` so teardown cleans them up
4. Run `mise run test-e2e` to verify locally before pushing

---

## Local Development

### Running the Web App

```bash
cd apps/web
pnpm dev
```

### Environment Files

| File                      | Purpose                                             | Committed? |
| ------------------------- | --------------------------------------------------- | ---------- |
| `mise.toml`               | Non-secret environment config (project IDs, region) | Yes        |
| `mise.local.toml`         | Local overrides (developer-specific GCP IDs)        | No         |
| `apps/web/.env.local`     | Local secrets (Kinde credentials)                   | No         |
| `apps/web/.env.e2e.local` | E2E test config (test user email)                   | No         |

### Running Tests

```bash
mise run test
```

After scaffolding, implement your own tests:

1. Create test files in `template-tests/` with `.bats` extension
2. Update `.mise-tasks/test` if needed
3. Tests run automatically in CI on every push

### Local Docker Operations

```bash
# Build with current version from version.txt
mise run docker-build

# Build with a custom tag
mise run docker-build my-feature-tag

# Push to registry (requires gcloud auth)
mise run docker-push

# Push with a custom tag
mise run docker-push my-feature-tag
```

The image name follows this pattern:

```
${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}:${TAG}
```

### Local Artifact Publishing

```bash
# Publish release version (uses version.txt)
mise run publish

# Publish a pre-release with a custom tag
mise run publish my-test-tag
# Creates version: 1.0.3-rc.my-test-tag
```

### Viewing Hidden Files (VS Code)

Toggle file visibility to reduce noise while working:

```bash
# Hide infrastructure files — shows only: docs/, src/, template-tests/, .claude/, mise.toml, README.md
mise run hide

# Show all files including .github/, .vscode/, Dockerfile, .mise-tasks/, etc.
mise run show
```

Note: hidden files do not appear in VS Code search (Cmd+Shift+F) until you run `mise run show`.

---

## Troubleshooting

### Auth Redirect Loop

Check that your Kinde callback URL exactly matches `{origin}/auth/callback`. A trailing slash, wrong port, or mismatched protocol (`http` vs `https`) causes a redirect loop.

### E2E Tests Failing with Auth Errors

Re-run `mise run fetch-e2e-secrets` to refresh credentials, then delete the saved auth state and rerun:

```bash
rm apps/web/e2e/.auth/p1.json
mise run test-e2e
```

### Firestore Index Required Error

Composite indexes are managed via Terraform, not `firestore.indexes.json`. Run `mise run tf-apply` to provision the index, then wait 2-3 minutes for it to build before retrying.

### Terraform State Lock

If an operation fails with a state lock error:

```bash
# Only use if you are certain no other process is running
terraform force-unlock <LOCK_ID>
```

### Preview Environment Not Cleaning Up

Check the cleanup workflow logs in GitHub Actions. Common causes:

- Workflow did not trigger (check branch name matches the expected pattern)
- Terraform destroy failed due to missing permissions

Manually destroy the preview workspace:

```bash
mise run tf-destroy proj-123 --auto-approve
```

### Docker Push Authentication Failed

Ensure gcloud is authenticated and the Docker credential helper is configured:

```bash
gcloud auth login
gcloud auth configure-docker ${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev
```

### Package Upload Failed

Check that the service account has the `artifactregistry.writer` role on the DevOps project.

---

## Next Steps

- Review [architecture.md](architecture.md) for system design principles
- Customize `infra/modules/` for your infrastructure needs
- Update `.mise-tasks/deploy` for your deployment method
- Set up monitoring and alerting for your GCP resources
