#!/usr/bin/env bash
set -euo pipefail

# Validate day-of-week in date strings within Calendar notes.
# Blocks when a written day name doesn't match the actual day for that date.
# Example: "Tuesday March 25, 2026" blocks if March 25 is actually a Wednesday.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only Calendar .md files
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *"/Calendar/"* ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

ERROR_FILE="/tmp/claude-dow-errors.$$"
rm -f "$ERROR_FILE"

# Extract "DayName Month DD, YYYY" patterns and validate each
grep -oE '(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday) (January|February|March|April|May|June|July|August|September|October|November|December) [0-9]{1,2}, [0-9]{4}' "$FILE_PATH" | sort -u | while read -r MATCH; do
  WRITTEN_DAY=$(echo "$MATCH" | awk '{print $1}')
  DATE_PART=$(echo "$MATCH" | sed 's/^[A-Za-z]* //')
  ACTUAL_DAY=$(date -j -f "%B %d, %Y" "$DATE_PART" "+%A" 2>/dev/null) || continue
  if [[ "$WRITTEN_DAY" != "$ACTUAL_DAY" ]]; then
    echo "$MATCH → should be $ACTUAL_DAY" >> "$ERROR_FILE"
  fi
done

if [[ -f "$ERROR_FILE" ]]; then
  ERRORS=$(cat "$ERROR_FILE")
  rm -f "$ERROR_FILE"
  jq -n --arg reason "Day-of-week mismatch:
$ERRORS

Fix: replace the incorrect day name with the correct one shown above." \
    '{decision: "block", reason: $reason}'
  exit 0
fi

exit 0
