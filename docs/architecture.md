# Architecture

## Overview

`nv-gcp-template` is a GCP infrastructure-as-code template using Terraform for resource management. It provides automated preview environments for feature branches, and a structured promotion workflow (dev → stage → prod) with approval gates.

The template implements branch-based infrastructure provisioning where feature/bugfix/hotfix branches automatically create isolated Terraform workspaces for testing changes, while permanent environments follow a controlled deployment pipeline.

## Terraform Infrastructure Workflow

### Branch-to-Environment Mapping

The template uses branch names to determine Terraform workspaces and environments:

| Branch Pattern            | Environment | Workspace  | Action                                  |
| ------------------------- | ----------- | ---------- | --------------------------------------- |
| `feature/XXXX-NNN-*`      | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `bugfix/XXXX-NNN-*`       | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `hotfix/XXXX-NNN-*`       | preview     | `xxxx-nnn` | Create/update on push, destroy on merge |
| `main`                    | dev         | `dev`      | Update on merge                         |
| Tag via workflow_dispatch | stage       | `stage`    | Manual deploy + approval gate           |
| Approved stage            | prod        | `prod`     | Manual deploy after approval            |

### Issue ID Extraction

Preview environments extract issue IDs from branch names for workspace naming:

- Pattern: `feature/PROJ-12345-description` → workspace: `proj-12345`
- Pattern: `bugfix/BUG-1-fix` → workspace: `bug-1`
- Supports any tracker format: `[LETTERS]-[DIGITS]`
- Automatically normalized to lowercase for GCP resource naming compliance

### Workspace Strategy

Terraform workspaces provide state isolation using a shared GCS backend:

- **Backend Bucket**: `${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage` (shared across ALL projects)
- **Backend Location**: DevOps project (centralized state management)
- **State Prefix**: `${GCP_PROJECT_ID}/${PROJECT}` (GCP project + application name)
- **Workspaces**: `dev`, `stage`, `prod`, plus dynamic preview workspaces (e.g., `proj-123`, `bug-1`)
- **Bucket Features**: Versioning enabled for state history and rollback

### Multi-Project Backend Architecture

This template uses a **shared backend bucket** strategy to support multiple GCP projects and applications:

#### State Organization

All applications store their Terraform state in a single shared GCS bucket, organized by GCP project ID and application name:

```
${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage/  # Shared bucket (e.g., devops-466002-terraform-backend-storage)
├── my-gcp-project/
│   ├── app1/
│   │   ├── env:/dev/default.tfstate       # app1 dev workspace
│   │   ├── env:/stage/default.tfstate     # app1 stage workspace
│   │   ├── env:/prod/default.tfstate      # app1 prod workspace
│   │   └── env:/proj-123/default.tfstate  # app1 preview workspace
│   └── app2/
│       ├── env:/dev/default.tfstate       # app2 dev workspace
│       └── env:/prod/default.tfstate      # app2 prod workspace
└── another-gcp-project/
    └── app3/
        └── env:/dev/default.tfstate       # app3 dev workspace
```

#### Configuration

- **Bucket**: `${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage` (deterministic, globally unique)
- **Prefix**: `${GCP_PROJECT_ID}/${PROJECT}` (GCP project + application name)
- **Workspace**: `dev`, `stage`, `prod`, or `${issue-id}` (environment-specific)

#### Benefits

- **Multi-GCP-Project Support**: Supports multiple GCP projects in one bucket
- **Clear Hierarchy**: GCP Project → Application → Environment structure
- **Project Isolation**: Each GCP project + app combination is completely isolated
- **Environment Isolation**: Workspaces provide environment-level isolation
- **Centralized Management**: One bucket to manage, monitor, and backup
- **Cost Efficient**: Single bucket for all projects reduces management overhead

### Resource Naming and Labeling

All GCP resources follow a consistent naming convention:

**Naming Pattern**: `${project}-${environment}--${resource-name}`

Examples:
- Preview: `myapp-proj-123--bucket`
- Dev: `myapp-dev--bucket`
- Stage: `myapp-stage--bucket`
- Prod: `myapp-prod--bucket`

The double-dash (`--`) separator distinguishes environment from resource name.

**Standard Labels** (applied to all resources):
```hcl
labels = {
  project     = var.project      # Repository/application name
  environment = var.environment  # Environment identifier
  managed_by  = "terraform"      # Infrastructure management tool
}
```

These labels enable resource tracking across multiple repositories deploying to the same GCP project.

### Deployment Flow

```
┌─────────────┐    ┌──────────┐    ┌───────┐    ┌──────┐
│ Feature     │ -> │ Preview  │ -> │  Dev  │ -> │Stage │ -> │ Prod │
│ Branch      │    │ (auto)   │    │(auto) │    │(manual)   │(manual)
└─────────────┘    └──────────┘    └───────┘    └──────┘    └──────┘
     |                   |              |            |            |
     v                   v              v            v            v
  Push to             Workspace      Merge to    Tag +        Approve +
  feature/*           created        main        Deploy       Deploy
                      Infra
                      provisioned
```

### GitHub Environments

GitHub environments provide approval gates and secret isolation:

- **preview-*** (dynamic): No approvals, short-lived, auto-created per branch
- **dev**: No approvals, auto-deploy on merge to main
- **stage**: Requires manual approval before deploy
- **prod**: Requires manual approval before deploy

## How It Works

The template follows this infrastructure workflow:

```
┌────────┐    ┌──────┐    ┌───────────┐    ┌─────────┐    ┌────────────────┐
│ direnv │ -> │ just │ -> │ Terraform │ -> │ scripts │ -> │ GitHub Actions │
└────────┘    └───┬──┘    └───────────┘    └─────────┘    └────────────────┘
                  │
                  v
            ┌───────────┐
            │  Claude   │
            │ (optional)│
            └───────────┘
```

When you run a command like `just tf-apply`, here's what happens:

1. direnv automatically loads `.envrc` to populate your environment with GCP_PROJECT_ID, GCP_REGION, and DevOps project configuration
2. just executes the Terraform command (`just tf-plan`, `just tf-apply`, `just tf-destroy`) using recipes defined in the `justfile`
3. The justfile recipes call utility functions in `scripts/utils.sh` for workspace inference and selection
4. Terraform provisions or updates GCP infrastructure based on the current workspace (dev, stage, prod, or preview)
5. GitHub Actions workflows trigger on branch pushes and merges, automatically managing infrastructure lifecycle
6. Claude commands provide optional LLM assistance for complex workflows like template upgrades and documenting architectural decisions

## Design / Basic Usage

### Getting Started

For detailed setup instructions, see the [User Guide](user-guide.md#quick-start).

After scaffolding a project from this template, configure your `.envrc` with GCP project details. Then interact with your infrastructure via `just` commands:

```bash
just tf-create-backend  # Create GCS backend bucket (one-time)
just tf-init            # Initialize Terraform backend
just tf-plan            # Preview infrastructure changes
just tf-apply           # Apply infrastructure changes
just tf-destroy         # Destroy infrastructure
```

Preview environments are created automatically when you push to feature/bugfix/hotfix branches.

### Customization Points

The infrastructure is defined in Terraform modules under `infra/`:

**Add new resources**: Create new modules in `infra/modules/` and instantiate them in `infra/environments/main.tf`:

```hcl
module "new_resource" {
  source = "../modules/my-resource"

  project          = var.project
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  environment_name = var.environment_name
}
```

**Customize workflows**: The `deploy` recipe in `justfile` is a placeholder for post-infrastructure deployment steps:

```just
deploy WORKSPACE="":
    # Add application deployment commands here
    kubectl apply -f k8s/ --context=${WORKSPACE_NAME}
    # or: gcloud run deploy ...
```

The key principle: infrastructure in Terraform modules, deployment hooks in just recipes, automation in GitHub Actions. This separation keeps your infrastructure declarative and version-controlled while allowing flexible deployment patterns.

## Project Structure

### Template (This Repo)

For template maintainers. Includes testing infrastructure:

```
nv-gcp-template/
├── .envrc                   # Environment variables
├── justfile                 # Commands + TEMPLATE section
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker services configuration
├── scripts/                 # Bash framework
│   ├── setup.sh
│   ├── scaffold.sh
│   ├── upversion.sh
│   └── utils.sh             # Terraform utilities
├── infra/                   # Terraform infrastructure
│   ├── modules/             # Reusable Terraform modules
│   │   └── storage-bucket/  # Example module
│   └── environments/        # Root Terraform configuration
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── versions.tf
├── test/                    # bats tests (for template)
├── docs/                    # architecture.md, user-guide.md
├── .claude/                 # AI workflows + all commands
├── .github/workflows/       # preview.yml, release.yml, deploy-manual.yml
└── .devcontainer/           # VS Code container
```

### Scaffolded Projects

For end users. Template development files removed:

```
myproject/
├── .envrc                   # Your infrastructure config
├── justfile                 # Clean commands (no TEMPLATE section)
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker services configuration
├── scripts/                 # Bash framework
├── infra/                   # Your Terraform infrastructure
│   ├── modules/             # Your custom modules
│   └── environments/        # Root configuration
├── docs/                    # Your docs
├── .claude/                 # User-facing commands only
├── .github/workflows/       # Infrastructure workflows
└── .devcontainer/           # VS Code container
```

Key difference: The main README.md documents template architecture and is kept in the template repository. During scaffolding, `README.template.md` is renamed to `README.md` in the new project and customized with project-specific information. Template development files (`test/`, `.claude/commands/upgrade.md`, etc.) are removed.

## Implementation Details

This section is for template maintainers and advanced users who need to understand how components work internally.

### Component: justfile

The `justfile` serves as the command runner interface, providing a consistent command experience across all projects regardless of language. It uses bash as the shell interpreter and defines color variables (INFO, SUCCESS, WARN, ERROR) for pretty output. The `_load` recipe sources `.envrc` to load environment variables, and all other recipes depend on it to ensure consistent configuration.

Recipe dependencies create a build chain (`test` depends on `build`, `publish` depends on both `test` and `build-prod`) that enforces quality gates automatically. This prevents common mistakes like publishing untested code, improving developer confidence and reducing production incidents.

### Component: scripts/

The `scripts/` directory contains language-agnostic bash automation, isolating platform-specific complexity from your project code. This design allows the template to support any language while maintaining consistent workflows.

- `setup.sh` - Installs dependencies using semantic flags (`--dev`, `--ci`, `--template`) that clearly communicate intent and avoid installing unnecessary tools in CI environments
- `scaffold.sh` - Initializes new projects from the template, handling case variant replacements (PascalCase, camelCase, etc.), template cleanup, and backup/restore on failure to ensure safe initialization
- `upversion.sh` - Wraps semantic-release with a consistent interface (local dry-run mode vs CI mode), enabling developers to preview version bumps before pushing
- `utils.sh` - Provides shared functions for logging, version reading, and cross-platform compatibility, reducing code duplication and maintenance burden

All scripts use `set -euo pipefail` for fail-fast behavior, catching errors immediately rather than continuing with invalid state.

### Component: .envrc

The `.envrc` file holds environment configuration that direnv loads automatically, eliminating the need to manually export variables or pass flags to commands. This improves DX by making environment consistent across terminal sessions and reducing context-switching friction.

Keep it simple with just `export` statements - no bash logic. This constraint prevents complex logic from hiding in configuration, making projects easier to debug. Secrets belong in GitHub Secrets, not `.envrc`, following security best practices. Each project commits its own `.envrc` file for reproducibility. The `.envrc.template` file provides a starting point for scaffolded projects with placeholders that `scaffold.sh` replaces.

### Component: GitHub Actions

Two workflows handle CI/CD with minimal configuration: `ci.yml` runs `just build` and `just test` on pull requests, while `release.yml` runs semantic-release on main branch and then `just publish` if a new version was created.

The workflows call your just commands rather than duplicating logic, creating a single source of truth. This design means you can test CI behavior locally (`just test` runs the same way everywhere), debug faster, and upgrade workflows without touching project-specific logic. Customization happens in familiar territory (bash scripts and just recipes) rather than GitHub Actions YAML.

### Component: Claude Commands

Claude commands provide LLM-assisted workflows for complex tasks.

This template provides two custom commands:

- `/adapt` - Template-only command for adapting to new languages (auto-deletes after use)
- `/upgrade` - Upgrade to the latest template version

All other workflow commands (`/spec:new/go/pause`, `/dev:commit`, `/dev:review`, `/adr:new`, etc.) are provided by the [Claudevoyant plugin](https://github.com/cloudvoyant/claudevoyant). The plugin is automatically configured during scaffolding and provides a comprehensive set of development workflow commands.

### Component: Dockerfile (Multi-Stage)

The `Dockerfile` uses a multi-stage build to support both minimal runtime environments and full development environments from a single file:

**Base Stage** (`target: base`):

- Used by docker-compose for `just docker-run` and `just docker-test`
- Installs only essential dependencies: bash, just, direnv
- Fast build time (~1-2 minutes)
- Minimal image size for quick iteration

**Dev Stage** (`target: dev`):

- Used by VS Code DevContainers
- Builds on top of base stage
- Adds development tools: docker, node/npx, gcloud, shellcheck, shfmt, claude
- Adds template testing tools: bats-core
- Slower build (~10 minutes), but cached after first build

Configuration:

- `docker-compose.yml` services specify `target: base` for fast builds
- `.devcontainer/devcontainer.json` specifies `target: dev` for full environment
- Both share the same base layers, maximizing Docker layer cache efficiency

### Component: docker-compose.yml

Provides containerized services for running and testing without installing dependencies locally:

- `runner` service: Executes `just run` in isolated container
- `tester` service: Executes `just test` in isolated container
- Both use `target: base` for minimal, fast builds
- Mount project directory to `/workspace` for live code updates

### Component: .devcontainer/

The `.devcontainer/` directory provides VS Code Dev Containers configuration for consistent development environments across teams. The devcontainer uses the root-level `Dockerfile` with `target: dev` to build a full development environment.

Features:

- `git:1` - Git installed from source (credentials auto-shared by VS Code via SSH agent forwarding)
- `docker-outside-of-docker:1` - Docker CLI that connects to host's Docker daemon

Credential Mounting:

- Claude CLI credentials mounted from `~/.claude` directory
- Uses cross-platform path resolution: `${localEnv:HOME}${localEnv:USERPROFILE}` expands to HOME on Unix or USERPROFILE on Windows
- Git/GitHub credentials automatically forwarded via SSH agent (requires `ssh-add` on host)
- gcloud requires manual `gcloud auth login` inside container (credentials persist via Docker volumes)

VS Code Extensions:

- `mkhl.direnv` - direnv support
- `skellock.just` and `nefrob.vscode-just-syntax` - justfile syntax highlighting
- `timonwong.shellcheck` and `foxundermoon.shell-format` - Shell script linting and formatting
- `ms-azuretools.vscode-docker` - Docker support

Cross-Platform Considerations:

- Works on macOS, Linux, and Windows (via Docker Desktop or WSL)
- Credential paths use environment variable fallback pattern for platform compatibility
- On Windows, if `~/.claude` doesn't exist at `%USERPROFILE%\.claude`, mount will fail gracefully (container starts without Claude credentials)

### Setup Flags

The `setup.sh` script uses semantic flags to indicate what level of tooling to install (also documented in [User Guide](user-guide.md#getting-started)):

```bash
just setup              # Required: bash, just, direnv
just setup --dev        # + docker, node/npx, gcloud, shellcheck, shfmt, claude
just setup --ci         # + node/npx, gcloud (for release automation)
just setup --template   # + bats-core (template testing)
```

This approach makes dependencies explicit and context-aware. Developers get linting and formatting tools (`--dev`), CI environments install only what's needed for builds (`--ci`), and template maintainers get testing frameworks (`--template`). This reduces CI build times, prevents tool version conflicts, and makes onboarding clearer ("run `just setup --dev` to get started").

### Publishing

The template defaults to GCP Artifact Registry but is easily customized for other registries. Just edit the `publish` recipe:

```just
# npm
publish: test build-prod
    npm publish

# PyPI
publish: test build-prod
    twine upload dist/*

# Docker
publish: test build-prod
    docker push myimage:{{VERSION}}
```

### CI/CD Secrets

Configure secrets once at the organization level (Settings → Secrets → Actions). All repositories inherit organization secrets automatically.

Required GCP secrets:

- `GCP_SA_KEY` - Service account JSON key with permissions for:
  - Creating/managing resources in the infrastructure project
  - Reading/writing to the tfstate bucket in the DevOps project
  - Pushing Docker images to Container Registry (if using)
  - Uploading artifacts to Artifact Registry (if using)

The service account should have these roles:

**In DevOps Project**:
- `roles/storage.objectAdmin` (for tfstate bucket)
- `roles/artifactregistry.writer` (for artifact publishing)

**In Infrastructure Project**:
- `roles/compute.admin` or resource-specific roles
- `roles/storage.admin` (for GCS buckets)
- Other roles based on resources you provision

See [user-guide.md](user-guide.md#gcp-authentication) for detailed service account setup instructions.

### Cross-Platform Support

The template works on macOS, Linux, and Windows (via WSL) without requiring users to install platform-specific tools. This broad compatibility reduces team onboarding friction and prevents "works on my machine" issues.

Key compatibility measures:

- Line endings enforced to LF via `.editorconfig` (prevents git diff noise on Windows)
- `sed_inplace` helper handles differences between macOS and GNU sed (abstracts platform quirks)
- Bash 3.2+ required (macOS ships with Bash 3.2, avoiding Bash 4+ features ensures compatibility without upgrades)
- Package manager detection for Homebrew (macOS), apt/yum/pacman (Linux), with fallback to curl (installs tools automatically based on available package managers)

### Security

Secrets belong in GitHub Secrets, never in `.envrc` or committed code, following the principle of separating configuration from credentials. The `.gitignore` includes comprehensive patterns for keys, certificates, credentials, and .env files to prevent accidental commits.

All scripts use `set -euo pipefail` for fail-fast behavior, ensuring errors don't silently propagate. Error traps handle cleanup on failure, preventing partial state. Lock files prevent concurrent script execution, avoiding race conditions during critical operations like scaffolding or version bumping.

### Testing

For user projects, customize `just test` for your language (pytest for Python, npm test for Node.js, go test for Go, cargo test for Rust).

For template development, use bats-core for bash script testing:

```bash
just setup --template  # Install bats
just test-template     # Run template tests
```

Tests cover scaffold.sh validation, .envrc handling, case variant replacements, and template file cleanup.

## References

- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [bats-core bash testing](https://bats-core.readthedocs.io/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
