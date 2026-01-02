# Claude Code Instructions

## Workflow Commands

This template provides two custom commands:

- `/adapt` - Template-only command for adapting to new languages (auto-deletes after use)
- `/upgrade` - Upgrade to the latest template version

All other workflow commands (`/spec:new/go/bg/stop/pause`, `/dev:commit`, `/dev:review`, `/adr:new`, etc.) are provided by the [Claudevoyant plugin](https://github.com/cloudvoyant/claudevoyant). The plugin is automatically configured during scaffolding and provides a comprehensive set of development workflow commands.

For trivial single-step tasks, proceed directly without asking.

## Spec-Driven Development

This project uses a spec-driven approach: plan first, implement second.

### Workflow Pattern

Use the Claudevoyant plugin commands for structured development workflows. See `/upgrade` command for the canonical example:

1. Create comprehensive plan in `.claude/plan.md` (using `/spec:new` from plugin)
2. Work through plan systematically. Add sub-lists of check-boxes as needed for complex tasks.
3. Mark items complete as you finish
4. When plan is done, update docs and delete plan

### File Purposes

`.claude/plan.md` - Active work only

- Current implementation tasks
- Phases and checkboxes
- Delete when complete

`.claude/tasks.md` - Future work

- Deferred features
- Ideas from abandoned plan items
- Reference for next session

`docs/` - Permanent knowledge

- `architecture.md` - design principles, system architecture (prime directive)
- `user-guide.md` - how to use the project
- `decisions/` - ADRs for significant choices

### When to Create ADRs

For significant architectural changes, use the `/adr:new` command from the Claudevoyant plugin which will:

1. Create `docs/decisions/NNN-short-title.md`
2. Follow the ADR template format
3. Update `docs/decisions/README.md` index
4. Update `docs/architecture.md` if needed

## Git Commits

No Claude Code attributions in commits. Clean, professional messages only.

## Commands

Prefer just commands to simple bash. Projects should be run, tested, etc. via just whenever possible.

## Quick Reference

1. Read plan.md before starting
2. Mark tasks complete immediately
3. Update docs when done
4. Delete plan.md on completion or abandonment
