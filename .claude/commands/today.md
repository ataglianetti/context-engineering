---
description: Morning briefing -- today's meetings, open action items, threads needing attention
---

Morning briefing showing what's on the docket. Separate from `/first-light` (journaling) and `/daily-note` (end-of-day log).

**Prerequisites:**
- `icalBuddy` installed (`brew install ical-buddy`)
- Calendar accounts synced to Apple Calendar via System Settings -> Internet Accounts
- Terminal.app granted Calendar access (Privacy & Security -> Calendars)

## 0. Temporal Catch-Up

Before the briefing, check for and generate any missing temporal notes. This makes the daily/weekly/monthly stack self-healing -- no separate catch-up runs needed.

**Run this section silently.** Only surface output if notes were actually generated.

### 0a. Daily note backfill (up to 7 days)

Scan backward from yesterday to 7 days ago. Process oldest-first so weekly synthesis has all daily notes available.

```
For each candidate date (7 days ago -> yesterday, oldest first):
  1. Does Calendar/YYYY-MM-DD.md exist with substantive content in ## Log?
     Skip if Log has 3+ non-empty bullets with real text.
     Treat as missing if Log is absent, empty, or contains only
     placeholder lines (bare `- `, single stub entries). -> skip if substantive
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
  3. If no evidence from any source -> skip (no empty notes for idle days)
  4. If evidence found -> generate daily note using /daily-note logic
     with that specific date as the target argument
```

**Idempotency:** Step 1 prevents re-generating notes that already have content. A daily note is treated as missing if its `## Log` section has fewer than 3 non-empty bullets -- this catches template placeholders (`- `), partial stubs (e.g., a Reminders section exists but Log was never filled), and notes with only 1-2 trivial entries that don't reflect a full day's work.

### 0b. Weekly note catch-up

After daily backfill completes, check for missing weekly notes:

```
For each ISO week that has at least one day in the backfill window
(yesterday through 7 days ago):
  1. Does Calendar/YYYY-Www.md exist with content in ## Summary? -> skip
  2. Count daily notes for that week with populated ### Log sections
     - Need at least 1 populated daily note to generate a meaningful weekly
  3. If yes -> generate weekly note using /weekly-note logic
     with that week's identifier (e.g., "W08", "2026-W08")
```

Process weeks in chronological order.

### 0c. Monthly note catch-up (days 1-5 only)

Only runs if today is day 1-5 of the month:

```
  1. Does Calendar/YYYY-MM.md for last month exist
     with content in ## Work (beyond just context headers)? -> skip
  2. Are there weekly notes for last month? -> generate using /monthly-note logic
     with last month as the target (e.g., "last month", "2026-01")
```

### 0d. Catch-up output

If any notes were generated, show a brief summary before the main briefing:

```
> Catch-up: Generated daily notes for Feb 19, Feb 20. Weekly note for W08.
```

If nothing was missing, emit nothing -- go straight to Section 1.

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
- For series matches, note the last meeting date and any open items from it

## 1.5. Upcoming Milestones

Scan portfolio notes with `product-status: In Development` for flat milestone fields: `milestone:` (name) and `milestone-date:` (ISO date). Calculate days until each milestone relative to today.

**Proximity markers (convention-based, no per-milestone config):**
- `(OVERDUE)` -- date has passed
- `(!!)` -- 14 days or fewer
- `(!)` -- 15-30 days
- Listed, no marker -- 31-60 days
- Not surfaced -- 60+ days out

**Milestone lifecycle:**
- `milestone:` + `milestone-date:` frontmatter is the next upcoming milestone only (flat, Obsidian-editable)
- `## Status` table on the portfolio note is the full historical record
- When a milestone passes: `/today` flags it `(OVERDUE)`. Session close handles cleanup -- mark complete (with actual date) in Status table, advance `milestone:` and `milestone-date:` to the next row from the table, or clear both if no more milestones remain.

**Output (inline in Workflow 1, after meetings):**
```
### Upcoming Milestones
- (!!) Mar 12 -- [Project] Business Commit Presentation ([Context Name])
- (!) Mar 26 -- [Project] Definition Validation ([Context Name])
```

If no milestones are within 60 days, omit this section entirely.

## 1.6. Content Deadlines

Scan Post notes for upcoming `target-date:` values. Posts live in `Contexts/Personal/Content/Posts/` (all subdirectories).

**Query:** Grep for `target-date:` across all Post notes. Parse the ISO date and compare to today.

**Proximity markers (same convention as milestones):**
- `(OVERDUE)` -- date has passed and `post-status:` is not `published`
- `(!!)` -- 14 days or fewer
- `(!)` -- 15-30 days
- Listed, no marker -- 31-60 days
- Not surfaced -- 60+ days out

**Skip:** Posts with `post-status: published` (already shipped, regardless of date).

**Output (inline in Workflow 1, after milestones):**
```
### Content Deadlines
- (!!) Feb 27 -- "Post Title" (Substack, draft)
- (!) Mar 6 -- "Another Post" (Substack, draft)
```

Show the post title (from first alias or filename), platform (from `post-platform:`), and current status (from `post-status:`).

If no content deadlines are within 60 days, omit this section entirely.

---

## 2. Open Items & Threads

Collect all actionable items into a single numbered list for batch triage.

### 2a. Gather open action items

**Primary source: registry.** Read `.claude/registry.md` Action Items table (created on first `/today` run if it doesn't exist). Apply state-based filtering:

| State | Behavior |
|-------|----------|
| `open` | Surface in main list |
| `waiting` | Surface in main list with "(waiting on [person])" annotation |
| `deferred` | Check resurface date -- skip if today < resurface, surface if today >= resurface |
| `blocked` | Collect into separate "Blocked" group |
| `someday` | Skip entirely (weekly review only) |

**Cross-reference with source notes:** For each registry item, verify the checkbox is still `- [ ]` in the source meeting note. If it's been marked `- [x]` outside triage, remove from registry silently.

**Catch new items:** Also grep Calendar/ meeting notes for unchecked `- [ ]` items not yet in the registry (current month + prior month). These surface as `open` with a "(new)" annotation. They get added to the registry during triage processing.

For each item, also check for existing sub-bullets (dated context updates from prior triage). Show the latest update inline if present.

### 2b. Gather threads needing attention

Scan recent Thread notes (last 30 days). Apply filters in order:

**Step 1: Check `tracking:` frontmatter (fastest filter)**
- `tracking: resolved` -> skip
- `tracking: dismissed` -> skip
- `tracking: waiting` -> include, show latest `## Tracking` sub-bullet as line
- `tracking: active` or field absent -> proceed to Step 2

**Step 2: Auto-resolution detection (fallback for untagged threads)**
Before including a thread without explicit `tracking:` state, check if it's been addressed:
- Search meeting notes and daily notes created *after* the thread for wikilinks to the thread note
- If the thread is referenced in a subsequent meeting note or daily note log, it's been discussed -- don't surface it

**Step 3: Attention signals (for threads that pass Steps 1-2)**
Surface if any of:
- Thread contains a message with `DRAFT` in the speaker line (unsent draft reply)
- Last message in `## Thread` was from someone other than the vault owner (potential waiting-for-reply)
- `tracking: waiting` (already included in Step 1)

**Note:** The `tracking:` field is the primary persistence mechanism. Auto-resolution detection (Step 2) is a safety net for threads that were never triaged, not the primary filter. Once a thread goes through triage, its `tracking:` field governs all future scans.

### 2c. Check yesterday's unfinished business

If yesterday's daily note (or most recent daily note with content) exists:
- Items in the Log that reference "pending", "waiting", "TBD"
- Cross-reference with today's meetings (is a follow-up scheduled?)

## 3. Output & Flow

The briefing is **two sequential workflows**, not one big dump. Present each block, handle its interaction, then move to the next.

### Workflow 1: Meetings -> Note Creation

Present today's meetings, then milestones (Section 1.5), then immediately offer meeting note creation (Section 5). Resolve note creation before moving on.

```
## Today -- Wednesday, February 19

### Meetings
- 10:00 AM -- Project Standup ([Context Name]) -- *series, last: Feb 12*
- 2:00 PM -- Team Sync ([Context Name])

### Upcoming Milestones
- (!!) Mar 12 -- [Project] Business Commit ([Context Name])
- (!) Mar 26 -- [Project] Definition Validation ([Context Name])

### Content Deadlines
- (!!) Feb 27 -- "Post Title" (Substack, draft)
```

-> Meeting note creation prompt (Section 5)
-> Create selected notes
-> Then continue to Workflow 2

### Workflow 2: Open Items & Threads (Unified Triage)

After meeting notes are handled, present all actionable items in a single numbered list. Group by context, with threads inline and stale items separated at the bottom.

```
### Open Items & Threads (8)

**[Context Name]**
1. [ ] Relay spec to teammate -- *Standup, Feb 25*
2. [ ] Record demo clips for validation -- *1:1, Feb 25*
3. [ ] Follow up on naming candidates -- *1:1, Feb 25*

**[Context Name]**
4. ~thread~ Vendor Discussion -- competitor examples (6d)
5. ~thread/waiting~ Partner Demo -- email sent, awaiting reply (4d)
   > Feb 25: meeting scheduled for Tue March 3

**Blocked**
6. [ ] Update PRD: parameter ranges -- waiting on teammate (Session, Feb 25)

**Stale (14+ days)**
7. [ ] Reach out re: graphics caveat -- *Sync, Jan 16* (34d)

> 2 items deferred (next resurface: Mar 10)
> 0 items someday

> Triage: "1: done, 3: defer march 26, 5: waiting - demo scheduled, 6: waiting john, 7: close"
> Items not mentioned stay as-is.
```

**Numbering:** Continuous across all groups. Items with existing context updates show the latest sub-bullet so the user has full state before deciding.

**Output is conversational, not written to any file.**

## 4. Triage Processing

The user batch-responds with all decisions in one message. Process all at once -- do NOT step through items one by one.

### Action vocabulary

| Response | What happens |
|----------|-------------|
| `done` | Mark `- [x]` in source meeting note. Remove from registry. |
| `close` | Mark `- [x]` in source meeting note. Remove from registry. |
| `close - reason` | Mark `- [x]`, append reason as dated sub-bullet. Remove from registry. |
| `defer <date>` | Set state=deferred + resurface date in registry. Hidden until that date. |
| `defer <date> - reason` | Same + reason in Detail column. |
| `waiting <person>` | Set state=waiting + person in Detail column. Surfaces daily with staleness. |
| `blocked - reason` | Set state=blocked + reason in Detail column. Surfaces in "Blocked" group. |
| `someday` | Set state=someday. Hidden from daily briefing, visible in weekly review only. |
| Any other text | Leave `- [ ]`, append dated context update as sub-bullet in source note. Keep current registry state. |
| *(not mentioned)* | No change. |

**Date parsing for `defer`:** Accept natural date formats: `march 15`, `3/15`, `2 weeks`, `next monday`, `1 month`. Resolve to ISO date (YYYY-MM-DD) in registry.

**Registry sync:** Items found in grep but not yet in registry get added as `open` during triage. This keeps the registry growing naturally without a separate "add" step.

Anything that isn't a recognized keyword (`done`, `close`, `defer`, `waiting`, `blocked`, `someday`) is treated as a context update.

### Context update format

Append a dated sub-bullet directly below the action item in the **source meeting note**:

```markdown
- [ ] Send normalized parameter mappings to teammate
  - *Feb 23: discussed in 1:1, needs additional column first*
```

Next time `/today` surfaces this item, the latest update appears as a sub-bullet so the user sees current state without having to open the source note.

### Thread triage

Threads persist to the **thread note itself** (not a meeting note). Every triage decision writes to the vault.

| Response | What happens |
|----------|-------------|
| `done` / `close` | Set `tracking: resolved` in thread note frontmatter |
| `close - reason` | Set `tracking: resolved` + append dated sub-bullet to `## Tracking` |
| `dismiss` | Set `tracking: dismissed` in thread note frontmatter |
| `waiting` or `waiting - context` | Set `tracking: waiting` + append dated sub-bullet to `## Tracking` |
| Any other text | Append dated sub-bullet to `## Tracking` (keep current `tracking:` value, or set `active`) |
| *(not mentioned)* | No change |

### Thread tracking section format

If the thread note doesn't have a `## Tracking` section yet, create one after `## Summary` (before `## Key Points` or `## Thread`):

```markdown
## Tracking
- *Feb 25: meeting scheduled for Tue March 3*
- *Feb 27: demo went well, wants a follow-up proposal*
```

Next time `/today` surfaces this thread, the latest entry appears as a sub-bullet -- same pattern as action items.

### Thread tracking field

Add `tracking:` to frontmatter only on first triage (not on thread creation). Values:

| Value | Meaning | `/today` behavior |
|-------|---------|-------------------|
| *(absent)* | Never triaged | Apply auto-detection (Step 2-3 in 2b) |
| `active` | Actively needs attention | Always surface |
| `waiting` | Ball in someone else's court | Surface with latest context |
| `resolved` | Done, no more action | Skip |
| `dismissed` | User doesn't want to track | Skip |

## 5. Meeting Note Creation

Runs as part of Workflow 1 (after meeting list, before open items).

### Filter Events

From the icalBuddy output, **exclude** events that aren't real meetings:
- All-day events without attendees (e.g., "PAYDAY", holidays)
- Events titled "Focus Time", "Lunch", or similar blocks
- Cancelled events

### Present Selection

Use `AskUserQuestion` with `multiSelect: true`. Each option:
- **Label:** `HH:MM AM -- Event Title`
- **Description:** Context + classification hint (e.g., "Series: Project Standup", "1:1", or "New meeting")

Before presenting, check which meetings already have notes. If `Calendar/YYYY-MM-DD [Expected Name].md` exists, exclude it from the options and note it:
> Already have notes for: Project Standup

If ALL meetings already have notes, skip the question entirely:
> All meeting notes already exist for today.

### Classify Each Selected Meeting

For each selected meeting, classify in priority order:

**1. Series Match**
Match the calendar event title against Meeting Series notes in `Calendar/`:
- Compare against the Meeting Series note's **filename** (basename) and **`aliases:`** entries
- Use bidirectional fuzzy matching (case-insensitive): the event title *contains* a series name/alias, OR a series name/alias *contains* the event title. Also strip common prefixes before comparing: year prefixes ("2026 ", "2025 "), frequency words ("Bi-weekly ", "Weekly ", "Monthly ")
- Calendar event titles often differ from vault series names (e.g., "2026 Bi-weekly Products team meeting" -> "Product Team"). Add known calendar titles as `aliases:` on the Meeting Series note so they match directly
- If matched -> **Meeting Occurrence** type

**2. 1:1 Detection**
If icalBuddy shows exactly 2 attendees and one is [Your Name] (or the user's email):
- The other attendee is the 1:1 partner
- Match their name against Person notes in `Contexts/*/People/`
- If matched -> **Meeting (1-1)** type

**3. Generic Meeting**
Everything else -> **Generic Meeting** type. Ask user for context if calendar source is ambiguous.

### Create Notes

#### Series Match -> Meeting Occurrence

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
cssclasses:
---

# [First alias from series]
[[YYYY-MM-DD|Formatted Date]]

## Notes
-
```

File: `Calendar/YYYY-MM-DD [Series Note Filename].md`

#### 1:1 -> Meeting (1-1)

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
cssclasses:
---

# 1:1 with [Person Name]
[[YYYY-MM-DD|Formatted Date]]

## Notes
-
```

File: `Calendar/YYYY-MM-DD [Person Name].md`

#### Generic -> Meeting

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
cssclasses:
---

# Event Title
[[YYYY-MM-DD|Formatted Date]]

## Notes
-
```

File: `Calendar/YYYY-MM-DD [Event Title].md`

### Confirmation

After creating notes, confirm with a summary:

```
Created meeting notes:
- Calendar/2026-02-19 Project Standup.md (series)
- Calendar/2026-02-19 Jane Smith.md (1:1)
- Calendar/2026-02-19 Team Sync.md (generic)
```

If the user selected "Other" or no meetings, skip creation silently.
