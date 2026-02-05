# Session Protocol

## At Session Start
- Both `work-state.md` and `memory.md` auto-load with rules
- Scan `work-state.md` for Active/Blocked projects across all contexts
- Check `memory.md` for relevant recent decisions or open threads
- Reference previous context naturally: "Last time we were working on..."

## Session Close Detection
Update state when user signals session is ending. Recognize intent, not exact phrases:
- **Explicit memory request:** "update memory", "save this", "remember this"
- **Session ending signals:** "done", "bye", "thanks", "that's all", "wrapping up", or similar
- **Via command:** `/update-memory`

The key is recognizing the intent to close. Variations like "bye bye", "done for now", "all set" all signal the same thing.

## Session Close Process

### Always: Update `work-state.md`
1. Update "Last Session" date
2. For each project with activity this session:
	- Update "Last Touched" date
	- Update "Left Off" with current state (brief, specific)
	- Update "State" if changed (Active, Blocked, Quiet, Paused)
3. Add new project rows when substantive work happens on something not yet tracked
4. Remove projects Quiet for 14+ days (portfolio notes + daily notes retain history)

### Conditionally: Update `memory.md`
Only when something in its sections actually changed:
- New decision → add to Recent Decisions (keep last 10-15)
- New open thread → add to Open Threads
- New pattern learned → add to Patterns & Preferences

## Confirmation
Always confirm at session close:

**When updates made:**
> Memory updated:
> - Work state: [projects updated]
> - Decision added: [decision] (if any)

**When no substantive updates needed:**
> Memory current. Nothing new to record from this session.

Keep confirmation brief (2-3 lines max).
