#!/usr/bin/env bash
# Thread note budget check (PostToolUse on Write/Edit)
# Warns when a Thread note drifts from the current-state spec:
#   - Summary narrative > 700 chars (accretion-log tell — rewrite as current state)
#   - Key Points top-level bullets > 8
#   - one-liner: > 300 chars
#   - a "## Reply" heading exists (reply-lifecycle violation — sent replies are ## Thread messages)
# Does not block — friction to trigger a consolidation pass. Fails open.

set -euo pipefail

LOG="/tmp/claude-hook-debug.log"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

case "$FILE_PATH" in
  */Calendar/*) ;;
  *) exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

TYPE=$(grep -m1 '^type:' "$FILE_PATH" | sed 's/type:[[:space:]]*//' || true)
[[ "$TYPE" != "Thread" ]] && exit 0

# Only check processed threads (must have a Summary section)
grep -q '^## Summary' "$FILE_PATH" || exit 0

WARNINGS=()

# --- 1. Summary narrative length -------------------------------------------
# Narrative = lines between "## Summary" and the first bullet, "Key signals:",
# or next heading. Whitespace-normalized character count.
NARRATIVE=""
IN_SUMMARY=false
while IFS= read -r line; do
  if [[ "$line" == "## Summary" ]]; then
    IN_SUMMARY=true
    continue
  fi
  if $IN_SUMMARY; then
    if [[ "$line" =~ ^## ]] || [[ "$line" =~ ^-\  ]] || [[ "$line" =~ ^Key\ signals ]] || [[ "$line" =~ ^\*\*.+\*\* ]]; then
      break
    fi
    NARRATIVE+="$line "
  fi
done < "$FILE_PATH"

NARRATIVE_LEN=$(echo "$NARRATIVE" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//' | wc -c | tr -d ' ')
NARRATIVE_THRESHOLD=700
if [[ $NARRATIVE_LEN -gt $NARRATIVE_THRESHOLD ]]; then
  WARNINGS+=("Summary narrative is ${NARRATIVE_LEN} chars (threshold ${NARRATIVE_THRESHOLD}). Rewrite as CURRENT STATE in 2-3 sentences — no dated 'On 6/8…' accretion paragraphs; chronology lives in the messages.")
fi

# --- 2. Key Points bullet count ---------------------------------------------
KP_COUNT=0
IN_KP=false
while IFS= read -r line; do
  if [[ "$line" == "## Key Points" ]]; then
    IN_KP=true
    continue
  fi
  if $IN_KP; then
    [[ "$line" =~ ^## ]] && break
    [[ "$line" =~ ^-\  ]] && ((KP_COUNT++)) || true
  fi
done < "$FILE_PATH"

KP_THRESHOLD=8
if [[ $KP_COUNT -gt $KP_THRESHOLD ]]; then
  WARNINGS+=("Key Points has ${KP_COUNT} top-level bullets (threshold ${KP_THRESHOLD}). Keep decisions/numbers the Summary doesn't carry; resolve superseded points; no triple-stating with Summary and messages.")
fi

# --- 3. one-liner length ------------------------------------------------------
ONE_LINER=$(grep -m1 '^one-liner:' "$FILE_PATH" | sed 's/^one-liner:[[:space:]]*//' || true)
OL_LEN=$(echo -n "$ONE_LINER" | wc -c | tr -d ' ')
OL_THRESHOLD=300
if [[ $OL_LEN -gt $OL_THRESHOLD ]]; then
  WARNINGS+=("one-liner is ${OL_LEN} chars (threshold ${OL_THRESHOLD}). One sentence — move the detail into the Summary.")
fi

# --- 4. Reply-lifecycle violation ---------------------------------------------
if grep -qE '^## Reply' "$FILE_PATH"; then
  WARNINGS+=("Found a '## Reply' section. Sent replies are ordinary ## Thread messages (plain-text sender header); drafts use the /draft-reply DRAFT header inside ## Thread.")
fi

echo "$(date '+%H:%M:%S') validate-thread-budget: $FILE_PATH — narrative=${NARRATIVE_LEN} kp=${KP_COUNT} oneliner=${OL_LEN} warnings=${#WARNINGS[@]}" >> "$LOG"

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  REASON="Thread budget check: "
  for w in "${WARNINGS[@]}"; do
    REASON+="$w "
  done
  jq -n --arg reason "$REASON" '{decision: "warn", reason: $reason}'
  exit 0
fi

exit 0
