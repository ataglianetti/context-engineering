#!/usr/bin/env bash
# Context-budget ratchet (PostToolUse on Write/Edit)
#
# Blocks GROWTH of the always-on context files (rules/core/memory.md, rules/core/work-state.md)
# while they are over budget. THE RATCHET INVARIANT: an edit that shrinks the file is NEVER
# blocked — archiving/compressing always passes, so the hook cannot trap a session.
#
# Why it exists: the always-loaded context files are the ones that silently bloat into a
# junk drawer. Discipline doesn't hold; a wall does. This keeps them small enough to stay
# useful by forcing you to archive old entries out before you can add new ones.
#
# Checks (all lengths measured on whitespace-squeezed content — Markdown table
# formatting pads cells with alignment spaces; padding is not content):
#   memory.md     R1  Recent Decisions rows: block only if count > CAP  AND count grew vs stored
#   memory.md     R2  any decision row dated today: normalized line <= TODAY_ROW_MAX chars
#   memory.md     R3  Open Threads bullets: block only if count > CAP  AND count grew vs stored
#   work-state.md W1  Left Off cell in a row whose Last Touched = today: <= LEFTOFF_MAX chars
#
# State: /tmp file storing last-seen normalized size + counts per file. Missing state
# (reboot, first run) => record and pass (fail-open baseline). Delta checks (R1/R3) never
# fire without state, so pre-existing over-budget content is grandfathered until it grows.
#
# Fail-open everywhere: any error => exit 0 silently. This is a wall, not a tripwire.
# Tune the caps below to your own tolerance.

set -u
trap 'exit 0' ERR

LOG="/tmp/claude-hook-debug.log"
STATE="${CONTEXT_BUDGET_STATE:-/tmp/claude-context-budget.state}"

DECISIONS_CAP=8
THREADS_CAP=25
TODAY_ROW_MAX=700
LEFTOFF_MAX=1250

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[[ -z "$FILE_PATH" ]] && exit 0

# Only the two always-on context files
case "$FILE_PATH" in
  */rules/core/memory.md | */rules/core/work-state.md) ;;
  *) exit 0 ;;
esac

# Only THIS project's own files — a session editing another repo's
# rules/core/memory.md must not be budgeted against this project's caps.
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  case "$FILE_PATH" in
    "$CLAUDE_PROJECT_DIR"/*) ;;
    *) exit 0 ;;
  esac
fi

[[ -f "$FILE_PATH" ]] || exit 0

TODAY=$(date +%Y-%m-%d)
BASENAME=$(basename "$FILE_PATH")

# Normalized copy: squeeze runs of spaces (table-alignment padding is not content)
NORM=$(mktemp) || exit 0
tr -s ' ' < "$FILE_PATH" > "$NORM" 2>/dev/null || { rm -f "$NORM"; exit 0; }
NEW_SIZE=$(wc -c < "$NORM" | tr -d ' ')

# Current counts (memory.md only; zeros for work-state.md)
ROWS=0; THREADS=0
if [[ "$BASENAME" == "memory.md" ]]; then
  ROWS=$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}' "$NORM" 2>/dev/null || true)
  THREADS=$(awk '/^## Open Threads/{f=1;next} /^## /{f=0} f && /^- /{n++} END{print n+0}' "$NORM" 2>/dev/null || true)
  [[ "$ROWS" =~ ^[0-9]+$ ]] || ROWS=0
  [[ "$THREADS" =~ ^[0-9]+$ ]] || THREADS=0
fi

# Stored state: "<basename> <norm_size> <rows> <threads>"
STORED_SIZE=""; STORED_ROWS=""; STORED_THREADS=""
if [[ -f "$STATE" ]]; then
  STORED_LINE=$(grep "^$BASENAME " "$STATE" 2>/dev/null | tail -1 || true)
  if [[ -n "$STORED_LINE" ]]; then
    STORED_SIZE=$(echo "$STORED_LINE" | awk '{print $2}')
    STORED_ROWS=$(echo "$STORED_LINE" | awk '{print $3}')
    STORED_THREADS=$(echo "$STORED_LINE" | awk '{print $4}')
  fi
fi

update_state() {
  { [[ -f "$STATE" ]] && grep -v "^$BASENAME " "$STATE" 2>/dev/null; true; } > "$STATE.tmp"
  echo "$BASENAME $NEW_SIZE $ROWS $THREADS" >> "$STATE.tmp"
  mv "$STATE.tmp" "$STATE" 2>/dev/null || true
}

finish_pass() { update_state; rm -f "$NORM"; exit 0; }

block() {
  update_state
  echo "$(date '+%H:%M:%S') context-budget: BLOCKING $BASENAME — $2" >> "$LOG" 2>/dev/null || true
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  rm -f "$NORM"
  exit 0
}

# ── THE RATCHET INVARIANT: a shrinking edit always passes ──────────────────
if [[ -n "$STORED_SIZE" ]] && [[ "$NEW_SIZE" -lt "$STORED_SIZE" ]]; then
  finish_pass
fi

if [[ "$BASENAME" == "memory.md" ]]; then
  # R1: decision-row count — delta-gated (grandfathers pre-existing overage)
  if [[ "$ROWS" -gt "$DECISIONS_CAP" && -n "$STORED_ROWS" && "$ROWS" -gt "$STORED_ROWS" ]]; then
    block "Context budget: Recent Decisions now has $ROWS rows (cap $DECISIONS_CAP). Archive the oldest row(s) out of memory.md (into a dated note or your decisions archive) and delete them from the table in this same session, so the always-loaded file stays small. Nothing is lost — the detail moves, it doesn't disappear. Shrinking edits always pass this hook." "R1 rows=$ROWS stored=$STORED_ROWS"
  fi
  # R2: any decision row dated today over the per-row budget.
  # String prefix match, not regex — awk -v mangles backslash escapes ("\|" -> "|"),
  # which silently turns an anchored pattern into match-everything.
  LONG_TODAY_ROW=$(awk -v p="| $TODAY " -v max="$TODAY_ROW_MAX" 'index($0, p) == 1 && length($0) > max {print length($0); exit}' "$NORM" 2>/dev/null || true)
  if [[ -n "$LONG_TODAY_ROW" ]]; then
    block "Context budget: a decision row dated $TODAY is $LONG_TODAY_ROW chars (cap $TODAY_ROW_MAX, whitespace-normalized). Keep decision + one-line rationale in the table; the full narrative belongs in a linked note or the project Session Log. Shrinking edits always pass this hook." "R2 len=$LONG_TODAY_ROW"
  fi
  # R3: Open Threads count — delta-gated
  if [[ "$THREADS" -gt "$THREADS_CAP" && -n "$STORED_THREADS" && "$THREADS" -gt "$STORED_THREADS" ]]; then
    block "Context budget: Open Threads now has $THREADS bullets (cap $THREADS_CAP). Move the least-active thread's detail out to an archive note and leave a one-line index entry (name + one sentence + pointer). Shrinking edits always pass this hook." "R3 threads=$THREADS stored=$STORED_THREADS"
  fi
fi

if [[ "$BASENAME" == "work-state.md" ]]; then
  # W1: Left Off cell in a row touched today (remainder of the line after the "| TODAY |" date cell)
  LONG_CELL=$(awk -v d="| $TODAY |" -v max="$LEFTOFF_MAX" '
    { i = index($0, d)
      if (i > 0) { rest = substr($0, i + length(d)); if (length(rest) > max) { print length(rest); exit } } }
  ' "$NORM" 2>/dev/null || true)
  if [[ -n "$LONG_CELL" ]]; then
    block "Context budget: a Left Off cell touched today is $LONG_CELL chars (cap $LEFTOFF_MAX, whitespace-normalized). Move the dated narrative chain to the project's Session Log; keep current state + next action in the cell. Shrinking edits always pass this hook." "W1 len=$LONG_CELL"
  fi
fi

finish_pass
