# {{PROJECT_NAME}}

> A new project scaffolded from {{TEMPLATE_NAME}} (v{{TEMPLATE_VERSION}})

## Overview

[Add your project description here]

### Project Structure

```
.
├── docs/          # Documentation
├── scripts/       # Utility scripts and CI/CD hooks
└── .../           # [ SPECIFY PROJECT SPECIFIC DIRS ]
└── justfile       # Build recipes
└── .envrc         # Key env vars and shell config
└── version.txt    # Project version
└── ...            # [ SPECIFY PROJECT SPECIFIC FILES ]
```

## Prerequisites

- bash 3.2+
- just
- [List other required tools and dependencies]

## Setup

Run `just setup` or `./scripts/setup.sh` to install remaining dependencies (just, direnv).

Optional: `just setup --dev` for development tools, `just setup --template` for template testing.

## Quick Start

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

Build run and test with `just`.

```bash
❯ just run

❯ just test

```

Just runs the necessary dependencies for a task on it's own!

## Publishing

Commit using conventional commits (`feat:`, `fix:`, `docs:`). Merge/push to main and CI/CD will run automatically bumping your project version and publishing a package.

### Release Process

1. **Make changes** on a feature branch
2. **Commit with conventional commits**:
   - `feat: add new feature` → minor version bump
   - `fix: resolve bug` → patch version bump
   - `feat!: breaking change` or `BREAKING CHANGE:` in footer → major version bump
3. **Push to GitHub** and create a pull request
4. **Merge to main** - the CI/CD pipeline will:
   - Run tests
   - Build artifacts
   - Generate changelog
   - Create GitHub release
   - Publish to registry (if configured)

### Manual Publishing

To publish manually:

```bash
# Ensure you're on main branch with clean working directory
just publish
```

This will publish a pre-release package version.

### Registry Configuration

Publishing to artifact registries is optional. This project defaults to GCP Artifact Registry but can be configured for npm, PyPI, Docker Hub, etc.

Configure in `.envrc`:

- **GCP Artifact Registry** (default): Set `GCP_REGISTRY_PROJECT_ID`, `GCP_REGISTRY_REGION`, `GCP_REGISTRY_NAME`
- **Other registries**: Update the `publish` recipe in `justfile` and add registry-specific variables to `.envrc`

Examples:

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

See the [{{TEMPLATE_NAME}} User Guide](https://github.com/your-org/{{TEMPLATE_NAME}}/blob/main/docs/user-guide.md) for detailed configuration instructions.

## Documentation

To learn more about using this template, read the docs:

- [User Guide](docs/user-guide.md) - Complete setup and usage guide
- [Architecture](docs/architecture.md) - Design and implementation details

## References

- [just command runner](https://github.com/casey/just)
- [direnv environment management](https://direnv.net/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [bats-core bash testing](https://bats-core.readthedocs.io/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
