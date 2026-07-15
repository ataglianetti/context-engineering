#!/usr/bin/env bash
# Validate date wikilink format in Meeting notes (PostToolUse on Write/Edit)
# Enforces: line after H1 must be [[YYYY-MM-DD|Month DDth, YYYY]]
# - Link target = daily note (YYYY-MM-DD), never the meeting note itself
# - Alias uses ordinal day, no day names, no year omission

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only Calendar .md files
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *"/Calendar/"* ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Only Meeting type notes
TYPE=$(awk '/^---$/{n++; next} n==0{next} n==1{print; next} n>=2{exit}' "$FILE_PATH" | grep -E '^type:' | head -1 | sed 's/^type:[[:space:]]*//')
[[ "$TYPE" != "Meeting" ]] && exit 0

# Find the H1 line and the line after it
H1_LINE=$(grep -n '^# ' "$FILE_PATH" | head -1 | cut -d: -f1)
[[ -z "$H1_LINE" ]] && exit 0

DATE_LINE_NUM=$((H1_LINE + 1))
DATE_LINE=$(sed -n "${DATE_LINE_NUM}p" "$FILE_PATH")

# Skip if line is empty (note still being constructed)
[[ -z "$DATE_LINE" ]] && exit 0

# Extract the wikilink parts
# Expected: [[YYYY-MM-DD|Month DDth, YYYY]]
if ! echo "$DATE_LINE" | grep -qE '^\[\['; then
  # Not a wikilink at all — might be raw text or something else, skip
  exit 0
fi

# Extract link target (before |) and alias (after |)
LINK_TARGET=$(echo "$DATE_LINE" | sed -n 's/^\[\[\([^|]*\)|.*/\1/p')
LINK_ALIAS=$(echo "$DATE_LINE" | sed -n 's/^\[\[[^|]*|\(.*\)\]\].*/\1/p')

# If no pipe (no alias), extract the whole link
if [[ -z "$LINK_TARGET" ]]; then
  LINK_TARGET=$(echo "$DATE_LINE" | sed -n 's/^\[\[\(.*\)\]\].*/\1/p')
fi

ERRORS=""

# Check 1: Link target must be YYYY-MM-DD (daily note), not a meeting note filename
if ! echo "$LINK_TARGET" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  ERRORS="Link target is '$LINK_TARGET' — must be a daily note date (YYYY-MM-DD), not a meeting filename."
fi

# Check 2: Alias must exist
if [[ -z "$LINK_ALIAS" ]]; then
  ERRORS="${ERRORS:+$ERRORS\n}Missing display alias. Format: [[YYYY-MM-DD|Month DDth, YYYY]]"
fi

# Check 3: Alias must not contain day names
if echo "$LINK_ALIAS" | grep -qE '(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)'; then
  ERRORS="${ERRORS:+$ERRORS\n}Alias contains day name ('$LINK_ALIAS'). Use 'Month DDth, YYYY' format only — no day names."
fi

# Check 4: Alias must contain a year
if [[ -n "$LINK_ALIAS" ]] && ! echo "$LINK_ALIAS" | grep -qE '[0-9]{4}'; then
  ERRORS="${ERRORS:+$ERRORS\n}Alias missing year ('$LINK_ALIAS'). Use 'Month DDth, YYYY' format."
fi

# Check 5: Alias should use ordinal day (1st, 2nd, 3rd, etc.)
if [[ -n "$LINK_ALIAS" ]] && ! echo "$LINK_ALIAS" | grep -qE '[0-9]+(st|nd|rd|th)'; then
  ERRORS="${ERRORS:+$ERRORS\n}Alias missing ordinal day ('$LINK_ALIAS'). Use 'April 1st, 2026' not 'April 1, 2026'."
fi

if [[ -n "$ERRORS" ]]; then
  # Derive the correct format from the link target date
  if echo "$LINK_TARGET" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    CORRECT_DATE="$LINK_TARGET"
  else
    # Try to get date from filename
    CORRECT_DATE=$(basename "$FILE_PATH" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
  fi

  if [[ -n "${CORRECT_DATE:-}" ]]; then
    # Generate correct alias using date command
    MONTH=$(date -j -f "%Y-%m-%d" "$CORRECT_DATE" "+%B" 2>/dev/null || echo "")
    DAY=$(date -j -f "%Y-%m-%d" "$CORRECT_DATE" "+%-d" 2>/dev/null || echo "")
    YEAR=$(date -j -f "%Y-%m-%d" "$CORRECT_DATE" "+%Y" 2>/dev/null || echo "")

    # Add ordinal suffix
    case "$DAY" in
      1|21|31) SUFFIX="st" ;;
      2|22) SUFFIX="nd" ;;
      3|23) SUFFIX="rd" ;;
      *) SUFFIX="th" ;;
    esac

    CORRECT="[[$CORRECT_DATE|$MONTH ${DAY}${SUFFIX}, $YEAR]]"
  else
    CORRECT="[[YYYY-MM-DD|Month DDth, YYYY]]"
  fi

  jq -n --arg reason "Meeting date wikilink format error:
$(echo -e "$ERRORS")

Fix: replace the date line with: $CORRECT" \
    '{decision: "block", reason: $reason}'
  exit 0
fi

exit 0
