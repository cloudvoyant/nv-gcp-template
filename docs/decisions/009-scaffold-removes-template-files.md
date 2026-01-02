# ADR-009: Scaffold Script Removes Template Files

Status: Accepted

Date: 2024-10-10

## Context

Scaffolded projects shouldn't include template development files like tests and template-specific commands.

## Decision

The `scaffold.sh` script automatically removes `test/`, `scripts/template-install.sh`, template-specific justfile commands, and other development files.

## Alternatives Considered

### Keep all files, document what to delete

- Pros: Users have full visibility
- Cons: Manual cleanup required, error-prone, confusing for users, larger projects

### Use .gitattributes export-ignore only

- Pros: Works for GitHub templates
- Cons: Doesn't help local scaffolding, incomplete solution

## Rationale

- Clean scaffolded projects out of the box - no manual work
- Reduces confusion about what files are needed
- Smaller project footprint
- Users don't need to understand template internals
- Combined with `.gitattributes export-ignore` for GitHub templates
- Automatic cleanup is more reliable than documentation
- Follows principle of least surprise
