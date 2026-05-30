## [1.4.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.4.1...v1.4.2) (2026-05-30)

### Bug Fixes

* **docker:** run pnpm web build in builder stage instead of build-prod

## [1.4.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.4.0...v1.4.1) (2026-05-30)

### Bug Fixes

* **docker:** install mise to PATH location via MISE_INSTALL_PATH

## [1.4.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.3.2...v1.4.0) (2026-05-30)

### ⚠ BREAKING CHANGES

* mise run tf-destroy now exits with an error when run on dev,
stage, or prod workspaces. Run terraform destroy manually for persistent environments.

### Features

* migrate from just/direnv to mise for task running and env config

Replace justfile + direnv + scripts/setup.sh with mise as the single tool
for task running, environment configuration, and dev-tool dependency management.

- Add mise.toml with [env] (PROJECT=mise-app-template, VERSION, GCP vars),
  [tools] (node 20, pnpm, terraform, bats, shellcheck, shfmt), and
  [settings] (experimental=true for .mise-tasks/ auto-discovery)
- Add .mise-tasks/ with 46 tasks replacing all justfile recipes
- Rewrite dockerfiles/base.dockerfile and web.dockerfile for mise-based 2-stage build
- Remove .devcontainer/, dev.dockerfile, root Dockerfile
- Update all 4 CI workflows and 2 composite actions to use mise
- Rename test/ → template-tests/; update scaffold task accordingly
- Delete justfile, scripts/setup.sh, scripts/toggle-files.sh,
  scripts/upversion.sh, scripts/scaffold.sh, scripts/utils.sh
- Remove .envrc and .envrc.template (replaced by mise.toml [env])
- Update all nv-gcp-template references to mise-app-template
- Apply prettier formatting to e2e fixtures and CHANGELOG.md

* protect persistent envs, add CI test suite, Firestore by workspace type

- Block tf-destroy on dev/stage/prod to prevent accidental data loss
- Add is_ci local (ci-* workspaces) to skip Firestore and avoid HTTP/2 timeouts
- Real preview workspaces get Firestore with deletion_policy=DELETE so no orphans
- Reorganise tests/: template tests in tests/template/, CI flow tests in tests/ci/
- Add breaking->minor release rule so 0.x projects stay at 0.x through breaking changes
- Fix stale docs: gcloud auth commands, scaffold path, just->mise task references
- Update scaffold to reference tests/ instead of template-tests/

BREAKING CHANGE: mise run tf-destroy now exits with an error when run on dev,
stage, or prod workspaces. Run terraform destroy manually for persistent environments.


### Bug Fixes

* **ci:** add semantic-release plugins to package.json and use pnpm exec

* **ci:** allow protobufjs build scripts in pnpm workspace

* **ci:** correct mise-action repo from jdx-code to jdx

* **ci:** pin pnpm to v10 to match local and avoid v11 build-approval changes

* **test:** resolve mise path portably for CI compatibility

* update template-export tests for mise migration (remove justfile/envrc refs)

## [1.3.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.3.1...v1.3.2) (2026-04-12)

### Bug Fixes

- align extract_issue_id and infer_terraform_workspace with readership

- update extract_issue_id test to expect error on non-feature branches

## [1.3.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.3.0...v1.3.1) (2026-04-12)

### Bug Fixes

- skip preview cleanup for non-feature branch PRs

## [1.3.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.7...v1.3.0) (2026-04-12)

### Features

- add full-stack SvelteKit app with auth, uploads, UI, and E2E

* SvelteKit app (apps/web) with Kinde OAuth 2.0 authentication, image
  upload pipeline (browser resize → signed GCS PUT → Firestore metadata),
  and CDN delivery via Cloud CDN
* libs/auth: Kinde client, JWT verification, session cookie management
* libs/storage: GCS client, signed URL generation, WebP image resizing
* libs/ui: shadcn-svelte component library (Button, Input, FileDropZone)
  with OKLCH theming; Tailwind content scan extended to libs/ui/src
* E2E test suite (Playwright) with global setup/teardown, auth state
  reuse, Firestore cleanup of [E2E]-prefixed records

### Bug Fixes

- add root .prettierignore to exclude generated and credential files

- align with readership structural patterns

* hooks.server.ts: add existsSync check on GOOGLE_APPLICATION_CREDENTIALS,
  add handleError export with errorId
* e2e: extract personas.ts, add P2 persona (unused), update auth fixtures
  to return p2Password (optional until secret is provisioned)
* ci.yml: add 'just publish' pre-release step in preview job
* .prettierignore: add _.tfvars, .nv/, service-account_.json, credentials.json

- apply prettier formatting

- **e2e:** broaden email selector and add debug screenshot on Kinde page

Add autocomplete/id/name fallback selectors to handle Kinde apps that
render email as type=text. Add screenshot after waitForURL to diagnose
selector mismatches in CI.

- export .env.e2e.local vars into environment before running playwright

- fail loudly in fetch-e2e-secrets if E2E_P1_PASSWORD not found

- **infra:** grant Cloud Run SA token creator to enable GCS signed URLs

Without iam.serviceAccountTokenCreator on itself, the Cloud Run SA cannot
sign blobs, so generateSignedUploadUrl() fails with ADC on Cloud Run.

- ignore .svelte-kit and gha-creds files in prettier

- **infra:** inject FIRESTORE_DATABASE_ID into Cloud Run env

The app defaults to (default) Firestore database when FIRESTORE_DATABASE_ID
is not set. Non-prod environments use a named database (project-env)
so this env var must be explicitly passed to the Cloud Run service.

- normalize e2e secret format and safe-load env vars without glob expansion

- remap legacy e2e secret key names to E2E\_ prefix on fetch

- restore .claude/style.md and workflows.md deleted by prettier

- revert fetch-e2e-secrets to simple form matching readership

- skip Terraform integration tests in build-and-test CI job

Terraform apply requires a built Docker image which is only available
in the preview job. Terraform deployment is covered there instead.

- skip Terraform integration tests in release pipeline ([#4](https://github.com/cloudvoyant/nv-gcp-template/issues/4))

- strip quotes from JSON-formatted secret keys and values

- **e2e:** use baseURL in logout test instead of hardcoded localhost

- **e2e:** use robust Kinde form selectors in global-setup

Replace getByLabel(/email/i) with input[name=p_email]/input[type=email]
and add waitForURL(/kinde.com/) to confirm redirect before filling form.
Also handle both single-step and two-step Kinde login flows.

### Tests

- **e2e:** improve upload test to capture error text on failure

## [1.2.7](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.6...v1.2.7) (2026-02-21)

### Bug Fixes

- include project name in non-prod domain pattern

Without the project name, all projects using this template would
compete for the same subdomain (e.g., dev.cloudvoyant.io), causing
domain mapping authorization failures. Matches readership's pattern:
project.env.base_domain.

## [1.2.6](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.5...v1.2.6) (2026-02-20)

### Bug Fixes

- set default base domain to cloudvoyant.io

## [1.2.5](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.4...v1.2.5) (2026-02-20)

### Bug Fixes

- upload release assets via semantic-release instead of gh cli

GitHub marks releases immutable after publishing, preventing
gh release upload from adding assets. Instead, build dist/ before
running semantic-release so @semantic-release/github uploads dist/\*
atomically when creating the release.

## [1.2.4](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.3...v1.2.4) (2026-02-20)

### Bug Fixes

- use dist/\* glob for release asset upload

dist/\*_/_ requires globstar and doesn't match files directly in
dist/ without it. Using dist/\* correctly matches dist/artifact.txt.

## [1.2.3](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.2...v1.2.3) (2026-02-20)

### Bug Fixes

- configure git auth before semantic-release to fix tag push

Sets the git remote URL with GITHUB_TOKEN credentials so that
semantic-release's internal `git push --tags` uses authenticated
HTTPS instead of relying on the credential helper set by checkout.

## [1.2.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.1...v1.2.2) (2026-02-20)

### Bug Fixes

- replace softprops release action with gh release upload

softprops/action-gh-release@v1 fails with "Cannot upload assets to
an immutable release" because @semantic-release/github already
publishes the GitHub release. Use gh release upload instead to
attach dist artifacts to the pre-existing release.

## [1.2.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.0...v1.2.1) (2026-02-20)

### Bug Fixes

- restore build-prod stub for Artifact Registry publish step

## [1.2.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.2...v1.2.0) (2026-02-20)

### Features

- adopt readership improvements into template

* CI/CD: concurrency, deployment tracking, split docker steps,
  release/deploy job split, amd64 platform
* Justfile: SERVICE abstraction, docker-login, get-url,
  force-redeploy, TF devops vars, pnpm recipes
* Docker: dockerfiles/ split (base/web/dev), apt HTTPS workaround,
  .dockerignore, github-cli devcontainer
* Infra: nv-fullstack-app module (Cloud Run + Firestore + IAM),
  enriched environment variables and outputs
* Scripts: check_gcloud_auth, pnpm as required dep, NodeSource
  for Node.js 22 in install_node
* App: minimal SvelteKit workspace (apps/web) with health endpoint

## [1.1.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.1...v1.1.2) (2026-01-11)

### Bug Fixes

- scaffodling correctly removes redundant template specific files. justfile show/hide presevred on scaffolding

## [1.1.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.0...v1.1.1) (2026-01-11)

### Bug Fixes

- dockerfile modifications for service deployment

- dockerfile modifications for service deployment

## [1.1.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.0.3...v1.1.0) (2026-01-11)

### Features

- added setup support for tf installation

### Bug Fixes

- added commit hash to preview docker tags

- calling setup.sh directly to support direnv installation prior to justfile usage

- fixed docker tagged in ci, added prerelease versions to package publishing

- fixed docker tagged in ci, added prerelease versions to package publishing

- fixed docker tagged in ci, added prerelease versions to package publishing

- fixed docker tagged in ci, added prerelease versions to package publishing

- fixed docker tagged in ci, added prerelease versions to package publishing

- fixed test cleanup for integration tests ensuring tf created buckets are deleted during cleanup

- refactoried ci to use custom actions making pipelines more DRY, combined peview and ci pipelines

### Documentation

- updated architecture, design and templates for readability

## [1.0.3](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.0.2...v1.0.3) (2026-01-08)

### Bug Fixes

- adding .envrc config for docker registry for publishing

## [1.0.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.0.1...v1.0.2) (2026-01-08)

### Bug Fixes

- using glcoud to configure docker auth in docker-[ush justfile recipe

## [1.0.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.0.0...v1.0.1) (2026-01-07)

### Bug Fixes

- docker compose push fixed

## 1.0.0 (2026-01-07)

### Features

- tf recipes and actions added, docs and testing wip

### Bug Fixes

- added gcp auth in ci pipeline

- fixed broken tests, dockerfile and scaffodling issues

- fixing issue with SKIP_TF_TESTS

- setting gcp project in ci now

- setting gcp project in ci now

- setting gcp project in ci now

- setting gcp project in ci now
