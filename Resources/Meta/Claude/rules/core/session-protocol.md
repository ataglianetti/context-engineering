# Session Protocol

## At Session Start
- Both `work-state.md` and `memory.md` auto-load with rules
- Scan `work-state.md` for Active/Blocked projects across all contexts
- When the user's first request targets a specific context, the per-context `**Last Session:**` line above that context's project table is the freshest narrative pulse — read it before the project rows
- Check `memory.md` for relevant recent decisions or open threads
- **Session log check:** When the user's first request targets a specific project, look for `Session Log.md` in that project's `Documents/` folder. If found, read the latest entry (first `###` block) to orient on intent and trajectory — richer context than work-state's "Left Off" alone.
- Reference previous context naturally: "Last time in [context], we were working on..."

### Time awareness
A `UserPromptSubmit` hook injects a `Current local time: HH:MM TZ, Weekday YYYY-MM-DD` line at the top of each message (settings.json). **If that line is present, use it** for time-of-day reasoning the date alone can't give: weekday vs. weekend, morning vs. evening, whether a listed meeting is already past, late-night pacing. **If it's absent, proceed without — never infer a clock time the model doesn't have.** Hook absence is a normal state (settings not reloaded yet, a Claude surface that doesn't run hooks). This is the live "now"; the session-start `currentDate` is the same date but survives context compaction less reliably.

## Session Close Detection
Update state when user signals session is ending. Recognize intent, not exact phrases:
- **Explicit memory request:** "update memory", "save this", "remember this"
- **Session ending signals:** "done", "bye", "thanks", "that's all", "wrapping up", or similar
- **Via command:** `/update-memory`

The key is recognizing the intent to close. Variations like "bye bye", "done for now", "all set" all signal the same thing.

## Session Close Process

### Always: Update `work-state.md`

> **Date source:** Always use the `currentDate` value from system context. Never infer today's date from existing file contents.

**Last Session is per-context.** Each context block owns its own `**Last Session (YYYY-MM-DD):**` line sitting between the context H2 and its project table. There is no global Last Session field.

1. For each context that saw activity this session:
	- Replace that context's `**Last Session (YYYY-MM-DD):**` line with today's date and a **1–2 sentence pulse** covering ONLY work in that context — the cross-project arc + what's next, not a session log. Target ≤ ~500 chars. This line auto-loads every session; depth belongs in the project Left Off cells (current state) and Session Logs (full history), not here. Do not append `Prior (date): …` chains — one optional "Prior (date): …" clause for a same-context session worth flagging is the ceiling.
	- Do not mix cross-context work into a single block — if two contexts both saw activity, update both independently
	- Leave unchanged any context that saw no activity (its prior Last Session date stays)
2. For each project with activity this session:
	- Update "Last Touched" date
	- Update "Left Off" — **current state + next action only, 2–3 sentences.** Keep the near-term milestone date/name (the milestone-drift hook checks for it). This cell is auto-loaded every session, so it must stay short. **It is not a session log.** Do not append `Prior (date): …` narrative chains here — that history belongs in the project's `Session Log.md` (see below). If a cell starts growing a dated chain, that's the signal to move the depth to the Session Log and cut the cell back.
	- Update "State" if changed (Active, Blocked, Quiet, Paused)
3. Add new project rows when substantive work happens on something not yet tracked
4. Remove projects Quiet for 14+ days (portfolio notes + daily notes retain history)

### Conditionally: Update `reminders.md`
Only when reminders were created, completed, or date-pushed this session:
1. Add new reminders from meeting next steps with future trigger dates
2. Remove completed reminders
3. Update dates for pushed reminders

### Conditionally: Update `## Status` table on portfolio notes
Only when milestone information changed this session:
- When milestone achieved: update its row in the `## Status` table (set Date to actual, Status to Complete).
- When milestone date shifts: update the Date column in the Status table.
- When a new milestone is learned: add a row to the Status table.

Milestones live in the body Status table only — there is no `milestone:` frontmatter field.

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
