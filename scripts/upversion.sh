#!/usr/bin/env bash
: <<DOCUMENTATION
Analyzes commits and creates a new version using semantic-release.

This script wraps semantic-release to provide a consistent interface for
version management across local and CI environments.

Usage:
  bash scripts/upversion.sh

Behavior:
- Analyzes commits since last release
- Determines next version based on conventional commits
- Updates CHANGELOG.md
- Creates git tag
- Pushes tag to remote (in CI only)

Outputs (for CI):
- new_release_published: true/false
- new_release_version: X.Y.Z

LANGUAGE-SPECIFIC PLUGINS:
Configure in .releaserc.json or package.json

Python: Update version in setup.py/pyproject.toml
  npm install --save-dev @semantic-release/exec
  Add to .releaserc.json:
    "plugins": [
      ["@semantic-release/exec", {
        "prepareCmd": "sed -i 's/version=\".*\"/version=\"\${nextRelease.version}\"/' setup.py"
      }]
    ]

Go: Update version in go.mod or version file
  Similar @semantic-release/exec configuration

Rust: Update Cargo.toml version
  Similar @semantic-release/exec configuration

Node: Uses @semantic-release/npm by default
DOCUMENTATION

# IMPORTS ----------------------------------------------------------------------
source "$(dirname "$0")/utils.sh"
set -euo pipefail

# MAIN -------------------------------------------------------------------------

log_info "Running semantic-release"

# Check if npx is available
if ! command_exists npx; then
    log_error "npx not found. Install Node.js: just setup --ci"
    exit 1
fi

# Capture current version before running semantic-release
CURRENT_VERSION=$(get_version)

# Run semantic-release
if [ -n "$CI" ]; then
    log_info "Running in CI mode - will create release and push"
    npx semantic-release
    EXIT_CODE=$?
else
    log_info "Running in local mode - dry-run only (no tags will be created)"
    npx semantic-release --dry-run
    EXIT_CODE=$?
fi

if [ $EXIT_CODE -ne 0 ]; then
    log_error "Semantic-release failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

log_success "Semantic-release completed successfully"

# Detect if a new release was published by checking if version changed
NEW_VERSION=$(get_version)

# Set GitHub Actions outputs if running in CI
if [ -n "$CI" ] && [ -n "$GITHUB_OUTPUT" ]; then
    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ] && [ -n "$NEW_VERSION" ]; then
        echo "new_release_published=true" >> "$GITHUB_OUTPUT"
        echo "new_release_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
        log_success "New release published: v$NEW_VERSION"
    else
        echo "new_release_published=false" >> "$GITHUB_OUTPUT"
        log_info "No new release published (no commits requiring version bump)"
    fi
fi

log_info "Version update complete"
