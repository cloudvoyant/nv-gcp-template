# ADR-008: Template Testing with Bats

Status: Accepted

Date: 2024-10-10

## Context

Need to test bash scripts and scaffolding functionality to ensure template quality.

## Decision

Use bats-core (Bash Automated Testing System) for all template testing.

## Alternatives Considered

### Manual testing only

- Pros: No test framework needed
- Cons: Error-prone, time-consuming, not repeatable, no CI/CD integration

## Rationale

- Simple syntax similar to other test frameworks (`@test "description" { ... }`)
- Good documentation and active community
- Easy to install via package managers (brew, apt, yum)
- Integrates well with CI/CD pipelines
- Standard tool for bash testing (widely adopted)
- Built-in helpers like `run` for capturing output
- Works well with our template development workflow
