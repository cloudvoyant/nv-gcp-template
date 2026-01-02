# ADR-001: Use Just as Command Runner

Status: Accepted

Date: 2024-10-10

## Context

Need a simple, cross-platform command runner for the platform that makes it easy to discover and execute common tasks.

## Decision

Use `just` as the primary command interface for all platform and user commands.

## Alternatives Considered

### Bash scripts only

- Pros: No additional dependencies
- Cons: No dependency management between tasks, harder to discover available commands, no built-in help

### Taskfile.dev

- Pros: Smart cancellation between tasks, larger community
- Cons: Poor support for command args, yaml and special syntax heavy

## Rationale

- Simple, intuitive syntax similar to Make but cleaner, easier than Taskfile for those unfamiliar
- Cross-platform (Windows, macOS, Linux)
- Built-in help (`just`) makes commands discoverable / self-documenting
- Recipe dependencies enable task composition
- Language-agnostic - works for any project type
- Easy to install via package managers or cargo
- Good support for command args
