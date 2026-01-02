# User Guide

`nv-lib-template` is a language-agnostic template for building projects with automated versioning, testing, and GitHub Action powered CI/CD workflows. It uses GCP Artifact Registry for publishing generic packages by default, but can be easily adapted for npm, PyPI, NuGet, CodeArtifact, etc.

## Features

Here's what this template gives you off the bat:

- A language-agnostic self-documenting command interface via `just`. Keep all your project commands organized in one file!
- Auto-load environment variables and configure shell environment with `direnv` - share project scoped shell configurations and simplify scripting and CLI tool usage without needing to pass around flags and inline environment variables.
- CI/CD with GitHub Actions - run test on MR commits, tag and release on merges to main.
- Easy CI/CD customization with language-agnostic bash scripting - No need to get too deep into GitHub Actions for customization. Modify the publish recipe, set GitHub Secrets and you're good to go.
- Trunk based development and automated versioning with conventional commits - semantic-release will handle version bumping for you! Work on feature branches and merge to main for bumps.
- GCP Artifact Registry publishing (easily modified for other registries)
- Cross-platform (macOS, Linux, Windows via WSL) - use the setup script to install dependencies, or alternately develop with Dev Containers or run tasks via Docker

## Requirements

- bash 3.2+
- [just](https://just.systems/man/en/)

Run `just setup` to install remaining dependencies (just, direnv).

Optional: `just setup --dev` for development tools, `just setup --template` for template testing.

## Getting Started

## Quick Start

Scaffold a new project:

```bash
# Option 1: Nedavellir CLI (automated)
nv create your-project-name --template nv-lib-template

# Option 2: GitHub template + scaffold script
# Click "Use this template" on GitHub, then:
git clone <your-new-repo>
cd <your-new-repo>
bash scripts/scaffold.sh --project your-project-name
```

Install dependencies and adapt the template for your needs:

```bash
just setup              # Required: bash, just, direnv
just scaffold           # Scaffold project - apply project name and reset version
claude /adapt           # Guided customization for your language / package manager
```

Type `just` to see all the tasks at your disposal:

```bash
❯ just
Available recipes:
    [dev]
    load                 # Load environment
    install              # Install dependencies
    build                # Build the project
    run                  # Run project locally
    test                 # Run tests
    clean                # Clean build artifacts

[ OUTPUT TRUNCATED ]
```

Build run and test with `just`. The template will show TODO messages in console prior to adapting.

```bash
❯ just run
TODO: Implement build for nv-lib-template@1.9.1
TODO: Implement run

❯ just test
TODO: Implement build for nv-lib-template@1.9.1
TODO: Implement test
```

Note how just runs the necessary dependencies for a task on it's own!

Commit using conventional commits (`feat:`, `fix:`, `docs:`). Merge/push to main and CI/CD will run automatically bumping your project version and publishing a package.

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

## The Basics

### Daily Commands

```bash
just install    # Install project dependencies
just build      # Build for development
just test       # Run tests
just run        # Run locally
just clean      # Clean build artifacts
```

### Commit and Release

Use conventional commits for automatic versioning:

```bash
git commit -m "feat: add new feature"      # Minor bump (0.1.0 → 0.2.0)
git commit -m "fix: resolve bug"           # Patch bump (0.1.0 → 0.1.1)
git commit -m "docs: update readme"        # No bump
git commit -m "feat!: breaking change"     # Major bump (0.1.0 → 1.0.0)
```

Push to main:

```bash
git push origin main
```

CI/CD automatically runs tests, creates a release, and publishes to your configured registry.

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

## Customizing The Template For Your Needs

### For Your Language

The `justfile` contains TODO placeholders. Run Claude's `/adapt` command for guided customization:

```bash
claude /adapt
```

Or manually replace placeholders with your language's commands:

```just
# Node.js example
install:
    npm install

build:
    npm run build

test: build
    npm test

publish: test build-prod
    npm publish
```

### For Your Registry

The `publish` recipe defaults to GCP Artifact Registry. Edit it for your registry:

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

Configure your `.envrc` accordingly:

```bash
# GCP (default)
export GCP_REGISTRY_PROJECT_ID="my-project"
export GCP_REGISTRY_REGION="us-east1"
export GCP_REGISTRY_NAME="my-registry"

# Or use registry-specific variables for npm, PyPI, etc.
```

### CI/CD Secrets

Configure secrets once at the organization level (Settings → Secrets → Actions):

For GCP (default):

- `GCP_SA_KEY` - Service account JSON key
- `GCP_REGISTRY_PROJECT_ID`, `GCP_REGISTRY_REGION`, `GCP_REGISTRY_NAME`

For other registries:

- npm: `NPM_TOKEN`
- PyPI: `PYPI_TOKEN`
- Docker Hub: `DOCKER_USERNAME`, `DOCKER_PASSWORD`

All projects automatically inherit organization secrets.

## Overriding CI/CD

### Customizing Behavior

Scripts in `scripts/` provide hooks for overriding CI/CD behavior:

- `scripts/upversion.sh` - Modify versioning logic here
- `scripts/setup.sh` - Add custom dependencies here

Edit these scripts to change how CI/CD runs, but avoid editing `.github/workflows/` directly.

### Example: Custom Versioning

To change how versions are calculated, edit `scripts/upversion.sh` or modify `.releaserc.json` to add semantic-release plugins.

### Example: Additional Setup Steps

To add custom dependencies during CI setup, extend `scripts/setup.sh` with your logic.

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

This creates a comprehensive migration plan, compares files, and walks you through changes while preserving your customizations.

## Troubleshooting

### direnv not loading .envrc

Add to your shell config (~/.bashrc, ~/.zshrc):

```bash
eval "$(direnv hook bash)"  # or zsh, fish
```

Reload and allow:

```bash
source ~/.bashrc
direnv allow
```

### just command not found

Install just:

```bash
brew install just           # macOS
# Or run: bash scripts/setup.sh
```

### Tests pass locally but fail in CI

Check that:

- Runtime versions match CI (Node.js, Python, Go versions)
- Lock files are committed (package-lock.json, requirements.txt)
- All dependencies are declared

### Publish fails with authentication error

Verify GitHub organization secrets are configured:

1. Organization → Settings → Secrets → Actions
2. Check secrets exist (GCP_SA_KEY, NPM_TOKEN, etc.)
3. Ensure repository access is enabled

For GCP, verify service account has `roles/artifactregistry.writer` permission.

### semantic-release fails

Ensure:

- Default branch is named `main` (or update `.releaserc.json`)
- At least one commit uses conventional format
- GITHUB_TOKEN secret is accessible

## Next Steps

1. Customize `justfile` for your language
2. Write code in `src/`
3. Add tests
4. Configure GitHub organization secrets
5. Set up branch protection on `main`
6. Make your first conventional commit
7. Push and watch the automated release

Or just run `claude /adapt`.

See [Architecture](architecture.md) for implementation details.
