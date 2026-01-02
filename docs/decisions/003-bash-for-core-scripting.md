# ADR-003: Bash for Core Scripting

Status: Accepted

Date: 2024-10-10

## Context

Need a scripting language for platform automation and utility scripts.

## Decision

Use bash for all core platform scripts.

## Alternatives Considered

### Python

- Pros: More powerful, better for complex logic, good standard library
- Cons: Requires interpreter installation, overkill for simple wrapper scripts, not always available by default

### Shell (sh/POSIX shell)

- Pros: Most portable, available everywhere
- Cons: Too limited, missing bash features like arrays, harder to write maintainable code

## Rationale

- Available on all Unix-like systems by default
- No additional runtime needed (unlike Python or Node)
- Good balance of simplicity and capability for wrapper scripts
- Excellent for system automation and file operations
- Cross-platform with WSL on Windows
- Sufficient for scripts under 100 lines (per Google style guide)
- Can be replaced by dedicated CLI tool (`nv` CLI) to remove all scripting downstream
