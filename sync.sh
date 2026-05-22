#!/bin/bash

# Claude Code Configuration Auto-Sync Script
# Syncs ~/.claude configs to this dotfiles repo and commits/pushes if changed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="$SCRIPT_DIR/.sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# macOS desktop notification — best-effort, never breaks the run.
notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1 || true
}

# Ensure directories exist
mkdir -p "$SCRIPT_DIR/skills" "$SCRIPT_DIR/plugins" "$SCRIPT_DIR/agents" "$SCRIPT_DIR/hooks"

# Copy a file if it changed. Skips symlinks (already managed by dotfiles).
sync_file() {
    local src="$1"
    local dest="$2"

    if [ -f "$src" ] && [ ! -L "$src" ]; then
        if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
            cp "$src" "$dest"
            log "Updated: $dest"
        fi
    fi
    return 0
}

# Mirror a directory. Skips symlinks (already managed by dotfiles).
sync_dir() {
    local src="$1"
    local dest="$2"

    if [ -d "$src" ] && [ ! -L "$src" ]; then
        rsync -a --delete "$src/" "$dest/" 2>/dev/null || true
    fi
    return 0
}

# Sync files
sync_file "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
sync_file "$CLAUDE_DIR/settings.json" "$SCRIPT_DIR/settings.json"
sync_file "$CLAUDE_DIR/statusline-wrapper.sh" "$SCRIPT_DIR/statusline-wrapper.sh"
sync_file "$CLAUDE_DIR/plugins/installed_plugins.json" "$SCRIPT_DIR/plugins/installed_plugins.json"
sync_file "$CLAUDE_DIR/plugins/known_marketplaces.json" "$SCRIPT_DIR/plugins/known_marketplaces.json"

# Sync directories
sync_dir "$CLAUDE_DIR/skills" "$SCRIPT_DIR/skills"
sync_dir "$CLAUDE_DIR/agents" "$SCRIPT_DIR/agents"
sync_dir "$CLAUDE_DIR/hooks" "$SCRIPT_DIR/hooks"
sync_dir "$CLAUDE_DIR/commands" "$SCRIPT_DIR/commands"

# Commit and push
cd "$SCRIPT_DIR" || exit 1
if git rev-parse --git-dir >/dev/null 2>&1; then
    # Commit if the working tree has changes
    if [ -n "$(git status --porcelain)" ]; then
        git add -A

        # Secret scan before committing — defense-in-depth for a public repo.
        if command -v gitleaks >/dev/null 2>&1; then
            gl_rc=0
            gl_out=$(gitleaks protect --staged --no-banner --redact 2>&1) || gl_rc=$?
            if [ "$gl_rc" -eq 1 ]; then
                log "SECRET DETECTED by gitleaks — commit/push aborted:"
                printf '%s\n' "$gl_out" | tail -20 >> "$LOG_FILE" || true
                notify "Claude 백업 중단" "시크릿 감지 — 커밋 취소됨. .sync.log 확인"
                exit 1
            elif [ "$gl_rc" -ne 0 ]; then
                log "gitleaks error (rc=$gl_rc) — secret scan skipped"
            fi
        else
            log "gitleaks not installed — secret scan skipped"
        fi

        git commit -m "chore(claude): auto-sync $(date '+%Y-%m-%d %H:%M')" --no-gpg-sign >/dev/null 2>&1 || true
        log "Committed changes"
    fi

    # Push whenever a remote exists. Always attempted, so a push that
    # failed on a previous run is retried here on the next run.
    if git remote get-url origin >/dev/null 2>&1; then
        if git push origin HEAD >/dev/null 2>&1; then
            log "Pushed to remote"
        else
            log "Push failed — will retry next run"
            notify "Claude 백업 경고" "원격 푸시 실패 — 다음 실행에서 재시도합니다"
        fi
    fi
fi

# Keep the log file small (last 100 lines)
if [ -f "$LOG_FILE" ]; then
    tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE" || true
fi
