#!/usr/bin/env bash
# Date validation hook (PostToolUse on Write/Edit)
# Ensures memory.md and work-state.md use today's actual date, not stale/inferred dates.

set -euo pipefail

LOG="/tmp/claude-hook-debug.log"

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

# Skip rules directory (these are rules files, not vault notes)
case "$FILE_PATH" in
  */.claude/* | */Resources/Meta/Claude/*)
    echo "$(date '+%H:%M:%S') validate-dates: rules path — skipped ($BASENAME)" >> "$LOG"
    exit 0 ;;
esac

# Skip if file doesn't exist
[[ ! -f "$FILE_PATH" ]] && exit 0

TODAY=$(date +%Y-%m-%d)

if [[ "$BASENAME" == "work-state.md" ]]; then
  # Per-context inline format: **Last Session (YYYY-MM-DD):** (one line per context).
  # The 2026-04-23 restructure replaced the old single "## Last Session" heading with
  # these inline lines. Only contexts touched this session get stamped today; others
  # legitimately stay in the past, and work-state is also edited mid-session — so we
  # cannot require any line to equal today without constant false positives. The one
  # unambiguous error (an inferred/fabricated date) is a date in the FUTURE.
  FUTURE_DATE=$(grep -oE 'Last Session \([0-9]{4}-[0-9]{2}-[0-9]{2}\)' "$FILE_PATH" \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
    | awk -v today="$TODAY" '$0 > today {print; exit}' || true)
  echo "$(date '+%H:%M:%S') validate-dates: work-state.md FUTURE_DATE=${FUTURE_DATE:-none} TODAY=$TODAY" >> "$LOG"
  if [[ -n "$FUTURE_DATE" ]]; then
    echo "$(date '+%H:%M:%S') validate-dates: BLOCKING — future Last Session date" >> "$LOG"
    jq -n --arg written "$FUTURE_DATE" --arg actual "$TODAY" '{
      decision: "block",
      reason: ("A Last Session date is " + $written + ", which is in the future (today is " + $actual + "). Use the system-provided currentDate, not an inferred date.")
    }'
    exit 0
  fi
  echo "$(date '+%H:%M:%S') validate-dates: work-state.md PASSED" >> "$LOG"
fi

if [[ "$BASENAME" == "memory.md" ]]; then
  # Check "Last updated:" line at bottom of file
  LAST_UPDATED=$(grep -oE 'Last updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$FILE_PATH" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
  echo "$(date '+%H:%M:%S') validate-dates: memory.md LAST_UPDATED=$LAST_UPDATED TODAY=$TODAY" >> "$LOG"
  if [[ -n "$LAST_UPDATED" && "$LAST_UPDATED" != "$TODAY" ]]; then
    echo "$(date '+%H:%M:%S') validate-dates: BLOCKING — date mismatch" >> "$LOG"
    jq -n --arg written "$LAST_UPDATED" --arg actual "$TODAY" '{
      decision: "block",
      reason: ("Last updated date is " + $written + ", but today is " + $actual + ". Use the system-provided currentDate.")
    }'
    exit 0
  fi
  echo "$(date '+%H:%M:%S') validate-dates: memory.md PASSED" >> "$LOG"
fi

# All checks passed — exit silently
exit 0
