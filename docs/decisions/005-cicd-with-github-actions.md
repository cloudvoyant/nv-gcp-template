# ADR-005: CI/CD with GitHub Actions

Status: Accepted

Date: 2024-10-10

## Context

Need a CI/CD system that automates testing, releases, and publishing while supporting trunk-based development and language-agnostic workflows.

## Decision

Use GitHub Actions for all CI/CD automation with a two-workflow approach:

1. `ci.yml` - Tests and builds on pull requests
2. `release.yml` - Creates releases and publishes on merge to main

Follow trunk-based development: test on PR, release on merge to main.

## Alternatives Considered

### GitLab CI

- Pros: Integrated with GitLab, good features
- Cons: Requires GitLab, not ideal for GitHub-hosted projects

## Rationale

Why GitHub Actions:

- Native GitHub integration - no external services
- Free for public repos, generous free tier for private
- YAML configuration in repository (`.github/workflows/`)
- Access to GitHub context (commits, PRs, releases)
- Good marketplace of reusable actions
- Familiar to GitHub users

Why two workflows (ci.yml + release.yml):

- Clear separation of concerns - testing vs releasing
- `ci.yml` runs on PRs to catch issues early
- `release.yml` only runs on main branch after merge
- Easier to understand and maintain than one large workflow
- Can be extended independently

Why trunk-based development:

- Simpler git workflow - no release branches needed
- Continuous delivery - every merge can be a release
- Works seamlessly with semantic-release and conventional commits
- Reduces merge conflicts and integration issues
- Encourages small, frequent changes

Key workflow patterns:

- Test on feature branches and PRs (ci.yml)
- Automatic versioning via semantic-release on merge (release.yml)
- Conditional publishing - only if new version created
- Uses default GITHUB_TOKEN (no PAT required)
- Combined release + publish in one workflow (atomic operation)

Language agnostic design:

- Workflows call `just` commands (build, test, publish)
- Language-specific logic stays in justfile
- Easy to customize for any language/framework
- CI/CD doesn't need language-specific knowledge
