---
description: Generate weekly summary from daily notes
---

Generate a weekly summary synthesizing daily note logs into a consolidated view.

**Arguments:**
- No argument: current week (or most recent completed week if run on Monday)
- Week specifier: "W05", "2026-W05", "last week", "W06"

**1. Determine target week**
- Parse the argument (if provided) to determine which week
- Week runs Monday-Sunday (ISO week)
- Find all daily notes for that week: `Calendar/YYYY-MM-DD.md`

**2. Read daily notes**

For each daily note in the target week:
- Read the `### Log` section
- Extract project groupings and their nested items
- Track all projects mentioned across the week

**3. Check memory.md for decisions**

Read `.claude/rules/core/memory.md`:
- Find entries in "Recent Decisions" table dated within the target week
- These will populate the Decisions section

**4. Synthesize weekly summary**

For each project that appeared in any daily note:
- Consolidate all activity into a single narrative summary
- Capture: what happened, what decisions were made, what moved forward
- Don't list individual items; synthesize into coherent description
- **Synthesis guardrails:** Do not connect projects or events that daily notes did not explicitly connect. If a project had multiple unrelated threads during the week, keep them as separate clauses -- not a unified narrative arc.

For code work:
- If repo is mapped to a vault project, fold into that project's summary
- If unmapped, use `Code: repo-name` format

**5. Generate the weekly note**

Path: `Calendar/YYYY-Www.md` (e.g., `Calendar/2026-W06.md`)

Format:
```markdown
---
type: Journal
created: YYYY-MM-DD
week: YYYY-Www
---

# Www | Month DD-DD, YYYY

## Summary

**[Context Name]**
- [[Project A]] - Week's arc summary (1-2 sentences)
- [[Project B]] - Summary

**[Context Name]**
- [[Project C]] - Summary

**Personal**
- [[Project D]] - Summary
- repo-name - Summary of unmapped repo activity

## Decisions
- Decision text (from memory.md, dated this week)

## Open Items

**Carry-Forward** (still open at end of week)

**[Context Name]**
- Item -- *Source Meeting, Date*

**[Context Name]**
- Item -- *Source Meeting, Date*

**Completed This Week**
- Item -- *Source Meeting, completed Date*
```

Rules:
- **Context headers:** Bold text (`**[Context Name]**`)
- **Whitespace:** Blank line between context groups only
- Each project appears exactly once with a synthesized summary
- Summaries: 1-2 sentences capturing the week's arc for that project
- Consolidate daily entries into narrative (don't list each day)
- Commits fold into project summary if repo is mapped
- Unmapped repos appear under appropriate context by repo name (no "Code:" prefix)
- Decisions section only appears if memory.md has entries from that week
- **Open Items section:** Scan all Calendar/ meeting notes from the week for open and completed action items. List as plain bullets with source links (not checkboxes -- meeting notes are the single source of truth for checkbox state). Carry-forward = still open at week end. Completed = marked done during the week. Group by context. Omit section if no items.
- No "Other" category (insignificant items drop at weekly level)
- Date range in H1 shows the Monday-Sunday span

**6. Output**

Show the generated weekly note. Confirm:
- Number of daily notes processed
- Date range covered
- Number of projects summarized
- Whether decisions were included
