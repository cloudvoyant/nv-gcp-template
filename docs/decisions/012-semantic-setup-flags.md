# ADR-012: Semantic Setup Flags

Status: Accepted

Date: 2025-10-12

## Context

The platform needs to support multiple installation contexts:
- Regular project development (needs core tools only)
- Full development workflow (needs linters, formatters, docker)
- CI/CD environments (needs minimal tools for automated builds)
- Platform development (needs testing frameworks)

We needed to decide how to structure setup script flags to give users control over what gets installed.

## Decision

Use semantic flags that describe the installation context:

- `--dev` - Install development tools (docker, node/npx, gcloud, shellcheck, shfmt, claude)
- `--ci` - Install CI essentials (node/npx, gcloud)
- `--template` - Install template development tools (bats-core)

Flags can be combined: `setup.sh --dev --platform`

Required dependencies (always installed):
- bash (shell)
- just (command runner)
- direnv (environment management)

## Alternatives Considered

### Single --all or --include-optional flag

```bash
setup.sh --include-optional  # Install everything
setup.sh                      # Install minimal
```

Pros:
- Simple binary choice
- Easy to understand

Cons:
- Forces users to install things they don't need
- CI environments would install unnecessary dev tools (shellcheck, shfmt)
- No way to install just CI tools without dev tools
- No clear intent about what "optional" means

### Individual tool flags

```bash
setup.sh --docker --node --shellcheck --shfmt --bats
```

Pros:
- Maximum granularity
- Users install only what they want

Cons:
- Verbose and tedious
- Requires users to know all tool names
- Hard to remember which tools are needed together
- Poor discoverability
- Doesn't express intent (why am I installing these?)

### Environment variable detection

```bash
# Detect context and auto-install
if [ -n "$CI" ]; then
    # Auto-install CI tools
elif [ -f "test/" ]; then
    # Auto-install platform tools
fi
```

Pros:
- Zero configuration
- Automatic context detection

Cons:
- Magic behavior is hard to debug
- Users lose control
- May install wrong things in edge cases
- Implicit rather than explicit

## Rationale

### Semantic flags express intent

- `--dev` says "I'm doing development work"
- `--ci` says "I'm in a CI environment"
- `--platform` says "I'm developing the platform itself"

This is clearer than listing individual tools.

### Context-appropriate installations

Each flag installs exactly what's needed for that context:

Development (`--dev`):
- docker - For containerized testing
- node/npx - For semantic-release and local versioning
- gcloud - For testing registry publishing
- shellcheck - For linting shell scripts
- shfmt - For formatting shell scripts
- claude - For AI-assisted development

CI (`--ci`):
- node/npx - For semantic-release in release pipelines
- gcloud - For publishing to GCP Artifact Registry
- NO docker (not needed for most test runs)
- NO linters/formatters (not needed in CI)

Template (`--template`):
- bats-core - For running template tests
- Used by template maintainers only

### Combinable for flexibility

Users can combine flags for their specific needs:
- `setup.sh` - Just core tools for using a scaffolded project
- `setup.sh --dev` - Full development environment
- `setup.sh --dev --template` - Template development
- `setup.sh --ci` - CI/release automation (node/npx, gcloud only)

### Clear separation of concerns

- Required - Always installed, no flag needed
- Development - Optional, for active development
- CI - Optional, for automated release pipelines only
- Template - Optional, for template maintenance

## Consequences

### Positive

- Clear and discoverable flag names
- Users install only what they need
- CI environments stay lean
- Easy to extend with new contexts (e.g., `--docker-only`)
- Self-documenting through flag names

### Negative

- Multiple flags to learn (but only 3)
- Need to document what each flag includes
- Can't install individual tools without editing script

### Future Extensions

Potential new flags:
- `--minimal` - Explicitly skip all optional tools
- `--docker-only` - Just docker, nothing else

## Related

- ADR-003: Bash for Core Scripting (setup.sh is a bash script)
- ADR-005: CI/CD with GitHub Actions (uses `setup.sh --ci`)