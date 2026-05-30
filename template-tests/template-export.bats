#!/usr/bin/env bats
# Tests for GitHub template export behavior
#
# Validates that export-ignore attributes in .gitattributes correctly
# exclude platform-specific files when using "Use this template" on GitHub.
#
# GitHub uses `git archive` to create templates, which respects export-ignore.
#
# Install bats: brew install bats-core
# Run: bats test/template-export.bats

setup() {
    export ORIGINAL_DIR="$PWD"

    # Create temporary directory for testing
    export TEST_DIR="$(mktemp -d)"
    export ARCHIVE_FILE="$TEST_DIR/template.tar"
    export EXTRACT_DIR="$TEST_DIR/extracted"

    # Must be in a git repo for git archive to work
    # The test assumes we're running from the platform repo itself
    if [ ! -d ".git" ]; then
        skip "Must run from git repository root"
    fi
}

teardown() {
    # Clean up test directory
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}

@test "git archive command works" {
    run git archive --format=tar --output="$ARCHIVE_FILE" HEAD

    [ "$status" -eq 0 ]
    [ -f "$ARCHIVE_FILE" ]
}

@test "archive includes all required files and directories" {
    git archive --format=tar --output="$ARCHIVE_FILE" HEAD
    mkdir -p "$EXTRACT_DIR"
    tar -xf "$ARCHIVE_FILE" -C "$EXTRACT_DIR"

    # Verify essential platform files are present
    [ -f "$EXTRACT_DIR/README.md" ]
    [ -f "$EXTRACT_DIR/.envrc.template" ]
    [ -f "$EXTRACT_DIR/justfile" ]
    [ -f "$EXTRACT_DIR/scripts/scaffold.sh" ]
    [ -d "$EXTRACT_DIR/.claude" ]

    # Claude commands directory should contain README with plugin installation info
    [ -f "$EXTRACT_DIR/.claude/commands/README.md" ]
    # Individual command files are now provided via the Claudevoyant plugin
    # and should not be in the template

    # User-facing Claude config files should be included
    [ -f "$EXTRACT_DIR/.claude/CLAUDE.md" ]
    [ -f "$EXTRACT_DIR/.claude/style.md" ]
    [ -f "$EXTRACT_DIR/.claude/workflows.md" ]

    # docs/ should exist but not docs/migrations/
    [ -d "$EXTRACT_DIR/docs" ]
    [ ! -d "$EXTRACT_DIR/docs/migrations" ]

    # scripts/ should exist with scaffold.sh but not platform-install.sh
    [ -d "$EXTRACT_DIR/scripts" ]
    [ -f "$EXTRACT_DIR/scripts/scaffold.sh" ]
    [ ! -f "$EXTRACT_DIR/scripts/platform-install.sh" ]
}

@test "validates all platform-specific files are excluded in one archive" {
    git archive --format=tar --output="$ARCHIVE_FILE" HEAD
    mkdir -p "$EXTRACT_DIR"
    tar -xf "$ARCHIVE_FILE" -C "$EXTRACT_DIR"

    # All platform development files should be excluded
    [ ! -d "$EXTRACT_DIR/test" ]
    [ ! -d "$EXTRACT_DIR/docs/migrations" ]
    [ ! -f "$EXTRACT_DIR/CHANGELOG.md" ]
    [ ! -f "$EXTRACT_DIR/RELEASE_NOTES.md" ]
    [ ! -f "$EXTRACT_DIR/scripts/platform-install.sh" ]

    # Platform-specific Claude files should be excluded
    [ ! -f "$EXTRACT_DIR/.claude/plan.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/tasks.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/migrations/generate-migration-guide.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/new-migration.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/validate-platform.md" ]

    # Template-specific commands should be included
    [ -f "$EXTRACT_DIR/.claude/commands/upgrade.md" ]
    [ -f "$EXTRACT_DIR/.claude/commands/adapt.md" ]
    [ -f "$EXTRACT_DIR/.claude/commands/README.md" ]

    # Plugin-provided commands should not be in template
    [ ! -f "$EXTRACT_DIR/.claude/commands/commit.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/plan.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/review.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/docs.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/adr-new.md" ]
    [ ! -f "$EXTRACT_DIR/.claude/commands/adr-capture.md" ]
}
