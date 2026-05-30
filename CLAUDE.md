# mise-app-template Style Guide

<!-- This file is automatically loaded by Claude Code -->
<!-- Context tags enable smart, contextual rule loading -->
<!-- Format: <!-- @context: tag1, tag2 --> before each section -->

## How to Use This Guide

This style guide uses context tags for efficient loading. Rules are only loaded when relevant to your current task.

- Add rules: `/styleguide:add "rule" --context build,code`
- Learn from patterns: `/styleguide:learn`
- Validate work: `/styleguide:validate`

---

<!-- @context: build, tools, shell -->

## Build System

**CRITICAL:** This project uses mise for all build and operational commands.

**Before running any bash/make/gcloud/docker command directly:**

1. Check available tasks: `mise tasks`
2. Use the mise task if one exists
3. Only run commands directly if no task exists

**Key tasks:**

- `mise run test` - Run bats test suite
- `mise run build` - Build project
- `mise run docker-build` - Build Docker image
- `mise run docker-push` - Push to GCP Container Registry
- `mise install` - Install all dev tools and dependencies
- `mise run gcp-login` - Authenticate with GCP
- `mise run tf-init/tf-plan/tf-apply/tf-destroy` - Terraform operations
- `mise run publish` - Publish artifact to GCP Artifact Registry
- `mise run upgrade` - Upgrade to latest template version

**Why:** mise ensures consistent, environment-aware commands across team and CI/CD.

---

<!-- @context: shell, code, bash -->

## Shell Script Style

**Safety:**

- All scripts must start with `set -euo pipefail`
- Source `./.mise-tasks/utils.sh` for shared utilities (`log_info`, `log_success`, `log_error`, `log_warn`)
- Use `confirm` utility before destructive operations

**Variables:**

- Quote all variable expansions: `"${VAR}"` not `$VAR`
- Use uppercase for env vars and constants
- Use lowercase for local variables

**Environment:**

- Read environment from `mise.toml [env]` — never hardcode project IDs or regions
- Use `eval "$(mise env --shell bash)"` when accessing env vars in scripts outside of mise context

---

<!-- @context: git, commit, vcs -->

## Git Commit Messages

**Format:** Conventional Commits

```
type: subject

body (optional)
```

**Types observed in this project:**

- `feat:` - New feature
- `fix:` - Bug fix
- `chore:` - Maintenance (deps, config, release)
- `docs:` - Documentation only
- `refactor:` - Code restructuring

**CRITICAL:** Never commit directly — always use `/dev:commit`. For subsequent fixes due to CI failures, also use `/dev:commit` for each fix commit.

**Rules:**

- Subject line max 72 characters
- Use imperative mood ("add feature" not "added feature")
- No period at end of subject
- `[skip ci]` suffix on automated release commits only
- No Claude Code attributions — clean, professional messages only

---

<!-- @context: docker, build, ci -->

## Docker

**Image naming convention:**

```
{region}-docker.pkg.dev/{devops_project}/{registry}/{project}:{version}
```

**Workflow:**

- Always use `mise run docker-build` and `mise run docker-push` (not direct docker commands)
- Tags: use VERSION from `mise.toml [env]` for releases, branch-name + commit hash for previews
- GCP auth for registry: `mise run gcp-login` before pushing

---

<!-- @context: terraform, infra, gcp -->

## Terraform / Infrastructure

**State backend:** GCS bucket `{GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage`

**Workflow (always via mise):**

1. `mise run tf-init [WORKSPACE]` - Init backend, auto-selects workspace from branch name
2. `mise run tf-plan [WORKSPACE]` - Plan changes
3. `mise run tf-apply [WORKSPACE]` - Apply (prompts for confirmation unless `--auto-approve`)
4. `mise run tf-destroy [WORKSPACE]` - Destroy (always confirms unless `--auto-approve`)

**Workspace naming:** Auto-inferred from branch name via `infer_terraform_workspace()` in `.mise-tasks/utils.sh`

**Module location:** `infra/modules/` — add reusable modules here
**Environment config:** `infra/environments/` — workspace-specific configuration

**Safety:** Never run `terraform destroy` or `terraform apply` directly; always use mise tasks which include confirmation guards.

---

<!-- @context: test, code, shell -->

## Testing

**Framework:** [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System)

**Running tests:**

- `mise run test` - Run full suite
- `bats template-tests/` - Run directly (if bats installed)
- Parallel execution used automatically if GNU parallel is available

**Test organization:**

- Test files in `template-tests/` directory with `.bats` extension
- Source `.mise-tasks/utils.sh` in `setup()` for utility access
- Use descriptive test names: `@test "function: describes expected behavior"`
- Test both happy path and edge cases (empty input, invalid format, etc.)

---

<!-- @context: gcp, infra, ci -->

## GCP Configuration

**Projects:**

- `GCP_PROJECT_ID` - Target infrastructure project
- `GCP_DEVOPS_PROJECT_ID` - DevOps project (tfstate, registries, artifacts)

**Authentication:**

- Local: `mise run gcp-login` (interactive browser auth)
- CI: `mise run gcp-login --ci` (service account via `$GCP_SA_KEY` env var)

**Artifact Registry:** Generic packages published via `mise run publish`
**Container Registry:** Docker images pushed via `mise run docker-push`

---

<!-- @context: docs, documentation -->

## Documentation

**Structure:**

- `docs/architecture.md` - Design principles and system architecture (prime directive)
- `docs/user-guide.md` - How to use the project
- `docs/decisions/` - ADRs for significant choices

**ADRs:** Use `/adr:new` command for architectural decisions — creates numbered `docs/decisions/NNN-title.md`

**Code comments:**

- Document "why" not "what" (code shows what)
- Prefer self-documenting code over explanatory comments

---

<!-- @context: code, tools -->

## File Operations (Claude Code)

**Tool preferences:**

- **Read** files before editing (required)
- **Edit** for modifications, **Write** only for new files
- **Grep** for content search, **Glob** for file patterns
- Reserve **Bash** for commands with no dedicated tool

---

## Context Tags Reference

| Tag                  | When loaded                      |
| -------------------- | -------------------------------- |
| `build`, `tools`     | Running build/install commands   |
| `shell`, `bash`      | Writing or editing shell scripts |
| `git`, `commit`      | Creating commits or PRs          |
| `docker`             | Docker build/push operations     |
| `terraform`, `infra` | Infrastructure changes           |
| `test`               | Writing or running tests         |
| `gcp`                | GCP-specific operations          |
| `docs`               | Documentation updates            |

---
