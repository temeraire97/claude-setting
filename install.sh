#!/bin/bash

# Claude Code Configuration Installer
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Configuration Installer ==="
echo ""

# Create ~/.claude directory if not exists
mkdir -p "$CLAUDE_DIR/skills"

# 1. Symlink CLAUDE.md
echo "[1/4] Setting up CLAUDE.md..."
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "  Backing up existing CLAUDE.md to CLAUDE.md.backup"
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
fi
ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Done: ~/.claude/CLAUDE.md -> $SCRIPT_DIR/CLAUDE.md"

# 2. Symlink settings.json
echo "[2/4] Setting up settings.json..."
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
    echo "  Backing up existing settings.json to settings.json.backup"
    mv "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Done: ~/.claude/settings.json -> $SCRIPT_DIR/settings.json"

# 3. Symlink skills directory
echo "[3/4] Setting up skills..."

# design-first skill
if [ -d "$CLAUDE_DIR/skills/design-first" ] && [ ! -L "$CLAUDE_DIR/skills/design-first" ]; then
    echo "  Backing up existing design-first skill"
    mv "$CLAUDE_DIR/skills/design-first" "$CLAUDE_DIR/skills/design-first.backup"
fi
ln -sfn "$SCRIPT_DIR/skills/design-first" "$CLAUDE_DIR/skills/design-first"
echo "  Done: ~/.claude/skills/design-first"

# backup skill
if [ -d "$CLAUDE_DIR/skills/backup" ] && [ ! -L "$CLAUDE_DIR/skills/backup" ]; then
    echo "  Backing up existing backup skill"
    mv "$CLAUDE_DIR/skills/backup" "$CLAUDE_DIR/skills/backup.bak"
fi
ln -sfn "$SCRIPT_DIR/skills/backup" "$CLAUDE_DIR/skills/backup"
echo "  Done: ~/.claude/skills/backup"

# 4. Install plugins
echo "[4/4] Installing plugins..."

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "  Warning: 'claude' CLI not found. Skipping plugin installation."
    echo "  Install plugins manually after installing Claude Code:"
    echo "    claude plugins install claude-hud@claude-hud"
    echo "    claude plugins install claude-mem@thedotmack"
else
    echo "  Installing claude-hud..."
    claude plugins install claude-hud@claude-hud 2>/dev/null || echo "  (already installed or error)"

    echo "  Installing claude-mem..."
    claude plugins install claude-mem@thedotmack 2>/dev/null || echo "  (already installed or error)"

    echo "  Plugins installed."
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed:"
echo "  - CLAUDE.md (global instructions)"
echo "  - settings.json (plugin settings, statusLine, thinking mode)"
echo "  - skills/design-first (Scout-Architect-Estimator workflow)"
echo "  - skills/backup (backup management)"
echo "  - Plugins: claude-hud, claude-mem"
echo ""
echo "Note: Plugin activation status is managed in settings.json"
echo "  - claude-hud: enabled"
echo "  - claude-mem: disabled"
