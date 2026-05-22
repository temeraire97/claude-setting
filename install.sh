#!/bin/bash

# Claude Code Configuration Installer
# Restores ~/.claude configuration from this dotfiles repo.
# - Config files & directories are symlinked back into ~/.claude
# - Marketplaces & plugins are reinstalled via the `claude` CLI
# Existing real files/directories are preserved as *.backup
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Configuration Installer ==="
echo ""

mkdir -p "$CLAUDE_DIR"

# Symlink a file into place, backing up any existing real file first.
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$src" ]; then
        echo "  skip (백업본 없음): ${dest##*/}"
        return 0
    fi
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup="$dest.backup.$(date +%Y%m%d-%H%M%S)"
        if ! mv "$dest" "$backup"; then
            echo "  ⚠ 기존 파일 백업 실패 — 건너뜀: $dest"
            return 0
        fi
        echo "  기존 파일 백업: $backup"
    elif [ -L "$dest" ]; then
        echo "  기존 심링크 교체: $dest"
    fi
    ln -sfn "$src" "$dest"
    echo "  linked: $dest"
}

# Symlink a directory into place, backing up any existing real directory first.
link_dir() {
    local src="$1"
    local dest="$2"

    if [ ! -d "$src" ]; then
        echo "  skip (백업본 없음): ${dest##*/}"
        return 0
    fi
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup="$dest.backup.$(date +%Y%m%d-%H%M%S)"
        if ! mv "$dest" "$backup"; then
            echo "  ⚠ 기존 디렉토리 백업 실패 — 건너뜀: $dest"
            return 0
        fi
        echo "  기존 디렉토리 백업: $backup"
    elif [ -L "$dest" ]; then
        echo "  기존 심링크 교체: $dest"
    fi
    ln -sfn "$src" "$dest"
    echo "  linked: $dest"
}

# Extract values from a JSON file. Prefers jq, falls back to python3.
json_extract() {
    local file="$1"
    local jq_filter="$2"
    local py_code="$3"

    if command -v jq >/dev/null 2>&1; then
        jq -r "$jq_filter" "$file" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "$py_code" "$file" 2>/dev/null
    else
        return 1
    fi
}

# 1. Config files
echo "[1/5] Config files..."
link_file "$SCRIPT_DIR/CLAUDE.md"             "$CLAUDE_DIR/CLAUDE.md"
link_file "$SCRIPT_DIR/settings.json"         "$CLAUDE_DIR/settings.json"
link_file "$SCRIPT_DIR/statusline-wrapper.sh" "$CLAUDE_DIR/statusline-wrapper.sh"

# 2. Directories — whole-dir symlink so new entries are tracked automatically
echo "[2/5] Skills / agents / hooks / commands..."
link_dir "$SCRIPT_DIR/skills"   "$CLAUDE_DIR/skills"
link_dir "$SCRIPT_DIR/agents"   "$CLAUDE_DIR/agents"
link_dir "$SCRIPT_DIR/hooks"    "$CLAUDE_DIR/hooks"
link_dir "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands"

# 3 & 4. Marketplaces and plugins (reinstalled via the claude CLI)
if ! command -v claude >/dev/null 2>&1; then
    echo "[3/5] Marketplaces... skip ('claude' CLI 없음)"
    echo "[4/5] Plugins... skip ('claude' CLI 없음)"
    echo "  Claude Code 설치 후 install.sh를 다시 실행하세요."
else
    mkdir -p "$CLAUDE_DIR/plugins"
    MARKET_FILE="$SCRIPT_DIR/plugins/known_marketplaces.json"
    PLUGIN_FILE="$SCRIPT_DIR/plugins/installed_plugins.json"

    # 3. Register marketplaces (must precede plugin installation)
    echo "[3/5] Marketplaces..."
    if [ -f "$MARKET_FILE" ]; then
        markets=$(json_extract "$MARKET_FILE" \
            '.[].source.repo' \
            'import json,sys; d=json.load(open(sys.argv[1])); [print(r) for v in d.values() if (r:=v.get("source",{}).get("repo"))]' || true)
        if [ -z "$markets" ]; then
            echo "  ✗ 파싱 실패 (jq/python3 없음 또는 형식 변경) — 수동 등록 필요"
        else
            while IFS= read -r repo; do
                [ -n "$repo" ] || continue
                if claude plugins marketplace add "$repo" >/dev/null 2>&1; then
                    echo "  ✓ $repo"
                else
                    echo "  ✗ 실패: $repo"
                fi
            done <<< "$markets"
        fi
    else
        echo "  skip (known_marketplaces.json 백업본 없음)"
    fi

    # 4. Install plugins
    echo "[4/5] Plugins..."
    if [ -f "$PLUGIN_FILE" ]; then
        plugins=$(json_extract "$PLUGIN_FILE" \
            '.plugins | keys[]' \
            'import json,sys; d=json.load(open(sys.argv[1])); [print(k) for k in d.get("plugins",{})]' || true)
        if [ -z "$plugins" ]; then
            echo "  ✗ 파싱 실패 (jq/python3 없음 또는 형식 변경) — 수동 설치 필요"
        else
            ok=0
            fail=0
            while IFS= read -r plugin; do
                [ -n "$plugin" ] || continue
                if out=$(claude plugins install "$plugin" 2>&1); then
                    echo "  ✓ $plugin"
                    ok=$((ok + 1))
                else
                    echo "  ✗ 실패: $plugin"
                    echo "$out" | tail -2 | sed 's/^/        /'
                    fail=$((fail + 1))
                fi
            done <<< "$plugins"
            echo "  설치 결과: 성공 $ok / 실패 $fail"
        fi
    else
        echo "  skip (installed_plugins.json 백업본 없음)"
    fi
fi

# 5. launchd 자동 백업(매일 19:00) 재등록 — 백업 시스템 자체를 복원.
#    skills/agents/hooks 심링크([2/5]) 이후에 실행해야 첫 자동 sync가
#    심링크를 건너뛰어 저장소를 덮어쓰지 않는다.
echo "[5/5] Auto-sync (launchd)..."
PLIST_SRC="$SCRIPT_DIR/com.user.claude-sync.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.claude-sync.plist"
if [ -f "$PLIST_SRC" ]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    if cp "$PLIST_SRC" "$PLIST_DEST"; then
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
        if launchctl load "$PLIST_DEST" 2>/dev/null; then
            echo "  ✓ 자동 백업 등록됨 (com.user.claude-sync)"
        else
            echo "  ✗ launchctl load 실패 — 수동 실행: launchctl load $PLIST_DEST"
        fi
    else
        echo "  ✗ plist 복사 실패: $PLIST_DEST"
    fi
else
    echo "  skip (com.user.claude-sync.plist 백업본 없음)"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "복원된 항목:"
echo "  - CLAUDE.md, settings.json, statusline-wrapper.sh (심볼릭 링크)"
echo "  - skills/, agents/, hooks/ (디렉토리 심볼릭 링크)"
echo "  - 마켓플레이스 / 플러그인 (claude CLI로 재설치)"
echo "  - launchd 자동 백업 (com.user.claude-sync)"
echo ""
echo "참고:"
echo "  - 기존 실제 파일·디렉토리는 *.backup 으로 보존됩니다."
echo "  - 플러그인 활성화 상태(enabledPlugins)는 settings.json에서 관리됩니다."
echo "  - 실패한 마켓플레이스/플러그인은 위 로그의 ✗ 항목을 확인하세요."
