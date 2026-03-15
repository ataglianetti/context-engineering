# Session Protocol

## At Session Start
- Both `work-state.md` and `memory.md` auto-load with rules
- Scan `work-state.md` for Active/Blocked projects across all contexts
- Check `memory.md` for relevant recent decisions or open threads
- **Session log check:** When the user's first request targets a specific project, look for `Session Log.md` in that project's `Documents/` folder. If found, read the latest entry (first `###` block) to orient on intent and trajectory — richer context than work-state's "Left Off" alone.
- Reference previous context naturally: "Last time in [context], we were working on..."

## Session Close Detection
Update state when user signals session is ending. Recognize intent, not exact phrases:
- **Explicit memory request:** "update memory", "save this", "remember this"
- **Session ending signals:** "done", "bye", "thanks", "that's all", "wrapping up", or similar
- **Via command:** `/update-memory`

The key is recognizing the intent to close. Variations like "bye bye", "done for now", "all set" all signal the same thing.

## Session Close Process

### Always: Update `work-state.md`

> **Date source:** Always use the `currentDate` value from system context. Never infer today's date from existing file contents.

1. Update "Last Session" date
2. For each project with activity this session:
	- Update "Last Touched" date
	- Update "Left Off" with current state (brief, specific)
	- Update "State" if changed (Active, Blocked, Quiet, Paused)
3. Add new project rows when substantive work happens on something not yet tracked
4. Remove projects Quiet for 14+ days (portfolio notes + daily notes retain history)

### Conditionally: Update `reminders.md`
Only when reminders were created, completed, or date-pushed this session:
1. Add new reminders from meeting next steps with future trigger dates
2. Remove completed reminders
3. Update dates for pushed reminders

### Conditionally: Update milestone frontmatter on portfolio notes
Only when milestone information changed this session:
1. When milestone achieved: update its row in `## Status` table (set Date to actual, Status to Complete), then advance `milestone:` and `milestone-date:` to the next row from the table. If no more milestones, clear both fields.
2. When milestone date shifts: update `milestone-date:` in frontmatter and the Date column in the Status table.
3. When a new milestone is learned: add a row to the Status table and, if it's the next upcoming milestone, set it in frontmatter.

### Conditionally: Update `memory.md`
Only when something in its sections actually changed:
- New decision → add to Recent Decisions (keep last 10-15)
- New open thread → add to Open Threads
- New pattern learned → add to Patterns & Preferences

### Conditionally: Offer Session Log

Offer a session log entry when the session was **substantial** — any of:
- Multi-step work on a single project
- Decisions with alternatives considered
- Paths explored and rejected
- Work that shifted from original intent

**Skip the offer** for quick Q&A, simple edits, routine updates.

**Offer format:**
> Session log entry for [Project]? (captures intent, outcome, findings, handoff)

If accepted:
1. Find or create `Session Log.md` in the project's `Documents/` folder
2. **Prepend** a new entry (newest first) under the `# Session Log` heading
3. Use this structure:

```markdown
### YYYY-MM-DD
**Intent:** What the user came in to accomplish
**Outcome:** What actually happened (especially if different from intent)
**Findings:** Key learnings, hypotheses tested, paths ruled out and why
**Next:** Explicit handoff — what the next session should pick up
```

4. If the file doesn't exist, create it as a Document:

```yaml
---
type: Document
document-type: Session Log
context: "[[Context Name]]"
about: "[[Project Name]]"
created: YYYY-MM-DD
---
```

Keep entries concise (3-5 lines per field max). The value is trajectory and reasoning, not exhaustive detail.

## Confirmation
Always confirm at session close:

**When updates made:**
> Memory updated:
> - Work state: [projects updated]
> - Decision added: [decision] (if any)

**When no substantive updates needed:**
> Memory current. Nothing new to record from this session.

Keep confirmation brief (2-3 lines max).
