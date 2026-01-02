# ADR-011: GitHub Template Support via .gitattributes

Status: Accepted

Date: 2024-10-10

## Context

Users may want to create new projects via GitHub's "Use this template" feature in addition to local scaffolding.

## Decision

Use `.gitattributes` with `export-ignore` to exclude platform development files from GitHub templates.

## Alternatives Considered

### Only scaffold.sh for creating new projects
- Pros: One way to do things
- Cons: Misses GitHub's built-in template feature, requires cloning and running script

### Separate template repository
- Pros: Clean separation
- Cons: Duplication, two repos to maintain, can get out of sync

### Manual file deletion instructions
- Pros: No special setup
- Cons: Error-prone, poor user experience, inconsistent results

## Rationale

- Works seamlessly with GitHub's "Use this template" feature
- No additional setup required by users
- Consistent with `scaffold.sh` behavior - same files excluded
- Zero-config for users creating repos via GitHub UI
- Complements local scaffolding (two ways to start a project)
- GitHub automatically respects `export-ignore` in `git archive`
- Tested via bats to ensure consistency
