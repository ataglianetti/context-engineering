# Session Protocol

## At Session Start
- Memory file (`core/memory.md`) auto-loads with rules
- Reference previous context naturally: "Last time we were working on..."
- Check Active Work State for current priorities

## Session Close Detection
Update memory when user signals session is ending. Recognize intent, not exact phrases:
- **Explicit memory request:** "update memory", "save this", "remember this"
- **Session ending signals:** "done", "bye", "thanks", "that's all", "wrapping up", or similar
- **Via command:** `/update-memory`

The key is recognizing the intent to close. Variations like "bye bye", "done for now", "all set" all signal the same thing.

## Memory Update Process
1. Update "Last Session" with date, focus, where we left off
2. Update other sections only if something changed:
   - New decision → add to Recent Decisions
   - Priority shift → update Active Work State
   - New pattern learned → add to Patterns & Preferences
3. Keep Recent Decisions to last 10-15 entries

## Confirmation
Always confirm memory status at session close:

**When updates made:**
> Memory updated: [brief list of what changed]
> - Last Session: [topic]
> - Added decision: [decision]

**When no substantive updates needed:**
> Memory current. Nothing new to record from this session.

Keep confirmation brief (2-3 lines max).
