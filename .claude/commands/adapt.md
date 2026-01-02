Help me adapt this template to my project's specific needs using a spec-driven approach.

## Overview

This workflow helps you customize this template for your specific use case by:

1. Understanding your requirements
2. Creating a comprehensive adaptation plan
3. Working through changes systematically
4. Testing and validating adaptations

## Steps

### 1. Understand Requirements

I'll ask you about:

- Project language and framework
- Build and test requirements
- Publishing targets (GCP, npm, Docker, etc.)
- CI/CD needs beyond SDK publishing? If so this template may not be fit for your needs.
- Additional tooling requirements

### 2. Create Adaptation Plan

I'll create `.claude/plan.md` with phases for:

```markdown
# Adaptation Plan: nv-lib-template → <your-project>

## Phase 1: Language Setup

- [ ] Update justfile build recipe for <language>
- [ ] Update justfile test recipe for <language>
- [ ] Add language-specific dependencies to setup.sh
- [ ] Update .gitignore for <language>

## Phase 2: Version Management

- [ ] Update .releaserc.json to use language-specific version file (package.json, pyproject.toml, Cargo.toml, etc.)
- [ ] Update semantic-release prepareCmd to write to your version file
- [ ] Update get_version() in scripts/utils.sh to read from your version file
- [ ] Remove version.txt if no longer needed

## Phase 3: Publishing

- [ ] Update publish recipe for <target>
- [ ] Configure registry authentication
- [ ] Notify users of any changes needed for GitHub action secrets

## Phase 4: Tooling

- [ ] Add <tool> configuration
- [ ] Update justfile recipes for <tool>
- [ ] Add <tool> to CI override scripts

## Phase 4: Documentation

- [ ] Update README.md with project specifics
- [ ] Update user-guide.md with custom workflows
- [ ] Document custom recipes in justfile
```

### 3. Work Through Plan

For each adaptation:

1. Review current implementation
2. Make necessary changes
3. Test changes work
4. Mark task complete
5. Move to next task

### 4. Validate Adaptations

```bash
# Test all changes work
just test

# Verify build works
just build

# Check CI would pass
just lint && just format-check && just test
```

### 5. Update Documentation

Update project docs to reflect customizations:

- `docs/architecture.md` - document custom design decisions
- `docs/user-guide.md` - explain custom workflows
- `README.md` - update with project specifics

### 6. Cleanup

```bash
# Archive or delete adaptation plan
mv .claude/plan.md .claude/adaptation-complete-$(date +%Y%m%d).md
```

## Best Practices

- Create plan before making changes
- Test after each significant adaptation
- Keep language-agnostic logic in `scripts/`
- Put language-specific logic in `justfile`
- Document why you made specific choices
- Update README.md to reflect customizations

## What to Keep vs Change

### Always Keep (core framework)

- `scripts/` - bash automation framework
- `.envrc` - environment variable management
- `.github/workflows/` - CI/CD structure
- `direnv` + `just` pattern

### Customize (language-specific)

- `justfile` recipes (build, test, run, publish)
- `.gitignore` patterns
- `docs/` content for your project
- `.envrc` for needed configuration
- Publishing targets and authentication

### Optional Additions

- Language-specific linters/formatters
- Additional CI checks
- Custom deployment scripts
- Development tooling

## Version Management for Different Languages

The template uses `version.txt` as a placeholder. **You should replace this with your language's standard version file.**

### Node.js (package.json)

1. Update `.releaserc.json`:

```json
{
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm", // Automatically handles package.json
    "@semantic-release/git",
    "@semantic-release/github"
  ]
}
```

2. Update `scripts/utils.sh` get_version():

```bash
get_version() {
    if [ -f "${PROJECT_ROOT}/package.json" ]; then
        node -p "require('./package.json').version" 2>/dev/null || echo "0.1.0"
    else
        echo "0.1.0"
    fi
}
```

3. Remove `version.txt`

### Python (pyproject.toml)

1. Update `.releaserc.json` prepareCmd:

```json
{
  "prepareCmd": "sed -i 's/^version = .*/version = \"${nextRelease.version}\"/' pyproject.toml"
}
```

2. Update `scripts/utils.sh` get_version():

```bash
get_version() {
    if [ -f "${PROJECT_ROOT}/pyproject.toml" ]; then
        grep '^version =' pyproject.toml | cut -d'"' -f2
    else
        echo "0.1.0"
    fi
}
```

3. Update git assets:

```json
{
  "assets": ["CHANGELOG.md", "pyproject.toml"]
}
```

### Go (VERSION file or go.mod)

**1. Update `.releaserc.json` prepareCmd:**

```json
{
  "prepareCmd": "echo ${nextRelease.version} > VERSION"
}
```

**2. Update `scripts/utils.sh` get_version():**

```bash
get_version() {
    if [ -f "${PROJECT_ROOT}/VERSION" ]; then
        cat "${PROJECT_ROOT}/VERSION" | tr -d '[:space:]'
    else
        echo "0.1.0"
    fi
}
```

### Rust (Cargo.toml)

**1. Update `.releaserc.json` prepareCmd:**

```json
{
  "prepareCmd": "sed -i 's/^version = .*/version = \"${nextRelease.version}\"/' Cargo.toml"
}
```

**2. Update `scripts/utils.sh` get_version():**

```bash
get_version() {
    if [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
        grep '^version =' Cargo.toml | cut -d'"' -f2
    else
        echo "0.1.0"
    fi
}
```

**3. Update git assets:**

```json
{
  "assets": ["CHANGELOG.md", "Cargo.toml", "Cargo.lock"]
}
```

### Docker (Dockerfile or VERSION)

Use `VERSION` file approach (same as Go above).

### Keep version.txt only if:

- You're building a truly language-agnostic tool
- You don't have a standard version file for your ecosystem
- You want a simple, universal approach

## Cleanup

Now that adaptation is complete, this command will delete itself since it's only needed during template adaptation.

Action: Delete `.claude/commands/adapt.md`

This is a template-only command and should not be kept in adapted repositories.
