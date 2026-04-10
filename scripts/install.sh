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
