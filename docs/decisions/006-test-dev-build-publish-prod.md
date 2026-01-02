# ADR-013: Test Development Build, Publish Production Build

Status: Accepted

Date: 2024-10-10

## Context

Need to balance test coverage with production readiness and CI/CD efficiency.

## Decision

Always test the development build (`just build`), create production build (`just build-prod`) only for publishing.

## Alternatives Considered

### Test both dev and prod builds
- Pros: More thorough testing
- Cons: Doubles CI time, production builds usually just add optimizations (minification, etc.)

### Only build production artifacts
- Pros: Single build path
- Cons: Slower development cycle, harder debugging, no fast iteration

### Test production build before publishing
- Pros: Verifies production artifacts
- Cons: Significantly longer CI time, most issues caught in dev build

## Rationale

- Tests run faster on dev builds (no optimizations/minification)
- Production builds often just add optimizations, not new functionality
- Reduces overall CI/CD time
- Matches typical development workflow (test locally with dev build)
- Production builds are deployment artifacts, not test targets
- Issues are caught early in dev build testing
- If dev build tests pass, prod build will work (same source code)
