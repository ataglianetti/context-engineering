#!/usr/bin/env bash
# Frontmatter validation hook (PostToolUse on Write/Edit)
# Enforces hard-wall rules: type: required, context: required on context-linked types

set -euo pipefail

LOG="/tmp/claude-hook-debug.log"

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a .md file
[[ -z "$FILE_PATH" ]] && { echo "$(date '+%H:%M:%S') validate-frontmatter: no file path or not .md — skipped" >> "$LOG"; exit 0; }
[[ "$FILE_PATH" != *.md ]] && { echo "$(date '+%H:%M:%S') validate-frontmatter: not .md — skipped ($FILE_PATH)" >> "$LOG"; exit 0; }

BASENAME=$(basename "$FILE_PATH")
echo "$(date '+%H:%M:%S') validate-frontmatter: checking $BASENAME" >> "$LOG"

# Skip excluded paths (include real path since .claude/ is a symlink)
case "$FILE_PATH" in
  */.claude/* | */Resources/Meta/Claude/* | */Resources/Templates/* | */Resources/Attachments/*)
    echo "$(date '+%H:%M:%S') validate-frontmatter: excluded path — skipped ($BASENAME)" >> "$LOG"
    exit 0 ;;
esac

# Skip if file doesn't exist (shouldn't happen PostToolUse, but guard)
[[ ! -f "$FILE_PATH" ]] && { echo "$(date '+%H:%M:%S') validate-frontmatter: file not found — skipped ($BASENAME)" >> "$LOG"; exit 0; }

# Frontmatter must start on line 1 (skip files using --- as horizontal rules)
FIRST_LINE=$(head -1 "$FILE_PATH")
[[ "$FIRST_LINE" != "---" ]] && { echo "$(date '+%H:%M:%S') validate-frontmatter: no frontmatter — skipped ($BASENAME)" >> "$LOG"; exit 0; }

# Extract frontmatter (between first two --- lines)
FRONTMATTER=$(sed -n '1,/^---$/!d; /^---$/,/^---$/p' "$FILE_PATH" | sed '1d;$d')

# Skip files with no frontmatter
[[ -z "$FRONTMATTER" ]] && { echo "$(date '+%H:%M:%S') validate-frontmatter: empty frontmatter — skipped ($BASENAME)" >> "$LOG"; exit 0; }

# Valid type values
VALID_TYPES="Context|Product|Platform|Initiative|Feature|Document|Definition|Application|Framework|Reference|Journal|Meeting|Meeting Series|Thread|Person|Post|Song|Object Writing|MOC|Vendor"

# Check type: exists and is non-empty
TYPE_VALUE=$(echo "$FRONTMATTER" | grep -E '^type:\s*' | head -1 | sed 's/^type:\s*//' | xargs || true)

if [[ -z "$TYPE_VALUE" ]]; then
  echo "$(date '+%H:%M:%S') validate-frontmatter: BLOCKING — missing type: ($BASENAME)" >> "$LOG"
  jq -n '{
    decision: "block",
    reason: "Missing `type:` property. Add `type:` to frontmatter. Valid types: Context, Product, Platform, Initiative, Feature, Document, Definition, Application, Framework, Reference, Journal, Meeting, Meeting Series, Thread, Person, Post, Song, Object Writing, MOC, Vendor. Check template at Resources/Templates/[Type].md"
  }'
  exit 0
fi

# Check type: value is valid
if ! echo "$TYPE_VALUE" | grep -qE "^($VALID_TYPES)$"; then
  echo "$(date '+%H:%M:%S') validate-frontmatter: BLOCKING — invalid type: '$TYPE_VALUE' ($BASENAME)" >> "$LOG"
  jq -n --arg type "$TYPE_VALUE" '{
    decision: "block",
    reason: ("Invalid type: \"" + $type + "\". Valid types: Context, Product, Platform, Initiative, Feature, Document, Definition, Application, Framework, Reference, Journal, Meeting, Meeting Series, Thread, Person, Post, Song, Object Writing, MOC, Vendor. Check template at Resources/Templates/[Type].md")
  }'
  exit 0
fi

# Context-linked types that require context: property
CONTEXT_TYPES="Product|Platform|Initiative|Feature|Document|Post|Application|Meeting|Thread|MOC|Vendor"

if echo "$TYPE_VALUE" | grep -qE "^($CONTEXT_TYPES)$"; then
  CONTEXT_VALUE=$(echo "$FRONTMATTER" | grep -E '^context:\s*' | head -1 | sed 's/^context:\s*//' || true)

  if [[ -z "$CONTEXT_VALUE" ]]; then
    echo "$(date '+%H:%M:%S') validate-frontmatter: BLOCKING — missing context: for type '$TYPE_VALUE' ($BASENAME)" >> "$LOG"
    jq -n --arg type "$TYPE_VALUE" '{
      decision: "block",
      reason: ("Type \"" + $type + "\" requires a `context:` property. Add `context:` as a wikilink (e.g., `context: \"[[Organization Name]]\"`). Context-linked types must reference their organizational context.")
    }'
    exit 0
  fi

  # Verify it's a wikilink
  if [[ "$CONTEXT_VALUE" != *"[["* ]]; then
    echo "$(date '+%H:%M:%S') validate-frontmatter: BLOCKING — context: not a wikilink ($BASENAME)" >> "$LOG"
    jq -n '{
      decision: "block",
      reason: "The `context:` value must be a wikilink (e.g., `context: \"[[Organization Name]]\"`). Plain text context references break the vault graph."
    }'
    exit 0
  fi
fi

# All checks passed
echo "$(date '+%H:%M:%S') validate-frontmatter: PASSED ($BASENAME)" >> "$LOG"
exit 0
