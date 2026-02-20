## [1.2.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.1...v1.2.2) (2026-02-20)

### Bug Fixes

* replace softprops release action with gh release upload

softprops/action-gh-release@v1 fails with "Cannot upload assets to
an immutable release" because @semantic-release/github already
publishes the GitHub release. Use gh release upload instead to
attach dist artifacts to the pre-existing release.

## [1.2.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.2.0...v1.2.1) (2026-02-20)

### Bug Fixes

* restore build-prod stub for Artifact Registry publish step

## [1.2.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.2...v1.2.0) (2026-02-20)

### Features

* adopt readership improvements into template

- CI/CD: concurrency, deployment tracking, split docker steps,
  release/deploy job split, amd64 platform
- Justfile: SERVICE abstraction, docker-login, get-url,
  force-redeploy, TF devops vars, pnpm recipes
- Docker: dockerfiles/ split (base/web/dev), apt HTTPS workaround,
  .dockerignore, github-cli devcontainer
- Infra: nv-fullstack-app module (Cloud Run + Firestore + IAM),
  enriched environment variables and outputs
- Scripts: check_gcloud_auth, pnpm as required dep, NodeSource
  for Node.js 22 in install_node
- App: minimal SvelteKit workspace (apps/web) with health endpoint

## [1.1.2](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.1...v1.1.2) (2026-01-11)

### Bug Fixes

* scaffodling correctly removes redundant template specific files. justfile show/hide presevred on scaffolding

## [1.1.1](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.1.0...v1.1.1) (2026-01-11)

### Bug Fixes

* dockerfile modifications for service deployment

* dockerfile modifications for service deployment

## [1.1.0](https://github.com/cloudvoyant/nv-gcp-template/compare/v1.0.3...v1.1.0) (2026-01-11)

### Features

* added setup support for tf installation


### Bug Fixes

* added commit hash to preview docker tags

* calling setup.sh directly to support direnv installation prior to justfile usage

* fixed docker tagged in ci, added prerelease versions to package publishing

* fixed docker tagged in ci, added prerelease versions to package publishing

* fixed docker tagged in ci, added prerelease versions to package publishing

* fixed docker tagged in ci, added prerelease versions to package publishing

* fixed docker tagged in ci, added prerelease versions to package publishing

* fixed test cleanup for integration tests ensuring tf created buckets are deleted during cleanup

* refactoried ci to use custom actions making pipelines more DRY, combined peview and ci pipelines


### Documentation

* updated architecture, design and templates for readability

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
