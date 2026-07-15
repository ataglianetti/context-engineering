#!/usr/bin/env bash
# Meeting bullet count check (PostToolUse on Write/Edit)
# Warns when a Meeting note has more than 6 bullets under ## Summary.
# Does not block — just creates friction to trigger a consolidation review.

set -euo pipefail

LOG="/tmp/claude-hook-debug.log"

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a .md file
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

# Only check Calendar/ files
case "$FILE_PATH" in
  */Calendar/*) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist
[[ ! -f "$FILE_PATH" ]] && exit 0

# Only check files with type: Meeting
TYPE=$(grep -m1 '^type:' "$FILE_PATH" | sed 's/type:[[:space:]]*//' || true)
[[ "$TYPE" != "Meeting" ]] && exit 0

# Only check if ## Summary exists (already processed)
grep -q '^## Summary' "$FILE_PATH" || exit 0

# Count top-level bullets (lines starting with "- ") between ## Summary and the next ** or ## heading
# This captures the flat bullet list, not sub-bullets or topic section bullets
IN_BULLETS=false
BULLET_COUNT=0

while IFS= read -r line; do
  # Start counting after ## Summary + the narrative paragraph
  if [[ "$line" == "## Summary" ]]; then
    IN_BULLETS=true
    continue
  fi

  # Stop at next heading, bold topic section, or Next Steps
  if $IN_BULLETS; then
    if [[ "$line" =~ ^## ]] || [[ "$line" =~ ^\*\*Next\ Steps ]] || [[ "$line" =~ ^\*\*.+\*\* ]]; then
      break
    fi
    # Count only top-level bullets (- not indented)
    if [[ "$line" =~ ^-\  ]]; then
      ((BULLET_COUNT++))
    fi
  fi
done < "$FILE_PATH"

echo "$(date '+%H:%M:%S') validate-meeting-bullets: $FILE_PATH — $BULLET_COUNT top-level bullets" >> "$LOG"

THRESHOLD=6

if [[ $BULLET_COUNT -gt $THRESHOLD ]]; then
  echo "$(date '+%H:%M:%S') validate-meeting-bullets: WARNING — $BULLET_COUNT bullets exceeds threshold of $THRESHOLD" >> "$LOG"
  jq -n --argjson count "$BULLET_COUNT" --argjson threshold "$THRESHOLD" '{
    decision: "warn",
    reason: ("Meeting note has " + ($count | tostring) + " top-level bullets (threshold: " + ($threshold | tostring) + "). Run consolidation pass: drop bullets that restate the Summary, merge overlapping bullets, cut implementation details that don'\''t affect decisions.")
  }'
  exit 0
fi

echo "$(date '+%H:%M:%S') validate-meeting-bullets: PASSED ($BULLET_COUNT ≤ $THRESHOLD)" >> "$LOG"
exit 0
