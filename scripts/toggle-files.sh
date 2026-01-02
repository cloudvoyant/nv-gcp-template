#!/usr/bin/env bash
: <<DOCUMENTATION
Toggle file visibility in VS Code by modifying .vscode/settings.json

Usage: toggle-files.sh [hide|show]

Commands:
  hide  - Hide non-essential files (show only: docs/, src/, test/, .envrc, justfile, README.md)
  show  - Show all files
DOCUMENTATION

set -euo pipefail

# IMPORTS ----------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source utils.sh if it exists, otherwise define minimal logging functions
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    # Minimal logging functions
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
fi

# CONFIGURATION ----------------------------------------------------------------

SETTINGS_FILE="${SCRIPT_DIR}/../.vscode/settings.json"

# FUNCTIONS --------------------------------------------------------------------

# Update files.exclude section in settings.json
update_file_exclusions() {
    local mode=$1

    if [ ! -f "$SETTINGS_FILE" ]; then
        log_error "Settings file not found: $SETTINGS_FILE"
        return 1
    fi

    # Create backup
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"

    if [ "$mode" = "hide" ]; then
        # Hide non-essential files
        sed -i.tmp '
            /"files.exclude": {/,/}/ {
                s/"\.devcontainer": false/"\.devcontainer": true/
                s/"\.vscode": [^,]*/"\.vscode": true/
                s/"\.github": [^,]*/"\.github": true/
                s/"\.editorconfig": [^,]*/"\.editorconfig": true/
                s/"\.gitignore": [^,]*/"\.gitignore": true/
                s/"\.gitattributes": [^,]*/"\.gitattributes": true/
                s/"\.releaserc\.json": [^,]*/"\.releaserc.json": true/
                s/"\.nv": [^,]*/"\.nv": true/
                s/"\.dockerignore": [^,]*/"\.dockerignore": true/
                s/"Dockerfile": [^,]*/"Dockerfile": true/
                s/"docker-compose\.yml": [^,]*/"docker-compose.yml": true/
                s/"justfile": [^,]*/"justfile": false/
                s/"version\.txt": [^,]*/"version.txt": true/
                s/"\.claude": [^,]*/"\.claude": false/
                s/"scripts": [^,]*/"scripts": true/
                s/"CONTRIBUTING\.md": [^,]*/"CONTRIBUTING.md": true/
                s/"CHANGELOG\.md": [^,]*/"CHANGELOG.md": true/
            }
        ' "$SETTINGS_FILE"

        # Add any missing patterns
        # Check if patterns exist, if not add them before the closing brace of files.exclude
        if ! grep -q '"Dockerfile"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "Dockerfile": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"docker-compose.yml"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "docker-compose.yml": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"justfile"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "justfile": false,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"version.txt"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "version.txt": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '".dockerignore"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    ".dockerignore": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"scripts"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "scripts": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"CONTRIBUTING.md"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "CONTRIBUTING.md": true,\n\1}/' "$SETTINGS_FILE"
        fi
        if ! grep -q '"CHANGELOG.md"' "$SETTINGS_FILE"; then
            sed -i.tmp '/"files.exclude": {/,/}/ s/\(.*\)}/    "CHANGELOG.md": true,\n\1}/' "$SETTINGS_FILE"
        fi
    else
        # Show all files
        sed -i.tmp '
            /"files.exclude": {/,/}/ {
                s/"\.devcontainer": true/"\.devcontainer": false/
                s/"\.vscode": [^,]*/"\.vscode": false/
                s/"\.github": [^,]*/"\.github": false/
                s/"\.editorconfig": [^,]*/"\.editorconfig": false/
                s/"\.gitignore": [^,]*/"\.gitignore": false/
                s/"\.gitattributes": [^,]*/"\.gitattributes": false/
                s/"\.releaserc\.json": [^,]*/"\.releaserc.json": false/
                s/"\.nv": [^,]*/"\.nv": false/
                s/"\.dockerignore": [^,]*/"\.dockerignore": false/
                s/"Dockerfile": [^,]*/"Dockerfile": false/
                s/"docker-compose\.yml": [^,]*/"docker-compose.yml": false/
                s/"justfile": [^,]*/"justfile": false/
                s/"version\.txt": [^,]*/"version.txt": false/
                s/"\.claude": [^,]*/"\.claude": false/
                s/"scripts": [^,]*/"scripts": false/
                s/"CONTRIBUTING\.md": [^,]*/"CONTRIBUTING.md": false/
                s/"CHANGELOG\.md": [^,]*/"CHANGELOG.md": false/
            }
        ' "$SETTINGS_FILE"
    fi

    # Remove temp file
    rm -f "${SETTINGS_FILE}.tmp"

    # Verify the file is still valid (basic check)
    if [ -f "$SETTINGS_FILE" ]; then
        rm -f "${SETTINGS_FILE}.bak"
        return 0
    else
        # Restore backup on failure
        mv "${SETTINGS_FILE}.bak" "$SETTINGS_FILE"
        return 1
    fi
}

# MAIN -------------------------------------------------------------------------

MODE="${1:-}"

if [ -z "$MODE" ]; then
    log_error "Usage: toggle-files.sh [hide|show]"
    exit 1
fi

case "$MODE" in
    hide)
        log_info "Hiding non-essential files in VS Code"
        if update_file_exclusions "hide"; then
            log_success "VS Code: Files hidden successfully"
            log_info "VS Code visible: docs/, src/, test/, .claude/, .envrc, justfile, README.md"
        else
            log_error "Failed to update VS Code settings"
            exit 1
        fi
        ;;
    show)
        log_info "Showing all files in VS Code"
        if update_file_exclusions "show"; then
            log_success "VS Code: All files are now visible"
        else
            log_error "Failed to update VS Code settings"
            exit 1
        fi
        ;;
    *)
        log_error "Invalid mode: $MODE"
        log_error "Usage: toggle-files.sh [hide|show]"
        exit 1
        ;;
esac
