# ADR-002: Centralize Configuration in .envrc

Status: Accepted

Date: 2024-10-10

## Context

Need consistent environment variable management across scripts, commands, and developer workflows.

## Decision

Use `.envrc` as the single source of truth for all configuration and environment variables.

## Alternatives Considered

### Environment-specific files (.env.dev, .env.prod)

- Pros: Environment separation
- Cons: More complex, most projects don't need this, harder to share common config

### Command-line arguments only

- Pros: Explicit, no file management
- Cons: Verbose, hard to maintain, no defaults, not shareable

## Rationale

- Single file to manage - reduced cognitive load
- Works with direnv for automatic environment loading - allows using unix commands like docker, tf, gcloud, aws, azure, etc. without the need for loading env files or in-line args
- Can be sourced manually by scripts (`source .envrc`)
- Standard Unix convention for environment variables
- Easy to version control and share with team
