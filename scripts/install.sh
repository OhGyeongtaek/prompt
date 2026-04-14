#!/bin/bash
# OGT Prompt — 글로벌 심볼릭 링크 설치 스크립트
#
# 사용법: ./scripts/install.sh
#
# commands/ 내 모든 스킬을 ~/.claude/commands/에 심볼릭 링크로 등록한다.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_DIR="$REPO_DIR/commands"
TARGET_DIR="$HOME/.claude/commands"

mkdir -p "$TARGET_DIR"

linked=0
skipped=0

for skill_dir in "$COMMANDS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue

    skill_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/$skill_name.md"

    if [ ! -f "$skill_file" ]; then
        echo "[skip] $skill_name — $skill_file not found"
        skipped=$((skipped + 1))
        continue
    fi

    target="$TARGET_DIR/$skill_name.md"

    if [ -L "$target" ]; then
        rm "$target"
    fi

    ln -s "$skill_file" "$target"
    echo "[link] $skill_name → $target"
    linked=$((linked + 1))
done

echo ""
echo "done: $linked linked, $skipped skipped"

# ── Claude Code settings.json 설정 ──────────────────────────────
SETTINGS_FILE="$HOME/.claude/settings.json"

if ! command -v jq &>/dev/null; then
    echo ""
    echo "[warn] jq가 설치되어 있지 않아 settings.json 설정을 건너뜁니다."
    echo "       brew install jq 후 다시 실행하세요."
    exit 0
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

echo ""
echo "Updating Claude Code settings..."

# 기존 설정을 보존하면서 병합
tmp=$(mktemp)
jq '
  .model = "sonnet" |
  .env = (.env // {}) * {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

echo "[set] model = sonnet"
echo "[set] MAX_THINKING_TOKENS = 10000"
echo "[set] CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = 50"
echo "[set] CLAUDE_CODE_SUBAGENT_MODEL = haiku"
echo ""
echo "settings updated: $SETTINGS_FILE"

# ── claude-hud 설치 ──────────────────────────────────────────────
echo ""
echo "Installing claude-hud..."

CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_HUD_CACHE_DIR="$CLAUDE_CONFIG_DIR/plugins/cache/claude-hud/claude-hud"

# 이미 설치된 버전 확인
if ls -d "$CLAUDE_HUD_CACHE_DIR"/*/  &>/dev/null; then
    HUD_VERSION=$(ls -d "$CLAUDE_HUD_CACHE_DIR"/*/ | awk -F/ '{ print $(NF-1) }' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
    echo "[skip] claude-hud $HUD_VERSION already installed"
else
    # 최신 버전 태그 가져오기
    if command -v git &>/dev/null; then
        HUD_VERSION=$(git ls-remote --tags https://github.com/jarrodwatts/claude-hud 2>/dev/null \
            | awk -F/ '{ print $NF }' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
            | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
        HUD_VERSION="${HUD_VERSION:-0.0.12}"
    else
        HUD_VERSION="0.0.12"
    fi

    HUD_INSTALL_DIR="$CLAUDE_HUD_CACHE_DIR/$HUD_VERSION"
    mkdir -p "$HUD_INSTALL_DIR"

    git clone --depth 1 --branch "v$HUD_VERSION" \
        https://github.com/jarrodwatts/claude-hud "$HUD_INSTALL_DIR" 2>/dev/null \
    || git clone --depth 1 \
        https://github.com/jarrodwatts/claude-hud "$HUD_INSTALL_DIR"

    echo "[installed] claude-hud $HUD_VERSION → $HUD_INSTALL_DIR"
fi

# statusLine 설정 추가 (jq 필요)
if command -v jq &>/dev/null; then
    RUNTIME_PATH=$(command -v node 2>/dev/null || echo "node")
    STATUS_CMD="$RUNTIME_PATH \"$CLAUDE_HUD_CACHE_DIR/$HUD_VERSION/dist/index.js\""

    tmp=$(mktemp)
    jq --arg cmd "$STATUS_CMD" \
        '.statusLine = {"type": "command", "command": $cmd}' \
        "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    echo "[set] statusLine = claude-hud"
fi
