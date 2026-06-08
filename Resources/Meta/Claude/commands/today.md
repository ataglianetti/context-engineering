---
description: Morning briefing — today's meetings, deadlines, reminders
---

Morning briefing showing what's on the docket. Separate from `/first-light` (journaling) and `/daily-note` (end-of-day log).

**Interactive by design — don't automate headlessly.** Meeting selection runs through `AskUserQuestion`, so `/today` can't run via launchd / `claude -p`: a headless run can't prompt, so it dumps the whole briefing into the daily note, which then lingers past end of day. Run it manually each morning.

**Prerequisites:**
- `icalBuddy` installed (`brew install ical-buddy`)
- Calendar accounts synced to Apple Calendar via System Settings → Internet Accounts
- Terminal.app granted Calendar access (Privacy & Security → Calendars)

## 0. Temporal Catch-Up

Backfilling missing daily/weekly/monthly notes is handled by **`/temporal-catch-up`** — that command is the single source of truth for the catch-up logic (idempotent detection, evidence sources, oldest-first daily → weekly → monthly, the one-line report). It runs as **Workflow 3** below.

Two `/today`-specific constraints, both already honored by the command:
- **Inline, never a background agent** — writes need the live approval channel (a backgrounded run fails closed silently). Invoking `/temporal-catch-up` from here keeps it in the main session.
- **Last, after the briefing** — so backfill never delays the interactive part.

---

## 1. Today's Meetings

Run icalBuddy via Terminal.app (some IDEs don't have Calendar TCC permission):
```bash
osascript -e 'tell application "Terminal" to do script "icalBuddy -f eventsToday > /tmp/icalbuddy-output.txt 2>&1"'
sleep 3
cat /tmp/icalbuddy-output.txt
```

- Show time, title, calendar source (to distinguish contexts)
- Flag meetings that have vault series notes (match title against `series:` frontmatter in Calendar/)
- For series matches, note the last meeting date
- **Anchor to the `Current local time:` line** (injected by the UserPromptSubmit hook, if present): split the list into already-past vs. still-upcoming meetings rather than dumping them flat, and adapt the framing to when `/today` is actually being run (a mid-afternoon run isn't a "morning briefing"). The clock can't confirm a meeting *occurred* — only that it's before/after now. If the time line is absent, list meetings flat as before.

## 1.5. Content Deadlines

Scan Post notes for upcoming `target-date:` values. Posts live in `Contexts/Personal/Content/Posts/` (all subdirectories).

**Query:** Grep for `target-date:` across all Post notes. Parse the ISO date and compare to today.

**Proximity markers:**
- `(OVERDUE)` — date has passed and `post-status:` is not `published`
- `(!!)` — 14 days or fewer
- `(!)` — 15-30 days
- Listed, no marker — 31-60 days
- Not surfaced — 60+ days out

**Skip:** Posts with `post-status: published` (already shipped, regardless of date).

**Output (inline in Workflow 1, after meetings):**
```
### Content Deadlines
- (!!) Feb 27 — "Post Title" (Substack, draft)
- (!) Mar 6 — "Another Post" (Substack, draft)
```

Show the post title (from first alias or filename), platform (from `post-platform:`), and current status (from `post-status:`).

If no content deadlines are within 60 days, omit this section entirely.

---

## 2. Reminders

Read `.claude/reminders.md`. Surface items where date ≤ today.

**Output:**
```
### Reminders (2)
1. Prepare panel contribution — *resurfaced from Mar 10* — [[YYYY-MM-DD Meeting Source]]
2. Check if deliverables are distributed — [[YYYY-MM-DD Meeting Source]]
```

If no reminders are due, omit this section.

**Triage** is simple: the user batch-responds.

| Response | What happens |
|----------|-------------|
| `done` | Remove from reminders list |
| `push <date>` | Update the date |
| Any other text | Append as context note, keep current date |
| *(not mentioned)* | No change |

**Date parsing:** Accept natural date formats: `march 15`, `3/15`, `2 weeks`, `next monday`, `1 month`. Resolve to ISO date (YYYY-MM-DD).

**Adding reminders:** During `/today` or any session, the user can say "remind me [thing] on [date]" and it gets added to the list. `/meeting-notes` can also suggest reminders from next steps (user approves before adding).

## 2.5. Vault Health

Run the read-only staleness check and surface its output **only if non-empty** (the script is silent when everything's clean — no "all good" line):

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/hooks/vault-health.sh"
```

It flags overdue `/distill-memory` runs, `memory.md` decision-table bloat, Quiet/Paused projects past 14 days, and oversized work-state Left Off cells. Print whatever it returns verbatim, then let the user decide whether to act — don't auto-run the suggested fixes. If it returns nothing, omit this section entirely.

---

## 3. Output & Flow

The briefing is **two sequential workflows**. Present each block, handle its interaction, then move to the next.

### Workflow 1: Meetings + Deadlines → Note Creation

Present today's meetings, content deadlines (Section 1.5), then immediately offer meeting note creation (Section 4). Resolve note creation before moving on.

```
## Today — Wednesday, March 5

### Meetings
- 10:00 AM — [Series Name] Standup ([Context Name]) — *series, last: Feb 26*
- 2:00 PM — Team Sync ([Context Name])

### Content Deadlines
- (OVERDUE) Feb 27 — "Post Title" (Substack, draft)
```

→ Meeting note creation prompt (Section 4)
→ Create selected notes
→ Then continue to Workflow 2

### Workflow 2: Reminders + Vault Health

After meeting notes are handled, present due reminders (Section 2) if any exist, then the vault-health block (Section 2.5) if the script returned anything.

```
### Reminders (1)
1. Prepare panel contribution — [[YYYY-MM-DD Meeting Source]]

> Triage: "1: push march 17" or "1: done"

⚠️ **Vault health**
- 3 auto-memory entries past revisit date — run `/distill-memory`
```

**Output is conversational, not written to any file.**

### Workflow 3: Temporal Catch-Up (inline)

After reminders are handled, run **`/temporal-catch-up`** inline in this session (see Section 0). It does the cheap existence scan first and stays silent if nothing's missing; otherwise it backfills oldest-first (daily → weekly → monthly) and reports one line. This is the only part of `/today` that writes notes to disk, and it runs last so it never delays the briefing.

---

## 4. Meeting Note Creation

Runs as part of Workflow 1 (after meeting list, before reminders).

### Person Note Lookup

When matching attendee names to Person notes, use `Glob` with pattern `Contexts/*/People/{Attendee Name}*.md`. Do **not** use Grep with a filename glob — the content + filename glob combination silently fails in flat directories.

### Filter Events

From the icalBuddy output, **exclude** events that aren't real meetings:
- All-day events without attendees (e.g., "PAYDAY", holidays)
- Events titled "Focus Time", "Lunch", or similar blocks
- Cancelled events

### Present Selection

Use `AskUserQuestion` with `multiSelect: true`. Each option:
- **Label:** `HH:MM AM — Event Title`
- **Description:** Context + classification hint (e.g., "Series: [Series Name] Standup", "1:1", or "New meeting")

**One option per meeting** — even when two look similar (e.g., two standups from different contexts), give each its own option. Never combine meetings into a single checkbox.

**4-option cap:** `AskUserQuestion` supports max 4 options per question. When there are more than 4 eligible meetings, split into multiple rounds (e.g., "Meetings — morning" and "Meetings — afternoon"). Never silently drop meetings to fit the cap.

Before presenting, check which meetings already have notes. If `Calendar/YYYY-MM-DD [Expected Name].md` exists, exclude it from the options and note it:
> Already have notes for: [Series Name] Standup

If ALL meetings already have notes, skip the question entirely:
> All meeting notes already exist for today.

### Classify Each Selected Meeting

For each selected meeting, classify in priority order:

**1. Series Match**
Match the calendar event title against Meeting Series notes in `Calendar/`:
- Compare against the Meeting Series note's **filename** (basename) and **`aliases:`** entries
- Use bidirectional fuzzy matching (case-insensitive): the event title *contains* a series name/alias, OR a series name/alias *contains* the event title. Also strip common prefixes before comparing: year prefixes ("2026 ", "2025 "), frequency words ("Bi-weekly ", "Weekly ", "Monthly ")
- Calendar event titles often differ from vault series names (e.g., "2026 Bi-weekly Products team meeting" → "Product Team"). Add known calendar titles as `aliases:` on the Meeting Series note so they match directly
- If matched → **Meeting Occurrence** type

**2. 1:1 Detection**
If icalBuddy shows exactly 2 attendees and one is [Your Name] (or the user's email):
- The other attendee is the 1:1 partner
- Match their name against Person notes in `Contexts/*/People/`
- If matched → **Meeting (1-1)** type

**3. Generic Meeting**
Everything else → **Generic Meeting** type. Ask user for context if calendar source is ambiguous.

### Create Notes

#### Series Match → Meeting Occurrence

Read the matched Meeting Series note. Build the note:

```markdown
---
type: Meeting
context: [from series]
series: "[[Series Name]]"
about: [from series]
with: [from series]
aliases:
  - "[first alias from series]"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# [First alias from series]
[[YYYY-MM-DD|Formatted Date]]

## Notes
-
```

File: `Calendar/YYYY-MM-DD [Series Note Filename].md`

#### 1:1 → Meeting (1-1)

Read the matched Person note. Pull `cadence:` (default "Ad-hoc") and `context:`.

**Carry-forward harvest:** Look for a `## Carry Forward` section in the Person note (header may have parenthetical suffix, e.g., `## Carry Forward (next 1:1 agenda)`). If present:
1. Capture every line from the header through the next `##` heading (or EOF), excluding the header line itself
2. Seed `## Notes` with those bullets verbatim (preserve indentation)
3. Remove the section from the Person note — header + body, plus one blank line after — so it doesn't double-fire on the following 1:1

If no `## Carry Forward` section exists, seed `## Notes` with a single bare `- ` as usual.

```markdown
---
type: Meeting
context: [from person note]
about:
with:
  - "[[Person Name]]"
aliases:
  - "[Cadence] 1:1 with [Person Name]"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# 1:1 with [Person Name]
[[YYYY-MM-DD|Formatted Date]]

## Notes
[harvested carry-forward bullets, or bare `- ` if none]
```

File: `Calendar/YYYY-MM-DD [Person Name].md`

After creating the meeting note, mention the harvest in the confirmation summary (e.g., "1 carry-forward item pulled from the Person note").

#### Generic → Meeting

Match icalBuddy attendee names against Person notes in `Contexts/*/People/`. Exclude [Your Name] (self). Wikilink matched names, skip unrecognized ones.

If context can't be determined from calendar source, ask the user.

```markdown
---
type: Meeting
context: "[[Context Name]]"
about:
with:
  - "[[Matched Person 1]]"
  - "[[Matched Person 2]]"
aliases:
  - "Event Title"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# Event Title
[[YYYY-MM-DD|Formatted Date]]

## Notes
-
```

File: `Calendar/YYYY-MM-DD [Event Title].md`

### Link to Daily Note

After creating meeting notes, add them as bullet wikilinks under `## Log` in today's daily note (`Calendar/YYYY-MM-DD.md`). This makes them findable throughout the day; `/daily-note` will reorganize under context headers later.

- If the daily note doesn't exist, create it from template first
- If `## Log` already has content, append below existing bullets
- If `## Log` is just a bare `- `, replace it
- Use aliased wikilinks: `- [[2026-03-12 Project Standup|Project Standup]]`
- Alias = first alias from the meeting note (or event title for generics)

### Confirmation

After creating notes and linking them, confirm with a summary:

```
Created meeting notes:
- Calendar/YYYY-MM-DD Project Standup.md (series)
- Calendar/YYYY-MM-DD Jane Smith.md (1:1)
- Calendar/YYYY-MM-DD Team Sync.md (generic)

Linked to daily note.
```

If the user selected "Other" or no meetings, skip creation silently.
