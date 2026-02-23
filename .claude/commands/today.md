---
description: Morning briefing -- today's meetings, open action items, threads needing attention
---

Morning briefing showing what's on the docket. Separate from `/first-light` (journaling) and `/daily-note` (end-of-day log).

**Prerequisites:**
- `icalBuddy` installed (`brew install ical-buddy`)
- Calendar accounts synced to Apple Calendar via System Settings -> Internet Accounts
- Terminal.app granted Calendar access (Privacy & Security -> Calendars)

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

## 2. Open Action Items

Scan Calendar/ meeting notes for unchecked items. **Search in parallel:**

Issue multiple Grep calls in a single tool-call batch to cover recent calendar files:
- Grep for `- \[ \]` across `Calendar/2026-02-*.md` files (current month)
- Grep for `- \[ \]` across `Calendar/2026-01-*.md` files (prior month, for stale item detection)
- If current month is January, adjust ranges accordingly

Process all results after the batch completes:
- Group by context, then by source meeting
- Show: item text, source meeting name, age in days
- Items older than 14 days: separate "Stale" group with count -- prompt: "Still relevant, or should I close these?"

## 3. Follow-Up Threads

Scan recent Thread notes (last 7 days) for:

- Threads with `## Draft Reply` that haven't been sent (no follow-up Thread note or meeting referencing resolution)
- Threads where the last message was from someone else (potential waiting-for-reply)

Light touch -- just list them with one-line context.

## 4. Yesterday's Unfinished Business

If yesterday's daily note exists, check:

- Any items in the Log that reference "pending", "waiting", "TBD"
- Cross-reference with today's meetings (is a follow-up scheduled?)

## 5. Output & Flow

The briefing is **two sequential workflows**, not one big dump. Present each block, handle its interaction, then move to the next.

### Workflow 1: Meetings -> Note Creation

Present today's meetings, then immediately offer meeting note creation (Section 7). Resolve note creation before moving on.

```
## Today -- Wednesday, February 19

### Meetings
- 10:00 AM -- Project Standup ([Context Name]) -- *series, last: Feb 12*
- 2:00 PM -- Team Sync ([Context Name])
```

-> Meeting note creation prompt (Section 7)
-> Create selected notes
-> Then continue to Workflow 2

### Workflow 2: Open Items & Threads

After meeting notes are handled, present open items, threads, and yesterday's unfinished business.

```
### Open Items (7)
**[Context Name]** (4)
- [ ] Review design proposal -- *Design Review, Feb 18*
- [ ] Send updated requirements -- *Planning Session, Feb 18*
...

**[Context Name]** (3)
- [ ] Schedule follow-up meeting -- *Triage, Feb 17*
...

### Threads Needing Attention
- Vendor discussion -- waiting on reply (3 days)

### Stale (14+ days, 2 items)
1. [ ] Follow up on graphics issue -- *Sync Meeting, Jan 16*
2. [ ] Discuss firmware approach -- *Sync Meeting, Jan 16*

> Triage: respond with number + action for each (e.g., "1: close, 2: keep - still waiting")
```

Output is conversational, not written to any file.

## 6. Stale Item Triage

When stale items exist (14+ days), present them **numbered** and ask the user to batch-respond with all decisions at once. One round trip, not one per item.

**User responds like:**
> 1: close, 2: close - not my item, 3: keep - blocked on review, 4: done, 5: close

**Then process all at once:**
- "close" or "done" -> mark `- [x]` in source note
- "keep" -> leave open, note any context the user added
- If user adds context, no need to ask follow-ups -- just apply

Do NOT step through items one by one. The whole point is speed.

## 7. Meeting Note Creation

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
- Use fuzzy matching: the event title should *contain* the series name or alias
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
modified:
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
modified:
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
modified:
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
