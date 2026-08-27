#!/usr/bin/env bash
# Writing-style audit reminder (PostToolUse on Write/Edit)
# Fires a NON-BLOCKING nudge to run the writing-style.md audit when
# external-facing prose is written: Post, Application, or Thread notes.
#
# The audit is semantic (diplomatic sandwich, negation-reversal pile-up,
# colon-setup punches, every-paragraph mic-drop, symmetric structure) and
# can't be detected mechanically. This hook doesn't try. Its only job is
# timing: nudge at the moment the draft lands, when the rule is most likely
# to have faded from context.

set -euo pipefail

LOG="/tmp/claude-hook-debug.log"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

BASENAME=$(basename "$FILE_PATH")

# Skip config/template/attachment paths — never external-facing prose
case "$FILE_PATH" in
  */.claude/* | */Resources/Meta/Claude/* | */Resources/Templates/* | */Resources/Attachments/*)
    exit 0 ;;
esac

[[ ! -f "$FILE_PATH" ]] && exit 0

# Extract `type:` from frontmatter (only within the first --- ... --- block)
TYPE=$(awk '/^---$/{c++; next} c==1 && /^type:/{sub(/^type:[[:space:]]*/,""); gsub(/"/,""); gsub(/\r/,""); print; exit}' "$FILE_PATH" | sed 's/[[:space:]]*$//')

case "$TYPE" in
  Post|Application|Thread)
    echo "$(date '+%H:%M:%S') writing-style-reminder: nudged ($TYPE — $BASENAME)" >> "$LOG"
    jq -n --arg type "$TYPE" '{
      decision: "warn",
      reason: ("External-facing copy written (type: " + $type + "). Before presenting to the user, run the writing-style.md audit: scan for negation-reversal pile-up (\"X, not Y\" as default shape), colon-setup punches (\"The unusual part:\"), every-paragraph mic-drops, the diplomatic sandwich, validate-then-disagree, and symmetric structure. Revise in-file before showing the draft. If this write was not author-drafted prose (e.g., recording an inbound thread or a resume bullet list), disregard.")
    }'
    exit 0 ;;
esac

echo "$(date '+%H:%M:%S') writing-style-reminder: skipped (type='$TYPE' — $BASENAME)" >> "$LOG"
exit 0
