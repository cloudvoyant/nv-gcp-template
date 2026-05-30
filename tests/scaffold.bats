#!/usr/bin/env bats
# Tests for .mise-tasks/scaffold (was: scripts/scaffold.sh)
#
# Install bats: mise run install
# Run: SKIP_TF_TESTS=1 mise run test

setup() {
    export ORIGINAL_DIR="$PWD"

    # Create temporary project directory with test name for easier debugging
    # BATS encodes special chars as -XX (hex), decode them using perl
    TEST_NAME_DECODED=$(printf '%s' "$BATS_TEST_NAME" | perl -pe 's/-([0-9a-f]{2})/chr(hex($1))/gie')
    TEST_NAME_SANITIZED=$(printf '%s' "$TEST_NAME_DECODED" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g')
    export PROJECT_DIR="$ORIGINAL_DIR/.nv/$TEST_NAME_SANITIZED"
    mkdir -p "$PROJECT_DIR"

    # Clone template repo to project/.nv/$PROJECT (simulating nv CLI behavior)
    export TEMPLATE_CLONE="$PROJECT_DIR/.nv/mise-app-template"
    mkdir -p "$TEMPLATE_CLONE"

    # Copy all files except .git, node_modules and build artifacts to template clone
    rsync -a \
        --exclude='.git' \
        --exclude='.nv' \
        --exclude='node_modules' \
        --exclude='.svelte-kit' \
        --exclude='.terraform' \
        "$ORIGINAL_DIR/" "$TEMPLATE_CLONE/"

    # Set up test variables
    export DEST_DIR="$PROJECT_DIR"
    export SRC_DIR="$TEMPLATE_CLONE"

    # Read VERSION and PROJECT from mise env (while still in trusted ORIGINAL_DIR)
    export PROJECT VERSION
    PROJECT=$(~/.local/bin/mise env 2>/dev/null | grep '^export PROJECT=' | sed 's/export PROJECT=//' | tr -d '"' || echo "mise-app-template")
    VERSION=$(~/.local/bin/mise env 2>/dev/null | grep '^export VERSION=' | sed 's/export VERSION=//' | tr -d '"' || cat "$ORIGINAL_DIR/version.txt")

    # Change to the template clone directory (where scaffold will be called from)
    cd "$TEMPLATE_CLONE"
}

teardown() {
    # Clean up test directories
    cd "$ORIGINAL_DIR"
    rm -rf "$PROJECT_DIR"
}

@test "scaffold defaults to project root when --src and --dest not provided" {
    # When run without args, should use current directory as default
    # We'll run with --non-interactive to avoid prompts
    run bash .mise-tasks/scaffold --non-interactive

    # Should succeed (defaults to current dir for both src and dest)
    [ "$status" -eq 0 ]
    [[ "$output" == *"Scaffolding complete"* ]]
}

@test "scaffold validates source directory exists" {
    run bash .mise-tasks/scaffold --src /nonexistent --dest ../..

    [ "$status" -eq 1 ]
    [[ "$output" == *"Source directory does not exist"* ]]
}

@test "scaffold validates destination directory exists" {
    run bash .mise-tasks/scaffold --src . --dest /nonexistent

    [ "$status" -eq 1 ]
    [[ "$output" == *"Destination directory does not exist"* ]]
}

@test "validates project name in non-interactive mode" {
    # Rejects invalid characters (spaces)
    run bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project "my project"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]

    # Accepts valid characters
    run bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project "my-valid_project123"

    [ "$status" -eq 0 ]
    [[ "$output" == *"project=my-valid_project123"* ]]
}

@test "configures mise.toml with project name and resets version.txt" {
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject

    # Sets project name in mise.toml
    run grep "testproject" "$DEST_DIR/mise.toml"
    [ "$status" -eq 0 ]

    # Resets project version to 0.1.0 in version.txt
    [ -f "$DEST_DIR/version.txt" ]
    run cat "$DEST_DIR/version.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == "0.1.0" ]]
}

@test "handles .claude directory with --keep-claude option" {
    mkdir -p "$DEST_DIR/.claude"
    touch "$DEST_DIR/.claude/plan.md" "$DEST_DIR/.claude/workflows.md" "$DEST_DIR/.claude/CLAUDE.md"

    # By default (without --keep-claude), removes entire .claude directory
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject

    [ ! -d "$DEST_DIR/.claude" ]

    # With --keep-claude, keeps .claude directory with only upgrade.md and README.md
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject \
        --keep-claude

    [ -d "$DEST_DIR/.claude" ]
}

@test "removes platform-specific files from destination" {
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject

    # Template tests directory should be removed
    [ ! -d "$DEST_DIR/template-tests" ]
    [ ! -f "$DEST_DIR/CHANGELOG.md" ]
    [ ! -f "$DEST_DIR/RELEASE_NOTES.md" ]
    [ ! -f "$DEST_DIR/docs/architecture.md" ]

    # No justfile in scaffolded project
    [ ! -f "$DEST_DIR/justfile" ]

    # mise.toml should exist
    [ -f "$DEST_DIR/mise.toml" ]
}

@test "replaces README.md with template" {
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project myproject

    # README should exist
    [ -f "$DEST_DIR/README.md" ]

    # Should contain project name
    run grep "# myproject" "$DEST_DIR/README.md"
    [ "$status" -eq 0 ]

    # Should contain template name
    run grep "mise-app-template" "$DEST_DIR/README.md"
    [ "$status" -eq 0 ]

    # Should contain platform version
    run grep "v$VERSION" "$DEST_DIR/README.md"
    [ "$status" -eq 0 ]

    # Should not contain template placeholders
    run grep "{{PROJECT_NAME}}" "$DEST_DIR/README.md"
    [ "$status" -eq 1 ]
}

@test "shows success message on completion" {
    run bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project myproject

    [ "$status" -eq 0 ]
    [[ "$output" == *"Scaffolding complete"* ]]
    [[ "$output" == *"Project: myproject"* ]]
}

@test "uses destination directory name as default project name" {
    # Create a properly named destination directory
    NEW_DEST="$ORIGINAL_DIR/.nv/my-awesome-project"
    mkdir -p "$NEW_DEST"

    # Copy platform files to the new destination
    rsync -a \
        --exclude='.git' \
        --exclude='.nv' \
        . "$NEW_DEST/"

    run bash .mise-tasks/scaffold \
        --src . \
        --dest "$NEW_DEST" \
        --non-interactive

    [ "$status" -eq 0 ]
    [[ "$output" == *"project=my-awesome-project"* ]]

    cd "$ORIGINAL_DIR"
    rm -rf "$NEW_DEST"
}

@test "restores original directory on failure" {
    # Destination starts empty (only .nv directory from setup)
    INITIAL_FILE_COUNT=$(find "$DEST_DIR" -mindepth 1 -maxdepth 1 ! -name '.nv' | wc -l)
    [ "$INITIAL_FILE_COUNT" -eq 0 ]

    # Make README.template.md unreadable to cause failure during template substitution
    chmod 000 "$SRC_DIR/README.template.md"

    # Try to run scaffold (should fail during README template substitution)
    run bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject

    # Restore permissions
    chmod 644 "$SRC_DIR/README.template.md"

    # Should have failed
    [ "$status" -ne 0 ]
    [[ "$output" == *"Restoring original directory"* ]]

    # Should be restored to empty (only .nv directory should exist)
    FILE_COUNT=$(find "$DEST_DIR" -mindepth 1 -maxdepth 1 ! -name '.nv' | wc -l)
    [ "$FILE_COUNT" -eq 0 ]
}

@test "removes backup directory on success" {
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project testproject

    # Backup directory should not exist after successful scaffold
    [ ! -d "$DEST_DIR/.nv/.scaffold-backup" ]
}

@test "replaces template name in all case variants across all files" {
    bash .mise-tasks/scaffold \
        --src . \
        --dest ../.. \
        --non-interactive \
        --project my_awesome_project

    # Check mise.toml has the project name replacing the template name
    run grep "my.awesome.project" "$DEST_DIR/mise.toml"
    [ "$status" -eq 0 ]

    # Verify template name no longer appears in mise.toml PROJECT line
    run grep "PROJECT = \"mise-app-template\"" "$DEST_DIR/mise.toml"
    [ "$status" -eq 1 ]

    # Check README contains project name in some variant
    run grep -r "my.awesome.project\|my-awesome-project" "$DEST_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "template source has development task commands" {
    # Run from the original (trusted) project directory
    cd "$ORIGINAL_DIR"

    # User-facing tasks (mise tasks)
    run ~/.local/bin/mise tasks
    [ "$status" -eq 0 ]

    # Upgrade task should exist
    [[ "$output" == *"upgrade"* ]]

    # Template-tests task should exist (for testing the template itself)
    [[ "$output" == *"template-tests"* ]]

    # Scaffold task should exist
    [[ "$output" == *"scaffold"* ]]
}

@test "scaffold processes install.sh.template when --non-interactive (defaults to no install.sh)" {
    # When run with --non-interactive, install.sh.template should be removed (default: no install.sh)
    run bash .mise-tasks/scaffold --src "$SRC_DIR" --dest "$DEST_DIR" --non-interactive --project test-project

    [ "$status" -eq 0 ]

    # Destination should not have install.sh (not requested)
    [ ! -f "$DEST_DIR/install.sh" ]

    # Destination should not have install.sh.template (removed)
    [ ! -f "$DEST_DIR/install.sh.template" ]
}

@test "scaffold with --keep-claude removes commands except upgrade.md" {
    # When run with --keep-claude, only upgrade.md and README.md should remain
    run bash .mise-tasks/scaffold --src "$SRC_DIR" --dest "$DEST_DIR" --non-interactive --project test-project --keep-claude

    [ "$status" -eq 0 ]

    # Only upgrade.md and README.md should remain
    [ -f "$DEST_DIR/.claude/commands/upgrade.md" ]
    [ -f "$DEST_DIR/.claude/commands/README.md" ]

    # adapt.md should be removed (template-only)
    [ ! -f "$DEST_DIR/.claude/commands/adapt.md" ]

    # Plugin commands should not exist
    [ ! -f "$DEST_DIR/.claude/commands/plan.md" ]
    [ ! -f "$DEST_DIR/.claude/commands/commit.md" ]
    [ ! -f "$DEST_DIR/.claude/commands/review.md" ]
}
