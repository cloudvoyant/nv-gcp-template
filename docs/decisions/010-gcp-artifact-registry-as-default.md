# ADR-010: GCP Artifact Registry as Default Publishing Target

Status: Accepted

Date: 2024-10-10

## Context

Need a default publishing implementation that works for any language and artifact type.

## Decision

Default `publish` recipe uses GCP Artifact Registry's generic repository type.

## Alternatives Considered

### No default implementation
- Pros: No assumptions, maximum flexibility
- Cons: Users must implement from scratch, no example to follow, harder to get started

### npm registry
- Pros: Familiar to JavaScript developers
- Cons: Too JavaScript-specific, doesn't work for other languages, not truly language-agnostic

### GitHub Packages
- Pros: Integrated with GitHub
- Cons: Requires PAT for auth, more complex setup, usage limits on free tier

## Rationale

- Generic repositories accept any file type (binaries, tarballs, etc.)
- Works for all languages - truly language-agnostic
- Simple authentication via service account JSON key
- Easy to override for language-specific registries (npm, PyPI, etc.)
- Good for monorepo/multi-language scenarios
- Provides working example users can customize
- GCP is a major cloud provider with good documentation
