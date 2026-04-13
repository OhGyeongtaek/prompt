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
