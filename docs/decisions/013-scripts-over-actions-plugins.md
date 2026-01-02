# ADR-013: Scripts Over Actions/Plugins

Status: Accepted

Date: 2025-10-12

## Context

GitHub Actions provides a marketplace with thousands of pre-built actions for common tasks like:
- Setting up language runtimes (actions/setup-node, actions/setup-python)
- Authenticating with registries (docker/login-action, google-github-actions/auth)
- Running tests and builds (various language-specific actions)
- Creating releases (semantic-release-action, release-drafter)

We needed to decide: should we use marketplace actions or custom scripts?

## Decision

Use custom scripts over marketplace actions for all core functionality:

- Setup: `bash scripts/setup.sh --ci`
- Testing: `just test`
- Building: `just build`
- Versioning: `just upversion --ci`
- Authentication: `just registry-login --ci`
- Publishing: `just publish`

Only use official GitHub actions for GitHub-specific operations:
- ✅ `actions/checkout@v4` - Repository checkout
- ✅ `actions/upload-artifact@v4` - Artifact storage
- ✅ `softprops/action-gh-release@v1` - GitHub release creation

Avoid third-party marketplace actions for:
- ❌ Language runtime setup (actions/setup-node, actions/setup-python)
- ❌ Registry authentication (docker/login-action, google-github-actions/auth)
- ❌ Test runners (language-specific test actions)
- ❌ Build tools (language-specific build actions)
- ❌ Publishing (npm-publish-action, pypi-publish-action)
- ❌ Versioning (semantic-release-action)

## Alternatives Considered

### Use marketplace actions for everything

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '18'

- uses: docker/login-action@v3
  with:
    registry: gcr.io
    username: _json_key
    password: ${{ secrets.GCP_SA_KEY }}

- uses: cycjimmy/semantic-release-action@v4
  with:
    extra_plugins: |
      @semantic-release/changelog
      @semantic-release/git
```

Pros:
- Less code to maintain
- Pre-tested implementations
- Common patterns
- Auto-updates through Dependabot

Cons:
- Not language-agnostic - Need different actions for Node.js, Python, Go, etc.
- Not testable locally - Can't test GitHub Actions locally
- Third-party dependency risk - Actions can be abandoned, break, or change APIs
- CI-only - Logic only works in GitHub Actions, not locally
- Version lock-in - Must track action versions across projects
- Black box - Hard to debug when things go wrong
- Less portable - Can't easily migrate to GitLab CI, CircleCI, etc.

### Mix of actions and scripts

Use actions for some things, scripts for others.

Pros:
- Pragmatic approach
- Use actions where they excel

Cons:
- Inconsistent patterns
- Harder to understand which approach to use when
- Split brain between two systems
- Some logic still not testable locally

### Pure bash scripts, no actions at all

Don't even use `actions/checkout`.

Pros:
- Ultimate portability
- Complete control

Cons:
- Reinventing wheels for GitHub-specific operations
- actions/checkout handles submodules, LFS, etc. reliably
- Not worth the maintenance burden

## Rationale

### Language-agnostic platform

The platform must work for any language - Node.js, Python, Go, Rust, Java, etc.

Marketplace actions are language-specific:
- `actions/setup-node` - Only for Node.js
- `actions/setup-python` - Only for Python
- `aws-actions/amazon-ecr-login` - Only for AWS ECR

Custom scripts work for all languages:
```bash
# Works for any language
just build    # Calls your language's build command
just test     # Calls your language's test command
just publish  # Calls your language's publish command
```

### Local testability

Scripts are testable locally:
```bash
# Test the entire pipeline locally
just test
just build
just upversion      # Dry-run by default (only creates tags in CI)
```

Actions only work in CI:
- Can't test GitHub Actions locally without simulators
- Slows down feedback loop
- Harder to debug issues

### Portability

Scripts work on any CI platform:
- GitHub Actions ✅
- GitLab CI ✅
- CircleCI ✅
- Jenkins ✅
- Local machine ✅

Actions only work on GitHub:
- Locked into GitHub Actions
- Can't migrate to other CI platforms without rewriting

### Reliability and maintenance

Custom scripts:
- We control the implementation
- Can fix bugs immediately
- No external dependencies to break
- Version controlled with the platform

Marketplace actions:
- Third-party code we don't control
- Authors can abandon projects (see left-pad incident)
- Breaking changes in action updates
- Must track versions across all projects using platform

### Consistency

One way to do things:
```bash
# Same commands everywhere
just test    # Works locally and in CI
just build   # Works locally and in CI
just publish # Works locally and in CI
```

vs. Multiple ways:
```bash
# Locally
npm test

# In CI
- uses: npm/test-action@v2
```

### Debuggability

Scripts are transparent:
- Read the bash script to see exactly what happens
- Add debug logging
- Test with `set -x` to see every command

Actions are black boxes:
- Implementation hidden in action repository
- Must read action source code elsewhere
- Harder to debug failures

## Consequences

### Positive

- Language-agnostic - Works for any programming language
- Locally testable - Full pipeline runs on developer machines
- Portable - Can migrate to any CI platform
- Reliable - No third-party dependencies to break
- Debuggable - All logic is in visible bash scripts
- Consistent - Same commands locally and in CI
- Educational - Developers learn the actual tools, not wrappers

### Negative

- More code to maintain - We own the implementation
- No auto-updates - Must manually update tool installations
- Requires bash knowledge - Team must understand bash scripting
- Longer initial setup - Must write setup scripts

### Edge Cases

We still use official GitHub actions when they provide significant value:

1. actions/checkout@v4 - Handles complex checkout scenarios (submodules, LFS, shallow clones)
2. actions/upload-artifact@v4 - GitHub-specific artifact storage
3. softprops/action-gh-release@v1 - GitHub release API integration

These are GitHub-specific operations that would be complex to reimplement in bash.

### Guidelines

Use marketplace action when:
- It's an official GitHub action (`actions/*`)
- It's for GitHub-specific operations (releases, artifacts)
- Reimplementing would be significantly complex

Use custom script when:
- It's core functionality (setup, test, build, publish)
- It needs to work locally
- It needs to be language-agnostic
- You want full control and debuggability

## Real-World Examples

### Good: Custom setup script

```yaml
- name: Setup environment
  run: bash scripts/setup.sh --ci
```

This works for any language. The script installs just, direnv, and any project-specific tools.

### Bad: Language-specific action

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
```

This locks us into Node.js. A Python project would need `actions/setup-python` instead.

### Good: just commands for all operations

```yaml
- name: Run tests
  run: |
    source .envrc
    just test

- name: Build project
  run: |
    source .envrc
    just build
```

Same pattern regardless of language.

## Related

- ADR-001: Use just as Command Runner (just provides the abstraction layer)
- ADR-003: Bash for Core Scripting (scripts are written in bash)
- ADR-005: CI/CD with GitHub Actions (where this decision is applied)
