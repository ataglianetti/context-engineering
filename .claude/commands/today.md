---
description: Morning briefing — today's meetings, open action items, threads needing attention
---

Morning briefing showing what's on the docket. Separate from `/first-light` (journaling) and `/daily-note` (end-of-day log).

**Prerequisites:**
- `icalBuddy` installed (`brew install ical-buddy`)
- Terminal.app granted Calendar access (Privacy & Security — Calendars)

## 1. Today's Meetings

Run icalBuddy via Terminal.app:
```bash
osascript -e 'tell application "Terminal" to do script "icalBuddy -f eventsToday > /tmp/icalbuddy-output.txt 2>&1"'
sleep 3
cat /tmp/icalbuddy-output.txt
```

- Show time, title, calendar source
- Flag meetings with vault series notes (match title against `series:` in Calendar/)
- For series matches, note last meeting date and open items

## 2. Open Action Items

Scan Calendar/ meeting notes for unchecked items:
- Grep for `- \[ \]` across recent meeting notes
- Group by context, then by source meeting
- Show: item text, source meeting, age in days
- Items older than 14 days: separate "Stale" group

## 3. Follow-Up Threads

Scan recent Thread notes (last 7 days) for:
- Threads with draft replies not yet sent
- Threads where last message was from someone else

## 4. Yesterday's Unfinished Business

If yesterday's daily note exists, check for pending/waiting/TBD items and cross-reference with today's meetings.

## 5. Output Format

Present as a clean briefing (not written to vault):

```
## Today — Day, Month DD

### Meetings
- 10:00 AM — Meeting Title (Context) — *N open items from last session*

### Open Items (N)
**Context A** (N)
- [ ] Item description — *Source Meeting, Date*

### Threads Needing Attention
- Thread subject — waiting on reply (N days)

### Stale (14+ days, N items)
1. [ ] Item — *Source, Date*
> Triage: respond with number + action (e.g., "1: close, 2: keep")
```

## 6. Stale Item Triage

Present stale items numbered. Ask user to batch-respond. Process all at once:
- "close"/"done" — mark `- [x]` in source note
- "keep" — leave open
Do NOT step through items one by one.

## 7. Meeting Note Creation

After briefing, offer to create meeting notes for today's meetings.

**Filter:** Exclude all-day events without attendees, focus/lunch blocks, cancelled events.

**Present selection:** multiSelect with time, title, context, and classification hint.

**Classify each selected meeting:**
1. **Series Match** — match calendar title against Meeting Series notes (filename + aliases). Fuzzy matching. — Meeting Occurrence type
2. **1:1 Detection** — exactly 2 attendees — match against Person notes — Meeting (1-1) type
3. **Generic Meeting** — everything else

**Create notes using appropriate template patterns** (series inherits frontmatter from series note, 1:1 from person note, generic from user input).
