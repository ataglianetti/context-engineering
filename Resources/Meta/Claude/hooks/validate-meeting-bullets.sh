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
# and measure their length. This captures the flat bullet list, not sub-bullets or
# topic section bullets.
#
# Length matters as much as count: a note can sit at exactly 6 bullets and still be a
# wall if each bullet is a paragraph. Counting alone is the gauge that can't see the
# failure the consolidation pass creates when it merges instead of cutting.
IN_BULLETS=false
BULLET_COUNT=0
LONG_COUNT=0
MAX_LEN=0
MAX_BULLET=""

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
      BULLET_COUNT=$((BULLET_COUNT + 1))
      LINE_LEN=${#line}
      if [[ $LINE_LEN -gt $MAX_LEN ]]; then
        MAX_LEN=$LINE_LEN
        MAX_BULLET="$line"
      fi
      if [[ $LINE_LEN -gt 180 ]]; then
        LONG_COUNT=$((LONG_COUNT + 1))
      fi
    fi
  fi
done < "$FILE_PATH"

THRESHOLD=6
LENGTH_THRESHOLD=180

echo "$(date '+%H:%M:%S') validate-meeting-bullets: $FILE_PATH — $BULLET_COUNT top-level bullets, longest $MAX_LEN chars, $LONG_COUNT over $LENGTH_THRESHOLD" >> "$LOG"

REASON=""

if [[ $BULLET_COUNT -gt $THRESHOLD ]]; then
  REASON="Meeting note has $BULLET_COUNT top-level bullets (threshold: $THRESHOLD). Run the consolidation pass: drop bullets that restate the Summary, cut implementation details that don't affect decisions."
fi

if [[ $LONG_COUNT -gt 0 ]]; then
  # Truncate the worst offender for the warning message
  EXCERPT="${MAX_BULLET:0:100}"
  [[ ${#MAX_BULLET} -gt 100 ]] && EXCERPT="${EXCERPT}..."

  LEN_MSG="$LONG_COUNT bullet(s) exceed $LENGTH_THRESHOLD chars; longest is $MAX_LEN chars. A bullet this long is a paragraph — split it, then re-run the consolidation filters on both halves (one half is usually droppable). Do NOT fix the count by merging bullets; that is what produced this. Worst offender: $EXCERPT"

  if [[ -n "$REASON" ]]; then
    REASON="$REASON  ALSO: $LEN_MSG"
  else
    REASON="$LEN_MSG"
  fi
fi

if [[ -n "$REASON" ]]; then
  echo "$(date '+%H:%M:%S') validate-meeting-bullets: WARNING — count=$BULLET_COUNT max_len=$MAX_LEN long=$LONG_COUNT" >> "$LOG"
  jq -n --arg reason "$REASON" '{decision: "warn", reason: $reason}'
  exit 0
fi

echo "$(date '+%H:%M:%S') validate-meeting-bullets: PASSED ($BULLET_COUNT ≤ $THRESHOLD, longest $MAX_LEN ≤ $LENGTH_THRESHOLD)" >> "$LOG"
exit 0
