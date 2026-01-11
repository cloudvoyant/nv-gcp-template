# User Guide

`nv-gcp-template` is a GCP infrastructure-as-code template using Terraform for resource management with robust CI/CD that supports multiple environments, artifact publishing and automated infrastructure updates.

## Features

Here's what this template enables you to do:

- Manage infra declaratively with IaC via Terraform
- Manage multiple environments with Terraform workspaces
- Implement trunk-based development for projects with infra
- Automate infra updates across environments via GitHub Actions
- Create preview environments (with isolated infra) on commits to `feature/hotfix/bugfix` branches
- Offer a self-documenting command interface for Terraform operations (`tf-plan`, `tf-apply`, `tf-destroy`) as well as other common project tasks such as building, testing, etc.
- Standardize env configuration for managing infra and code artifacts with GCP
- Support cross-platform development for contributors

## Requirements

- bash 3.2+
- [just](https://just.systems/man/en/)
-
- [Terraform](https://www.terraform.io/) 1.5+
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- GCP project with billing enabled

Run `just setup` to install bash, just, and direnv.

Optional: `just setup --dev` for development tools (docker, gcloud, shellcheck, etc.)

## Quick Start

### 1. Scaffold a New Project

```bash
# Option 1: Nedavellir CLI (automated)
nv create your-infra-project --template nv-gcp-template

# Option 2: GitHub template + scaffold script
# Click "Use this template" on GitHub, then:
git clone <your-new-repo>
cd <your-new-repo>
bash scripts/scaffold.sh --project your-infra-project
```

### 2. Configure GCP Projects

Edit `.envrc` with your GCP project details:

```bash
# DevOps Project (hosts tfstate bucket, registries)
export GCP_DEVOPS_PROJECT_ID=my-devops-project
export GCP_DEVOPS_PROJECT_REGION=us-east1
export GCP_DEVOPS_REGISTRY_NAME=my-registry

# Infrastructure Project (where resources are provisioned)
export GCP_PROJECT_ID=my-app-project
export GCP_REGION=us-east1
```

Allow direnv to load the configuration:

```bash
direnv allow
```

### 3. Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login
```

### 4. Create Terraform Backend

This is a one-time setup to create the GCS bucket for Terraform state:

```bash
just tf-create-backend
```

### 5. Initialize and Deploy

```bash
just tf-init          # Initialize Terraform backend and workspace
just tf-plan          # Preview infrastructure changes
just tf-apply         # Apply changes (creates a storage bucket by default)
```

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

### Using Docker

The template includes Docker support for running tasks in isolated containers without installing dependencies on your host machine.

Prerequisites:

- Docker Desktop or Docker Engine

Available Docker commands:

```bash
just docker-build    # Build the Docker image
just docker-run      # Run the project in a container
just docker-test     # Run tests in a container
```

The `Dockerfile` and `docker-compose.yml` are configured to install all required dependencies automatically. This is useful for:

- Running tasks without installing tools locally
- Ensuring consistency across different development machines
- Testing in a clean environment

### Using Dev Containers

The template includes a pre-configured devcontainer for consistent cross-platform development environments across your team.

Prerequisites on host:

- Docker Desktop or Docker Engine
- VS Code with Dev Containers extension

If you have Docker running and the Dev Container extension installed, then you can simply:

1. Open project in VS Code
2. Command Palette (Cmd/Ctrl+Shift+P) → "Dev Containers: Reopen in Container"
3. Wait for container build (first time only)

VS Code should reopen. In your terminal, you will now find everything you need including `just`, `direnv`, `gcloud` and more:

- Git, GitHub CLI, and Google Cloud CLI pre-installed
- Git credentials automatically shared from host via SSH agent forwarding
- Claude CLI credentials mounted from `~/.claude`
- All VS Code extensions for shell development (shellcheck, just syntax, etc.)
- Docker-in-Docker support for building containers

Authentication:

- Git/GitHub: Automatic via SSH agent forwarding (no setup needed)
- gcloud: Run `gcloud auth login` inside the container on first use
- Claude: Automatically available if configured on host

## Terraform Workflows

### Local Development

Work on infrastructure changes locally before pushing:

```bash
# Plan changes for current workspace (inferred from branch)
just tf-plan

# Plan changes for specific workspace
just tf-plan dev

# Apply changes with confirmation prompt
just tf-apply

# Apply changes without prompt (use in CI)
just tf-apply dev --auto-approve

# Destroy infrastructure (prompts for confirmation)
just tf-destroy

# Destroy without confirmation (use in CI)
just tf-destroy preview-123 --auto-approve
```

The workspace is automatically inferred from your current git branch:

- On `main` branch → `dev` workspace
- On `feature/PROJ-123-*` → `proj-123` workspace
- On other branches → `dev` workspace (fallback)

### Preview Environments

Preview environments are automatically created when you push to feature/bugfix/hotfix branches:

**Branch Naming Pattern**: `feature/TRACKER-ID-description`

Examples:

- `feature/JIRA-123-add-monitoring` → workspace `jira-123`
- `bugfix/BUG-1-fix-auth` → workspace `bug-1`
- `hotfix/PROD-999-critical` → workspace `prod-999`

**Workflow**:

1. Create a branch: `git checkout -b feature/PROJ-456-new-feature`
2. Push to GitHub: `git push origin feature/PROJ-456-new-feature`
3. GitHub Actions automatically:

   - Extracts issue ID (`proj-456`)
   - Creates Terraform workspace `proj-456`
   - Provisions infrastructure
   - Comments on PR with deployment details

4. When merged or branch deleted:
   - GitHub Actions runs cleanup workflow
   - Destroys all infrastructure in that workspace
   - Removes the Terraform workspace

### Stage and Production Deployments

Stage and production deployments are manual and require approval:

1. **Navigate to GitHub Actions**: Go to your repository → Actions tab

2. **Run Manual Deployment**:

   - Select "Manual Deployment" workflow
   - Click "Run workflow"
   - Enter version tag (e.g., `1.2.3`)
   - Select environment (`stage` or `prod`)
   - Click "Run workflow"

3. **Approve Deployment** (if required):
   - GitHub will pause and request approval
   - Designated approvers review the deployment
   - Click "Approve and deploy" to proceed

### Commit and Release

Use conventional commits for automatic versioning:

```bash
git commit -m "feat: add cloud run module"      # Minor bump (0.1.0 → 0.2.0)
git commit -m "fix: resolve bucket policy"      # Patch bump (0.1.0 → 0.1.1)
git commit -m "docs: update architecture"       # No bump
git commit -m "feat!: breaking change"          # Major bump (0.1.0 → 1.0.0)
```

Push to main:

```bash
git push origin main
```

CI/CD automatically:

- Runs tests (if configured)
- Creates a new release with semantic-release
- Builds and pushes Docker image (optional)
- Updates dev environment infrastructure

### Viewing Hidden Files (VS Code)

The template provides `just hide` and `just show` commands to toggle file visibility in VS Code, helping you focus on code or see the full project structure as needed.

Hide non-essential files (show only code and documentation):

```bash
just hide
```

This hides infrastructure files and shows only: `docs/`, `src/`, `test/`, `.claude/`, `.envrc`, `justfile`, and `README.md`.

Show all files:

```bash
just show
```

This reveals all hidden configuration files (`.github/`, `.vscode/`, `.devcontainer/`, `Dockerfile`, `docker-compose.yml`, `scripts/`, etc.).

**Note**: These commands are VS Code-specific and modify `.vscode/settings.json`. If you use a different editor, you'll need to configure file visibility using your editor's native settings.

**Limitation**: Hidden files won't appear in VS Code search results (Cmd+Shift+F) unless you run `just show` first or toggle "Use Exclude Settings" in the search panel.

## GCP Authentication

### Local Development

For local Terraform operations:

```bash
# Authenticate with your user account
gcloud auth login

# Set up application default credentials for Terraform
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

### CI/CD (GitHub Actions)

Create a service account with appropriate permissions:

```bash
# In DevOps project (for tfstate and registries)
gcloud iam service-accounts create terraform-ci \
  --project=${GCP_DEVOPS_PROJECT_ID} \
  --display-name="Terraform CI/CD"

# Grant roles in DevOps project
gcloud projects add-iam-policy-binding ${GCP_DEVOPS_PROJECT_ID} \
  --member="serviceAccount:terraform-ci@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding ${GCP_DEVOPS_PROJECT_ID} \
  --member="serviceAccount:terraform-ci@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Grant roles in Infrastructure project
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:terraform-ci@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Add other roles as needed for your resources (compute.admin, etc.)

# Create and download key
gcloud iam service-accounts keys create terraform-ci-key.json \
  --iam-account=terraform-ci@${GCP_DEVOPS_PROJECT_ID}.iam.gserviceaccount.com \
  --project=${GCP_DEVOPS_PROJECT_ID}
```

Add the key content to GitHub Secrets:

1. Go to repository Settings → Secrets → Actions
2. Create new secret: `GCP_SA_KEY`
3. Paste the entire contents of `terraform-ci-key.json`
4. Delete the local key file: `rm terraform-ci-key.json`

### GitHub Environment Configuration

Configure environments with approval requirements:

1. Go to repository Settings → Environments
2. Create environments: `dev`, `stage`, `prod`
3. For `stage` and `prod`:
   - Add "Required reviewers" (select team members)
   - Set deployment branch rule to "Selected branches" → `main`
4. For `dev`:
   - No approvals needed (auto-deploys)

## Customizing Infrastructure

### Adding New Terraform Modules

Create a new module in `infra/modules/`:

```bash
mkdir -p infra/modules/cloud-run
cd infra/modules/cloud-run
```

Create `main.tf`, `variables.tf`, and `outputs.tf` following the same pattern as the storage-bucket module.

Instantiate the module in `infra/environments/main.tf`:

```hcl
module "cloud_run" {
  source = "../modules/cloud-run"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name
}
```

### Customizing the Deploy Recipe

The `deploy` recipe is a placeholder for post-infrastructure deployment steps. Edit it in `justfile`:

```just
deploy WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="${WORKSPACE:-$(infer_terraform_workspace)}"

    log_info "Deploying application to workspace: ${WORKSPACE_NAME}"

    # Example: Deploy to Cloud Run
    # gcloud run deploy my-service \
    #     --image=gcr.io/${GCP_PROJECT_ID}/my-app:latest \
    #     --region=${GCP_REGION} \
    #     --platform=managed

    # Example: Deploy to GKE
    # kubectl apply -f k8s/ --context=${WORKSPACE_NAME}
```

## Troubleshooting

### Terraform State Lock Issues

If Terraform operations fail with a state lock error:

```bash
# List locks (requires storage.objects.list permission)
gsutil ls gs://${PROJECT}-tfstate/terraform/state/

# Remove a stuck lock (use with caution!)
# Only do this if you're CERTAIN no other process is running
terraform force-unlock <LOCK_ID>
```

### Workspace Not Found

If you get "workspace doesn't exist" errors:

```bash
# List available workspaces
cd infra/environments
terraform workspace list

# Create workspace manually if needed
terraform workspace new <workspace-name>
```

### Permission Denied Errors

Verify your service account has the necessary roles:

```bash
# Check IAM policy for DevOps project
gcloud projects get-iam-policy ${GCP_DEVOPS_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-ci@*"

# Check IAM policy for Infrastructure project
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-ci@*"
```

### GitHub Actions Workflow Failures

View detailed logs:

1. Go to repository → Actions tab
2. Click on the failed workflow run
3. Expand each step to see error messages
4. Check "Terraform Plan" and "Terraform Apply" steps for infrastructure errors

Common issues:

- Missing `GCP_SA_KEY` secret
- Service account permissions insufficient
- Backend bucket doesn't exist (run `just tf-create-backend`)
- Invalid Terraform syntax (test locally with `just tf-plan`)

## Advanced Usage

### Managing Multiple Infrastructure Projects

If you have multiple infrastructure repositories deploying to the same GCP project, the resource labeling convention allows you to identify resources by project:

```bash
# List all resources for a specific project in GCP Console
# Filter by labels: project=myapp, environment=dev
```

### Understanding State Management

#### Shared Backend Architecture

This template uses a **shared backend bucket** approach where all GCP projects and applications store state in a single GCS bucket:

- **Shared Bucket**: `${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage` (e.g., `devops-466002-terraform-backend-storage`)
- **Prefix**: `${GCP_PROJECT_ID}/${PROJECT}` (GCP project + application name)
- **Workspace**: `dev`, `stage`, `prod`, or preview workspace like `proj-123`

**Full state path example:**

```
gs://devops-466002-terraform-backend-storage/my-gcp-project/myapp/env:/dev/default.tfstate
                                              └─gcp-project─┘ └app┘ └workspace┘
```

#### Why This Approach?

1. **Multi-GCP-Project Support**: Multiple GCP projects can share the same backend
2. **Clear Hierarchy**: GCP Project → Application → Environment is explicit
3. **Complete Isolation**: Each GCP project + app is fully isolated by prefix
4. **Standard Tooling**: Uses Terraform's built-in workspace feature
5. **Easy Management**: One bucket to configure, backup, and monitor

#### Viewing State Files

List state files for your application:

```bash
# List all workspaces for this application
gsutil ls gs://${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage/${GCP_PROJECT_ID}/${PROJECT}/

# View specific workspace state
just tf-init dev
cd infra/environments
terraform state list
```

### Custom Branch Patterns

To support different issue tracker formats, modify `extract_issue_id()` in `scripts/utils.sh`:

```bash
# Example: Support numeric-only issue IDs (e.g., feature/123-description)
if [[ "$branch_name" =~ ^(feature|bugfix|hotfix)/([0-9]+) ]]; then
    local issue_id="issue-${BASH_REMATCH[2]}"
    echo "${issue_id}"
fi
```

### Environment-Specific Configurations

Use Terraform variables and workspace-based tfvars files for environment-specific settings:

```hcl
# infra/environments/variables.tf
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

# In main.tf, use locals to set environment-specific values
locals {
  instance_count = var.environment_name == "prod" ? 3 : 1
}
```

## Testing (Template Development)

This template includes integration tests that verify Terraform infrastructure provisioning. These tests are used during template development and are automatically removed when scaffolding a new project.

### Running Tests

```bash
# Setup test dependencies (template repo only)
just setup --template

# Run all template tests
just test

# The test recipe delegates to test-template, which runs:
# - Unit tests for utility functions (test/utils.bats)
# - Integration tests for Terraform commands (test/terraform-integration.bats)
```

### Test Types

**Unit Tests** (`test/utils.bats`):

- Test utility functions without GCP
- Fast, run on every PR
- Test issue ID extraction, workspace inference, etc.

**Integration Tests** (`test/terraform-integration.bats`):

- Actually provision infrastructure with Terraform
- Verify `just tf-*` commands work correctly
- Automatic cleanup after tests
- Require GCP credentials and project setup

### Manual Inspection

Skip cleanup to inspect infrastructure:

```bash
SKIP_CLEANUP=1 just test
# Infrastructure left intact for inspection
# Clean up manually: just tf-destroy tf-test-TIMESTAMP --auto-approve
```

Skip integration tests entirely:

```bash
SKIP_TF_TESTS=1 just test
```

### CI/CD

- Tests run via `just test` in all workflows
- After scaffolding, `just test` becomes a placeholder for project-specific tests
- Template tests (`test/` directory) and `test-template` recipe are removed during scaffolding

### For Scaffolded Projects

After scaffolding, implement your own tests by:

1. Creating test files in `test/` directory
2. Updating the `test` recipe in justfile to run your tests
3. Tests will automatically run in CI/CD via existing workflows

## Next Steps

- Review [architecture.md](architecture.md) for technical details
- Explore example modules in `infra/modules/`
- Set up GitHub environment protection rules
- Configure monitoring and alerting for your infrastructure
- Add custom Terraform modules for your application needs

## LLM Assistance with Claude

Claude commands provide guided workflows for complex tasks. The template includes two custom commands, while most workflow commands come from the [Claudevoyant plugin](https://github.com/cloudvoyant/claudevoyant) (automatically installed with `just setup --dev`).

### Template Commands

```bash
claude /adapt                   # Customize template for your language (auto-deletes after use)
claude /upgrade                 # Migrate to newer template version
```

### Plugin Commands (from Claudevoyant)

```bash
claude /spec:new                # Create a new project plan
claude /spec:go                 # Execute the plan with spec-driven development
claude /spec:pause              # Capture insights for resuming work later
claude /spec:refresh            # Update plan status
claude /adr:new                 # Create architectural decision record
claude /adr:capture             # Capture decisions from conversation
claude /dev:docs                    # Validate documentation
claude /dev:commit                  # Create conventional commit
claude /dev:review                  # Perform code review
```

### Upgrading Projects

When a new template version is released:

```bash
claude /upgrade
```

This creates a comprehensive migration plan, compares files, and walks you through changes while preserving your infrastructure customizations.
