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

# Files to sync (source -> destination)
declare -A FILES=(
    ["$CLAUDE_DIR/CLAUDE.md"]="$SCRIPT_DIR/CLAUDE.md"
    ["$CLAUDE_DIR/settings.json"]="$SCRIPT_DIR/settings.json"
    ["$CLAUDE_DIR/plugins/installed_plugins.json"]="$SCRIPT_DIR/plugins/installed_plugins.json"
)

# Directories to sync
declare -A DIRS=(
    ["$CLAUDE_DIR/skills/design-first"]="$SCRIPT_DIR/skills/design-first"
)

CHANGED=false

# Sync files
for src in "${!FILES[@]}"; do
    dest="${FILES[$src]}"
    if [ -f "$src" ]; then
        # Check if file is a symlink pointing to our dotfiles (skip if so)
        if [ -L "$src" ]; then
            continue
        fi

        # Compare and copy if different
        if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
            cp "$src" "$dest"
            log "Updated: $dest"
            CHANGED=true
        fi
    fi
done

# Sync directories
for src in "${!DIRS[@]}"; do
    dest="${DIRS[$src]}"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
        # Use rsync for directory sync
        if rsync -ac --delete "$src/" "$dest/" 2>/dev/null; then
            # Check if rsync made changes
            if [ $? -eq 0 ]; then
                # rsync doesn't tell us if changes were made, so we check git status later
                :
            fi
        fi
    fi
done

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
