#!/usr/bin/env bash
# Wikilink validation hook (PostToolUse on Write/Edit)
# Warns (does not block) when wikilinks point to non-existent notes

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a .md file
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

# Skip excluded paths (but allow work-state.md)
case "$FILE_PATH" in
  */rules/core/work-state.md) ;; # allow through
  */.claude/* | */Resources/Meta/Claude/* | */Resources/Templates/* | */Resources/Attachments/*) exit 0 ;;
esac

# Skip if file doesn't exist
[[ ! -f "$FILE_PATH" ]] && exit 0

# Vault root (resolve symlink if needed)
VAULT_ROOT="$(cd "$(dirname "$FILE_PATH")" && while [[ ! -f ".obsidian/app.json" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)"
[[ "$VAULT_ROOT" == "/" ]] && exit 0

# Build list of all note names (cached, 60s TTL)
CACHE="/tmp/claude-vault-notes-cache"
if [[ ! -f "$CACHE" ]] || [[ $(( $(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || echo 0) )) -gt 60 ]]; then
  find "$VAULT_ROOT" -name "*.md" -not -path "*/.trash/*" -not -path "*/.obsidian/*" | while read -r f; do
    basename "$f" .md
  done | tr '[:upper:]' '[:lower:]' | sort -u > "$CACHE"
fi

# Extract wikilinks, skipping code blocks and Templater tags
LINKS=$(
  awk '
    /^```/ { in_code = !in_code; next }
    in_code { next }
    { print }
  ' "$FILE_PATH" \
  | sed 's/<%[^%]*%>//g' \
  | grep -oE '\[\[[^]]+\]\]' \
  | sed 's/^\[\[//; s/\]\]$//' \
  | sed 's/|.*//; s/#.*//' \
  | sort -u
)

# For work-state.md: also extract project names from table
if [[ "$FILE_PATH" == *"work-state.md" ]]; then
  PROJ_NAMES=$(
    grep -E '^\|[^|]+\| (Active|Blocked|Quiet|Paused) \|' "$FILE_PATH" \
    | sed 's/^| *//; s/ *|.*//' \
    | sort -u
  )
  if [[ -n "$PROJ_NAMES" ]]; then
    LINKS=$(printf '%s\n%s' "$LINKS" "$PROJ_NAMES" | sort -u)
  fi
fi

[[ -z "$LINKS" ]] && exit 0

# Check each link against cache
ORPHANS=()
while IFS= read -r link; do
  [[ -z "$link" ]] && continue
  LOWER_LINK=$(echo "$link" | tr '[:upper:]' '[:lower:]')
  if ! grep -qxF "$LOWER_LINK" "$CACHE"; then
    ORPHANS+=("$link")
  fi
done <<< "$LINKS"

if [[ ${#ORPHANS[@]} -gt 0 ]]; then
  FORMATTED=""
  for o in "${ORPHANS[@]}"; do
    [[ -n "$FORMATTED" ]] && FORMATTED="$FORMATTED, "
    FORMATTED="${FORMATTED}[[${o}]]"
  done
  jq -n --arg orphans "$FORMATTED" '{
    decision: "warn",
    reason: ("Orphan wikilinks found: " + $orphans + ". These notes do not exist in the vault. Verify the link target or create the note first.")
  }'
  exit 0
fi

exit 0
