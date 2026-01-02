# ADR-007: Hybrid Release Notes (CHANGELOG + RELEASE_NOTES)

Status: Accepted

Date: 2024-10-10

## Context

Need both technical and user-friendly release documentation for different audiences.

## Decision

Auto-generate `CHANGELOG.md` from commits via semantic-release, and use Claude CLI to create human-friendly `RELEASE_NOTES.md`.

## Alternatives Considered

### Only auto-generated changelog
- Pros: Fully automated, consistent
- Cons: Too technical for end users, lacks context and impact explanation

### Only human-written release notes
- Pros: User-friendly, explains impact
- Cons: Manual work, easy to forget details, no complete technical record

### Single file for both audiences
- Pros: One place to look
- Cons: Either too technical or too high-level, can't serve both audiences well

## Rationale

- `CHANGELOG.md` provides complete technical history from commits
- `RELEASE_NOTES.md` explains user impact and improvements
- Serves different audiences (developers vs users/stakeholders)
- Claude makes human-friendly notes easy to create (via Claude Code commands or manual curation)
- Both can coexist in GitHub releases
- Developers can choose which to include based on their needs
- Best of both worlds - automation + human insight
