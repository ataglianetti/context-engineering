Manually trigger session close memory updates (same logic as session-protocol.md).

1. Read `.claude/rules/core/work-state.md` and `.claude/rules/core/memory.md`
2. **Update `work-state.md`:**
   - Set "Last Session" date to today
   - For each project with activity this session:
     - Update "Last Touched" date
     - Update "Left Off" with current state (brief, specific)
     - Update "State" if changed (Active, Blocked, Quiet, Paused)
   - Add new project rows for substantive work not yet tracked
   - Remove projects Quiet for 14+ days
3. **Conditionally update `memory.md`** (only when something actually changed):
   - New decision -> add to Recent Decisions table (keep last 10-15)
   - New open thread -> add to Open Threads
   - Resolved thread -> remove from Open Threads
   - New pattern learned -> add to Patterns & Preferences
4. **Offer session log** if the session was substantial (multi-step work, decisions with alternatives, paths explored and rejected)
5. Show user what changed
