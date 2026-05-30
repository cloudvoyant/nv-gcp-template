# Architecture

## Design

### Monorepo Structure (Feature-Slice)

The project is organized as a pnpm workspace monorepo with a feature-slice layout:

- `apps/web` — SvelteKit full-stack application deployed to Cloud Run. Handles routing, server-side rendering, API endpoints (`+server.ts`), and page load functions.
- `libs/auth` — Published as `@mise-app-template/auth`. Kinde OAuth 2.0 client and session management. **Server-only** — never import this in browser code. Exposes `initKindeConfig()`, token verification via JWKS, and silent refresh logic consumed by `hooks.server.ts`.
- `libs/storage` — Published as `@mise-app-template/storage`. GCS client, signed URL generation, and browser-side image resizing. Mixed boundary: `client.ts` and `resize.ts` are browser-safe; `operations.ts` is server-only.
- `libs/ui` — Published as `@mise-app-template/ui`. shadcn-svelte component library (Button, Input, FileDropZone, etc.). Browser-only Svelte components. Tailwind must scan `libs/ui/src/**` in `tailwind.config.js` so component class names are included in the build output.

pnpm workspaces tie these packages together. Cross-package imports use the package name (e.g. `@mise-app-template/auth`), not relative paths, to respect boundary enforcement.

### Infrastructure

Two Terraform roots handle different lifecycles:

- `infra/shared/` — Applied **once per project**. Provisions the Cloud CDN configuration and the public GCS bucket that CDN serves from. Changes here are infrequent and affect all environments simultaneously.
- `infra/environments/` — Applied **per workspace**. Provisions Cloud Run service, Firestore database, and the private GCS bucket used for upload staging. Each workspace gets its own isolated set of these resources.

Workspaces map directly to environments:

| Branch Pattern       | Workspace  | Lifecycle                           |
| -------------------- | ---------- | ----------------------------------- |
| `feature/PROJ-NNN-*` | `proj-nnn` | Created on push, destroyed on merge |
| `bugfix/BUG-NNN-*`   | `bug-nnn`  | Created on push, destroyed on merge |
| `main`               | `dev`      | Updated automatically on merge      |
| Tag via dispatch     | `stage`    | Manual deploy with approval gate    |
| Approved stage       | `prod`     | Manual deploy after approval        |

Terraform state is stored in a shared GCS backend in the DevOps project. The path structure is:

```
{GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage/
└── {GCP_PROJECT_ID}/
    └── {PROJECT}/
        ├── env:/dev/default.tfstate
        ├── env:/stage/default.tfstate
        ├── env:/prod/default.tfstate
        └── env:/proj-123/default.tfstate
```

This layout isolates state by GCP project and application name, so a single shared bucket can serve multiple projects without collision.

All GCP resources follow the naming pattern `{project}-{environment}--{resource-name}` (e.g. `myapp-proj-123--bucket`). The double-dash separates environment from resource name. All resources are labelled with `project`, `environment`, and `managed_by = "terraform"` for cross-repository tracking.

### GitHub Actions CI/CD

Three workflow files in `.github/workflows/` cover the full deployment lifecycle:

- **`preview.yml`** — Triggers on feature/bugfix/hotfix branch pushes. Infers workspace from branch name (e.g. `feature/PL-3-foo` → `pl-3`), runs `mise run tf-init`, `mise run tf-plan`, `mise run tf-apply` to provision preview infrastructure. On branch delete or merge, runs `mise run tf-destroy` to clean up.
- **`release.yml`** — Triggers on merge to `main`. Runs semantic-release to produce a version bump and changelog, then builds and deploys to the `dev` workspace. No approval required.
- **`deploy-manual.yml`** — Workflow dispatch triggered by a tagged release. Deploys to `stage` (with GitHub environment approval gate), then to `prod` (with a second approval gate).

Workflows call `mise run` tasks rather than inlining logic. This keeps CI as a thin orchestration layer and means the same commands work identically in local development and CI. GitHub environments (`preview-*`, `dev`, `stage`, `prod`) provide secret isolation and, for `stage` and `prod`, required reviewer approvals.

### Task Runner (mise)

`mise-tasks/` is the single interface for all project operations. Key tasks:

- `mise run test` / `mise run build` — Quality gates; `publish` depends on both
- `mise run tf-init/tf-plan/tf-apply/tf-destroy [WORKSPACE]` — Terraform operations with confirmation guards
- `mise run docker-build` / `mise run docker-push` — Image management (never run `docker` directly)
- `mise run fetch-e2e-secrets` — Pulls test credentials from Secret Manager
- `mise run test-e2e` — Fetches secrets if missing, injects GCP vars, runs Playwright

Task dependencies form a build chain that enforces quality gates automatically. `mise.toml [env]` provides all environment variables so all `mise run` tasks have consistent environment without extra flags.

---

## Implementation

### Kinde Auth Configuration

Kinde is a third-party OAuth 2.0 / OIDC provider. To configure it:

1. Create a **Back-end web** application in the Kinde dashboard.
2. Set the callback URL to `https://{your-domain}/auth/callback` and the logout redirect to `https://{your-domain}`.
3. Add the following to the workspace secret in Secret Manager (see Secret Manager section below):
   - `KINDE_DOMAIN` — your Kinde tenant domain (e.g. `https://yourapp.kinde.com`)
   - `KINDE_CLIENT_ID`
   - `KINDE_CLIENT_SECRET`

`libs/auth/src/kinde-client.ts` exposes `initKindeConfig()`, which is called from `hooks.server.ts` on server startup. Access tokens are verified against the Kinde JWKS endpoint (`https://{KINDE_DOMAIN}/.well-known/jwks`) using `jose`.

On every request, `hooks.server.ts` checks the session cookie. If the access token is expired but a refresh token is present, it silently exchanges the refresh token (`grant_type=refresh_token`) and writes an updated cookie. The user only sees a login prompt when both tokens are invalid or absent.

Sessions are stored as base64-encoded JSON in an httpOnly cookie named `{PROJECT}_session`.

### Secret Manager

All runtime secrets live in GCP Secret Manager in the **DevOps project**. The naming convention is:

```
{PROJECT}-{WORKSPACE}       # e.g. myapp-dev, myapp-prod
{PROJECT}-e2e-secrets       # E2E test credentials (shared across workspaces)
```

Each secret stores env-file format content — one `KEY=VALUE` per line. The app reads these at deploy time via Cloud Run environment injection. E2E secrets contain `E2E_P1_PASSWORD` and `E2E_P1_USER_ID` and are fetched locally by `mise run fetch-e2e-secrets`, which writes to `apps/web/.env.e2e.local`.

Required CI secret: `GCP_SA_KEY` — service account JSON key with the following roles:

- DevOps project: `roles/storage.objectAdmin` (tfstate bucket), `roles/artifactregistry.writer`, `roles/secretmanager.secretAccessor`
- Infrastructure project: `roles/run.admin`, `roles/storage.admin`, `roles/datastore.owner`, and any other roles needed for your resources

Configure secrets at the GitHub organization level so all repositories inherit them automatically.

### Firestore Indexes

Composite indexes are managed **exclusively via Terraform**. Do not use `firestore.indexes.json`.

Indexes are defined as `google_firestore_index` resources in `infra/modules/nv-fullstack-app/main.tf`. Terraform state management prevents index drift between environments and ensures indexes are applied consistently when a new workspace is provisioned.

Example: the uploads collection requires a composite index on `(userId ASC, filename ASC)` for the E2E teardown query that finds and deletes records tagged `[E2E]`.

### Image Upload Pipeline

1. Browser calls `libs/storage/src/resize.ts` to resize the original image into five WebP variants: thumbnail, small, medium, large, xlarge.
2. Browser calls `POST /api/images/upload-urls`, which uses `libs/storage` to generate signed PUT URLs for each variant plus the original — one URL per file.
3. Browser PUTs each file directly to GCS using its signed URL. Traffic bypasses Cloud Run, eliminating egress costs for uploads.
4. Browser calls `POST /api/uploads` to save metadata to Firestore: `basePath`, `cdnBasePath`, `srcset`, `filename`, `userId`, `purpose`.
5. CDN serves images from `cdnBasePath`, which points to the public GCS bucket fronted by Cloud CDN.

### Monorepo Package Boundaries

| Package        | Boundary     | Notes                                                                  |
| -------------- | ------------ | ---------------------------------------------------------------------- |
| `libs/auth`    | Server-only  | Never import in any code that runs in the browser                      |
| `libs/storage` | Mixed        | `client.ts`, `resize.ts` — browser-safe; `operations.ts` — server-only |
| `libs/ui`      | Browser-only | Svelte components; Tailwind must scan `libs/ui/src/**`                 |

Always import by package name (`@mise-app-template/auth`), not by relative path, to make boundary violations obvious in code review.

### E2E Test Architecture

Playwright tests live in `apps/web/e2e/`. The global setup and teardown hooks handle credential and state management so individual tests stay focused on behavior.

**Global setup:**

1. Runs `mise run fetch-e2e-secrets` if `apps/web/.env.e2e.local` is missing.
2. Executes a pre-run cleanup pass to remove leftover `[E2E]`-tagged data from previous runs.
3. Performs a P1 (primary test user) login via the Kinde auth flow and saves browser auth state for reuse across tests.

**Global teardown:**

- Runs `apps/web/scripts/teardown-e2e.ts`, which queries Firestore for all records tagged `[E2E]` and deletes them, keeping the test environment clean.

`mise run test-e2e` orchestrates the full sequence: fetches secrets if missing, injects the workspace-specific `GCP_PROJECT_ID` and region, and invokes Playwright.

### Terraform Workspace Strategy

`infer_terraform_workspace()` in `mise-tasks/utils.sh` extracts the issue ID from a branch name and normalizes it to lowercase for GCP resource naming compliance:

- `feature/PROJ-12345-my-feature` → `proj-12345`
- `bugfix/BUG-1-fix` → `bug-1`

The resulting workspace name is used as both the Terraform workspace and the `environment` label on all GCP resources. This creates a direct, traceable link from branch → workspace → resources.

**Persistent environment protection (breaking change in v1.4):** `mise run tf-destroy` refuses to run on `dev`, `stage`, or `prod` workspaces and exits with an error. These environments must be managed manually to prevent accidental data loss. The check happens before `tf-init`, failing fast without touching any state.

**Firestore provisioning by workspace type:**

| Workspace pattern | `is_ci` | `is_preview` | Firestore DB | `deletion_policy` |
|---|---|---|---|---|
| `ci-*` | true | true | Skipped (count=0) | — |
| feature/bugfix (`proj-123`) | false | true | Created | `DELETE` — fully removed on `tf-destroy` |
| `dev` / `stage` / `prod` | false | false | Created | `ABANDON` — terraform removes from state but leaves DB intact |

CI workspaces (`ci-*`) skip Firestore entirely to avoid HTTP/2 connection timeouts that occur during the multi-minute GCP Firestore create/delete operations. Real preview workspaces get a dedicated Firestore database with `deletion_policy = "DELETE"` so no orphaned databases are left in GCP after `tf-destroy`.

### Component: mise-tasks/

- `mise-tasks/utils.sh` — Shared logging (`log_info`, `log_success`, `log_error`, `log_warn`), `confirm` for destructive operations, `infer_terraform_workspace`, and cross-platform `sed_inplace`. Sourced by all other tasks (`#MISE hide=true`).
- `mise-tasks/scaffold` — Initializes a new project from the template. Handles PascalCase/camelCase/kebab-case replacements, removes template-only files, and restores from backup on failure.
- `mise-tasks/upversion` — Wraps semantic-release. Dry-run mode locally, CI mode in GitHub Actions.

All tasks use `set -euo pipefail`. Source `mise-tasks/utils.sh` at the top of any new task.

### Component: Dockerfile (Multi-Stage)

- **`base` stage** (`dockerfiles/base.dockerfile`) — Installs mise and all dev tools from `mise.toml [tools]` (node, pnpm, terraform, etc.). Runs `mise run install` to install pnpm dependencies. Used as the foundation for the web app build.
- **`runtime` stage** (`dockerfiles/web.dockerfile`) — Copies only the SvelteKit build output from the builder stage into a minimal `node:20-alpine` runtime image. No mise, no dev tools.

Docker layer caching is maximized by separating `mise install` (tool install) from `mise run install` (pnpm install) from `mise run build-prod` (app build).

### Cross-Platform Support

The template targets macOS, Linux, and Windows (via WSL or Docker Desktop):

- `.editorconfig` enforces LF line endings to prevent git diff noise on Windows.
- `sed_inplace` in `mise-tasks/utils.sh` abstracts the BSD/GNU `sed -i` difference.
- Bash 3.2+ is required — macOS ships with Bash 3.2, so Bash 4+ features are avoided.
- mise handles tool installation across platforms via its own plugin system.

### Security

- Secrets belong in GitHub Secrets and GCP Secret Manager — never in `mise.toml` or committed files.
- `.gitignore` includes patterns for keys, certificates, credentials, and `.env` files.
- `confirm` utility in `mise-tasks/utils.sh` gates all destructive operations (destroy, publish, scaffold).
- `set -euo pipefail` in all task scripts ensures errors fail fast rather than propagating silently.

---

## References

- [mise task runner and tool manager](https://mise.jdx.dev/)
- [Kinde authentication](https://kinde.com/docs/)
- [semantic-release](https://semantic-release.gitbook.io/)
- [bats-core bash testing](https://bats-core.readthedocs.io/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GCP Secret Manager](https://cloud.google.com/secret-manager/docs)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
