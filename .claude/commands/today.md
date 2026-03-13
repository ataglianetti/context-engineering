---
description: Morning briefing — today's meetings, milestones, reminders
---

Morning briefing showing what's on the docket. Separate from `/first-light` (journaling) and `/daily-note` (end-of-day log).

**Prerequisites:**
- `icalBuddy` installed (`brew install ical-buddy`)
- Calendar accounts synced to Apple Calendar via System Settings → Internet Accounts
- Terminal.app granted Calendar access (Privacy & Security → Calendars)

## 0. Temporal Catch-Up (Background)

Check for and generate missing temporal notes. This runs **in parallel with the main briefing** using background agents — it should never delay the calendar review.

### Execution

1. **Launch a background agent** (via Agent tool with `run_in_background: true`) to handle all catch-up work:
   - Daily note backfill (0a)
   - Weekly note catch-up (0b)
   - Monthly note catch-up (0c)
2. **Proceed immediately** to Section 1 (Today's Meetings) without waiting
3. When the background agent completes, append its output summary to the conversation

### 0a. Daily note backfill (up to 7 days)

Scan backward from yesterday to 7 days ago. Process oldest-first so weekly synthesis has all daily notes available.

```
For each candidate date (7 days ago → yesterday, oldest first):
  1. Does Calendar/YYYY-MM-DD.md exist with substantive content in ## Log?
     Skip if Log has 3+ non-empty bullets with real text.
     Treat as missing if Log is absent, empty, or contains only
     placeholder lines (bare `- `, single stub entries). → skip if substantive
  2. Check for work evidence on that date:
     a. GitHub commits:
        GH_USER=$(gh api user --jq '.login')
        gh api "search/commits?q=author:${GH_USER}+committer-date:YYYY-MM-DD" \
          --header "Accept: application/vnd.github.cloak-preview+json" \
          --jq '.total_count'
     b. Calendar/ notes: glob Calendar/YYYY-MM-DD*.md
        (meetings, threads created on that date)
     c. Contexts/ commits:
        git -C [vault-path]/Contexts log \
          --since="YYYY-MM-DD" --until="YYYY-MM-DD+1day" --oneline
  3. If no evidence from any source → skip (no empty notes for idle days)
  4. If evidence found → generate daily note using /daily-note logic
     with that specific date as the target argument
```

**Idempotency:** Step 1 prevents re-generating notes that already have content. A daily note is treated as missing if its `## Log` section has fewer than 3 non-empty bullets -- this catches template placeholders (`- `), partial stubs (e.g., a Reminders section exists but Log was never filled), and notes with only 1-2 trivial entries that don't reflect a full day's work.

### 0b. Weekly note catch-up

After daily backfill completes, check for missing weekly notes:

```
For each ISO week that has at least one day in the backfill window
(yesterday through 7 days ago):
  1. Does Calendar/YYYY-Www.md exist with content in ## Summary? → skip
  2. Count daily notes for that week with populated ### Log sections
     - Need at least 1 populated daily note to generate a meaningful weekly
  3. If yes → generate weekly note using /weekly-note logic
     with that week's identifier (e.g., "W08", "2026-W08")
```

Process weeks in chronological order.

### 0c. Monthly note catch-up (days 1-5 only)

Only runs if today is day 1-5 of the month:

```
  1. Does Calendar/YYYY-MM.md for last month exist
     with content in ## Work (beyond just context headers)? → skip
  2. Are there weekly notes for last month? → generate using /monthly-note logic
     with last month as the target (e.g., "last month", "2026-01")
```

### 0d. Agent output

The background agent should return a brief summary of what it generated. The orchestrator appends this to the conversation when the agent completes:

```
> Catch-up: Generated daily notes for Feb 19, Feb 20. Weekly note for W08.
```

If the agent found nothing to generate, it returns nothing and the orchestrator emits no output.

---

## 1. Today's Meetings

Run icalBuddy via Terminal.app (Cursor doesn't have Calendar TCC permission):
```bash
osascript -e 'tell application "Terminal" to do script "icalBuddy -f eventsToday > /tmp/icalbuddy-output.txt 2>&1"'
sleep 3
cat /tmp/icalbuddy-output.txt
```

- Show time, title, calendar source (to distinguish contexts)
- Flag meetings that have vault series notes (match title against `series:` frontmatter in Calendar/)
- For series matches, note the last meeting date

## 1.5. Upcoming Milestones

Scan portfolio notes with `product-status: In Development` for flat milestone fields: `milestone:` (name) and `milestone-date:` (ISO date). Calculate days until each milestone relative to today.

**Proximity markers (convention-based, no per-milestone config):**
- `(OVERDUE)` — date has passed
- `(!!)` — 14 days or fewer
- `(!)` — 15-30 days
- Listed, no marker — 31-60 days
- Not surfaced — 60+ days out

**Milestone lifecycle:**
- `milestone:` + `milestone-date:` frontmatter is the next upcoming milestone only (flat, Obsidian-editable)
- `## Status` table on the portfolio note is the full historical record
- When a milestone passes: `/today` flags it `(OVERDUE)`. Session close handles cleanup — mark complete (with actual date) in Status table, advance `milestone:` and `milestone-date:` to the next row from the table, or clear both if no more milestones remain.

**Output (inline in Workflow 1, after meetings):**
```
### Upcoming Milestones
- (!!) Mar 12 — [Project] Business Commit Presentation ([Context Name])
- (!) Mar 26 — [Project] Definition Validation ([Context Name])
```

If no milestones are within 60 days, omit this section entirely.

## 1.6. Content Deadlines

Scan Post notes for upcoming `target-date:` values. Posts live in `Contexts/Personal/Content/Posts/` (all subdirectories).

**Query:** Grep for `target-date:` across all Post notes. Parse the ISO date and compare to today.

**Proximity markers (same convention as milestones):**
- `(OVERDUE)` — date has passed and `post-status:` is not `published`
- `(!!)` — 14 days or fewer
- `(!)` — 15-30 days
- Listed, no marker — 31-60 days
- Not surfaced — 60+ days out

**Skip:** Posts with `post-status: published` (already shipped, regardless of date).

**Output (inline in Workflow 1, after milestones):**
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

---

## 3. Output & Flow

The briefing is **two sequential workflows**. Present each block, handle its interaction, then move to the next.

### Workflow 1: Meetings + Milestones + Deadlines → Note Creation

Present today's meetings, milestones (Section 1.5), content deadlines (Section 1.6), then immediately offer meeting note creation (Section 4). Resolve note creation before moving on.

```
## Today — Wednesday, March 5

### Meetings
- 10:00 AM — [Series Name] Standup ([Context Name]) — *series, last: Feb 26*
- 2:00 PM — Team Sync ([Context Name])

### Upcoming Milestones
- (!!) Mar 12 — [Project] Business Commit Presentation ([Context Name])
- (!) Mar 26 — [Project] Definition Validation ([Context Name])

### Content Deadlines
- (OVERDUE) Feb 27 — "Post Title" (Substack, draft)
```

→ Meeting note creation prompt (Section 4)
→ Create selected notes
→ Then continue to Workflow 2

### Workflow 2: Reminders

After meeting notes are handled, present due reminders (Section 2) if any exist.

```
### Reminders (1)
1. Prepare panel contribution — [[YYYY-MM-DD Meeting Source]]

> Triage: "1: push march 17" or "1: done"
```

**Output is conversational, not written to any file.**

---

## 4. Meeting Note Creation

Runs as part of Workflow 1 (after meeting list, before reminders).

### Filter Events

From the icalBuddy output, **exclude** events that aren't real meetings:
- All-day events without attendees (e.g., "PAYDAY", holidays)
- Events titled "Focus Time", "Lunch", or similar blocks
- Cancelled events

### Present Selection

Use `AskUserQuestion` with `multiSelect: true`. Each option:
- **Label:** `HH:MM AM — Event Title`
- **Description:** Context + classification hint (e.g., "Series: [Series Name] Standup", "1:1", or "New meeting")

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
-
```

File: `Calendar/YYYY-MM-DD [Person Name].md`

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
