Help me migrate this project to the latest nv-ziglib-template version using a spec-driven approach.

## Overview

This workflow helps you systematically upgrade your project to the latest template version by:

1. Detecting your current template version
2. Cloning the latest template for comparison
3. Creating a migration plan with all files to review
4. Working through changes methodically
5. Testing and validating the migration

## Steps

### 1. Detect Current Version

Check the template version this project is currently using:

```bash
grep NV_TEMPLATE_VERSION .envrc
```

If `NV_TEMPLATE_VERSION` doesn't exist in `.envrc`, this project was scaffolded before version tracking was added. Assume an older version and proceed with caution.

### 2. Clone Latest Template

Clone the latest template to `.nv/template-upstream-main` for comparison:

```bash
# Create directory if needed
mkdir -p .nv

# Clone template (or pull if already exists)
if [ -d ".nv/template-upstream-main" ]; then
    cd .nv/template-upstream-main && git pull && cd ../..
else
    git clone https://github.com/cloudvoyant/nv-ziglib-template .nv/template-upstream-main
fi
```

### 3. Create Migration Plan

Create `.claude/plan.md` with a structured migration plan. I'll help you create this plan with:

Structure:

```markdown
# Migration Plan: v<current> → v<target>

## Overview

Migrate from nv-ziglib-template v<current> to v<target>

## Files to Review

### Zig-Specific Files

- [ ] build.zig - Check for build configuration changes
- [ ] build.zig.zon - Check for dependency updates
- [ ] src/lib.zig - Check for library structure changes
- [ ] src/main.zig - Check for CLI changes

### Critical Infrastructure Files

- [ ] justfile - Check for recipe changes
- [ ] scripts/setup.sh - Check for new dependencies (Zig, ZLS)
- [ ] scripts/scaffold.sh - Check for improvements
- [ ] scripts/upversion.sh - Check for versioning updates
- [ ] scripts/utils.sh - Check for utility function updates
- [ ] scripts/toggle-files.sh - Check for Zig-specific file visibility
- [ ] .github/workflows/ci.yml - Check for workflow updates
- [ ] .github/workflows/release.yml - Check for release changes
- [ ] .envrc - Check for new variables

### Configuration Files

- [ ] .gitignore - Check for new patterns
- [ ] .gitattributes - Check for line ending rules
- [ ] .editorconfig - Check for editor settings
- [ ] .releaserc.json - Check for semantic-release config

### Claude Code Configuration

- [ ] .claude/instructions.md - Check for instruction updates
- [ ] .claude/workflows.md - Check for workflow improvements
- [ ] .claude/style.md - Check for style guide updates
- [ ] .claude/commands/\*.md - Check for new/updated commands

### IDE Configuration

- [ ] .vscode/settings.json - Check for editor settings
- [ ] .vscode/extensions.json - Check for recommended extensions
- [ ] .devcontainer/\* - Check for devcontainer updates

### Documentation

- [ ] README.template.md - Check for documentation updates
- [ ] docs/architecture.md - Check for architecture changes
- [ ] docs/user-guide.md - Check for user guide updates

## Changes to Apply

For each file with differences, I'll create tasks like:

### Task 1: Review justfile changes

- [ ] Compare: diff justfile .nv/template-upstream-main/justfile
- [ ] Review changes and decide what to apply
- [ ] Apply relevant changes (preserve project customizations)
- [ ] Test: just build && just test

### Task 2: Review Zig build configuration

- [ ] Compare: diff build.zig .nv/template-upstream-main/build.zig
- [ ] Compare: diff build.zig.zon .nv/template-upstream-main/build.zig.zon
- [ ] Review changes and decide what to apply
- [ ] Test: zig build && zig build test

[Repeat for each file category]

### Task N: Update version

- [ ] Update NV_TEMPLATE_VERSION in .envrc to <target>

## Testing

- [ ] Run: just test
- [ ] Verify builds work
- [ ] Check CI passes (if applicable)

## Cleanup

- [ ] Remove: rm -rf .nv/template-upstream-main
- [ ] Archive this migration plan (or delete)
```

### 4. Work Through Plan Systematically

For each task in the migration plan:

#### a. Compare Files

```bash
# Example: Compare justfile
diff justfile .nv/template-upstream-main/justfile

# Or for directories
diff -r scripts/ .nv/template-upstream-main/scripts/
```

#### b. Review Changes

Determine if changes apply to this project:

- **Infrastructure changes** (workflows, scripts): Usually apply
- **Recipe changes** (justfile): May need customization
- **Configuration** (.envrc.template, .gitignore): Review carefully
- **Claude/IDE configs**: Apply improvements, preserve project-specific settings

#### c. Apply Changes

Apply relevant changes while preserving project-specific customizations:

- Copy improved scripts
- Merge workflow updates
- Update recipes as needed
- Preserve project-specific logic

#### d. Mark Complete

Update `.claude/plan.md` to mark task as completed.

#### e. Test Incrementally

After applying each significant change:

```bash
just test
```

### 5. Update Version

After all changes applied:

```bash
# Update .envrc with new version
sed -i.bak 's/^export NV_TEMPLATE_VERSION=.*/export NV_TEMPLATE_VERSION=<new-version>/' .envrc && rm .envrc.bak
direnv allow
```

### 6. Final Validation

Run full test suite and verify:

```bash
# Run tests
just test

# Check that all expected files exist
ls -la scripts/ .github/workflows/

# Verify .envrc has correct version
grep NV_TEMPLATE_VERSION .envrc
```

### 7. Cleanup

```bash
# Remove template clone
rm -rf .nv/template-upstream-main

# Archive or delete migration plan
mv .claude/plan.md .claude/migration-complete-$(date +%Y%m%d).md
# Or: rm .claude/plan.md
```

## Best Practices

- **Create plan first** - Don't apply changes ad-hoc
- **Review all diffs** - Understand what changed and why
- **Preserve customizations** - Don't blindly copy template files
- **Test incrementally** - Verify after each significant change
- **Commit before starting** - Clean working directory for safety
- **Document decisions** - Note in plan.md why you kept/skipped changes

## Common Issues

### Missing NV_TEMPLATE_VERSION

If `.envrc` doesn't have `NV_TEMPLATE_VERSION`, add it:

```bash
echo '' >> .envrc
echo '# Nedavellir template tracking' >> .envrc
echo 'export NV_TEMPLATE=nv-ziglib-template' >> .envrc
echo 'export NV_TEMPLATE_VERSION=<current-version>' >> .envrc
```

### Conflicting Changes

If you've heavily customized files that also changed in the template:

1. Review the template change carefully
2. Manually apply the improvement to your customized version
3. Document the merge in plan.md

### Failed Tests After Migration

If tests fail after applying changes:

1. Review what changed
2. Check if you need to update test configuration
3. Verify all dependencies are installed
4. Consult template's CHANGELOG.md for breaking changes
