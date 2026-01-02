# ADR-012: No External Bash Dependencies

Status: Accepted

Date: 2024-10-10

## Context

Want scripts to work on minimal systems without requiring additional tools.

## Decision

Use only bash builtins and standard Unix utilities (sed, grep, awk, etc.) available on all Unix-like systems.

## Alternatives Considered

### Allow dependencies like jq, yq
- Pros: Better JSON/YAML parsing
- Cons: Additional installation step, not always available, adds complexity

### Use Python for complex tasks
- Pros: More powerful, better for data processing
- Cons: Requires Python installation, breaks "bash for scripts" principle

### Require specific tools per script
- Pros: Use best tool for each job
- Cons: Inconsistent dependencies, harder setup, portability issues

## Rationale

- Works on all Unix-like systems out of the box
- Reduces setup complexity for users
- Faster script execution (no process spawning for external tools)
- More portable across different environments
- Forces scripts to stay simple and focused
- Standard utilities are well-documented and stable
- Aligns with "minimal tooling requirements" design principle
