#!/bin/bash

# Claude Code Configuration Auto-Sync Script
# Syncs ~/.claude configs to dotfiles and commits if changed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="$SCRIPT_DIR/.sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Ensure directories exist
mkdir -p "$SCRIPT_DIR/skills/design-first" "$SCRIPT_DIR/plugins"

sync_file() {
    local src="$1"
    local dest="$2"

    if [ -f "$src" ]; then
        # Skip if source is a symlink (already managed by dotfiles)
        if [ -L "$src" ]; then
            return 0
        fi

        # Compare and copy if different
        if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
            cp "$src" "$dest"
            log "Updated: $dest"
            return 1  # indicates change
        fi
    fi
    return 0
}

sync_dir() {
    local src="$1"
    local dest="$2"

    if [ -d "$src" ] && [ ! -L "$src" ]; then
        rsync -a --delete "$src/" "$dest/" 2>/dev/null || true
    fi
}

# Sync files
sync_file "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
sync_file "$CLAUDE_DIR/settings.json" "$SCRIPT_DIR/settings.json"
sync_file "$CLAUDE_DIR/plugins/installed_plugins.json" "$SCRIPT_DIR/plugins/installed_plugins.json"

# Sync directories
sync_dir "$CLAUDE_DIR/skills/design-first" "$SCRIPT_DIR/skills/design-first"

# Git commit if in a git repo and there are changes
cd "$SCRIPT_DIR"
if [ -d ".git" ] || git rev-parse --git-dir > /dev/null 2>&1; then
    # Check for any changes (including untracked files)
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        git commit -m "chore(claude): auto-sync $(date '+%Y-%m-%d %H:%M')" --no-gpg-sign 2>/dev/null || true
        log "Committed changes"

        # Push if remote exists
        if git remote get-url origin &>/dev/null; then
            git push origin HEAD 2>/dev/null && log "Pushed to remote" || log "Push failed (will retry)"
        fi
    fi
fi

# Keep log file small (last 100 lines)
if [ -f "$LOG_FILE" ]; then
    tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
