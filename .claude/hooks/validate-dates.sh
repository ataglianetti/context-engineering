#!/usr/bin/env bash
# Date validation hook (PostToolUse on Write/Edit)
# Ensures memory.md and work-state.md use today's actual date, not stale/inferred dates.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a .md file
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

# Only validate memory.md and work-state.md
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  memory.md | work-state.md) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist
[[ ! -f "$FILE_PATH" ]] && exit 0

TODAY=$(date +%Y-%m-%d)

if [[ "$BASENAME" == "work-state.md" ]]; then
  # Check "Last Session" date line
  LAST_SESSION=$(grep -A1 '## Last Session' "$FILE_PATH" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
  if [[ -n "$LAST_SESSION" && "$LAST_SESSION" != "$TODAY" ]]; then
    jq -n --arg written "$LAST_SESSION" --arg actual "$TODAY" '{
      decision: "block",
      reason: ("Last Session date is " + $written + ", but today is " + $actual + ". Use the system-provided currentDate.")
    }'
    exit 0
  fi
fi

if [[ "$BASENAME" == "memory.md" ]]; then
  # Check "Last updated:" line at bottom
  LAST_UPDATED=$(grep -oE 'Last updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$FILE_PATH" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
  if [[ -n "$LAST_UPDATED" && "$LAST_UPDATED" != "$TODAY" ]]; then
    jq -n --arg written "$LAST_UPDATED" --arg actual "$TODAY" '{
      decision: "block",
      reason: ("Last updated date is " + $written + ", but today is " + $actual + ". Use the system-provided currentDate.")
    }'
    exit 0
  fi
fi

# All checks passed
exit 0
