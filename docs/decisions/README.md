# Architectural Decision Records (ADRs)

This directory contains architectural decision records for the platform. Each ADR documents an important architectural decision with context, alternatives considered, and rationale.

## Index

- [ADR-001: Use Just as Command Runner](001-use-just-as-command-runner.md)
- [ADR-002: Centralize Configuration in .envrc](002-centralize-configuration-in-envrc.md)
- [ADR-003: Bash for Core Scripting](003-bash-for-core-scripting.md)
- [ADR-004: No External Bash Dependencies](004-no-external-bash-dependencies.md)
- [ADR-005: CI/CD with GitHub Actions](005-cicd-with-github-actions.md)
- [ADR-006: Test Development Build, Publish Production Build](006-test-dev-build-publish-prod.md)
- [ADR-007: Hybrid Release Notes (CHANGELOG + RELEASE_NOTES)](007-hybrid-release-notes.md)
- [ADR-008: Platform Testing with Bats](008-platform-testing-with-bats.md)
- [ADR-009: Scaffold Script Removes Platform Files](009-scaffold-removes-platform-files.md)
- [ADR-010: GCP Artifact Registry as Default Publishing Target](010-gcp-artifact-registry-as-default.md)
- [ADR-011: GitHub Template Support via .gitattributes](011-github-template-support.md)
- [ADR-012: Semantic Setup Flags](012-semantic-setup-flags.md)
- [ADR-013: Scripts Over Actions/Plugins](013-scripts-over-actions-plugins.md)

## Creating New ADRs

When making significant architectural decisions:

1. Create a new file: `docs/decisions/NNN-short-title.md`
2. Use the next sequential number (NNN)
3. Follow the ADR template (see `.claude/style.md`)
4. Add an entry to this index
5. Update relevant documentation (architecture.md)
