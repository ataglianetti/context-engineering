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
- **Synthesis guardrails:** Do not connect projects or events that daily notes did not explicitly connect. If a project had multiple unrelated threads during the week, keep them as separate clauses — not a unified narrative arc.

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

**[Context Name]**
- [[Project D]] - Summary
- repo-name - Summary of unmapped repo activity

## Decisions
- Decision text (from memory.md, dated this week)

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
- No "Other" category (insignificant items drop at weekly level)
- Date range in H1 shows the Monday-Sunday span

**6. Link to monthly note**

Check if a monthly note exists for the month containing this week's Monday:
- Look for `Calendar/YYYY-MM.md` (e.g., `Calendar/2026-02.md`)
- If it exists, prepend the monthly link to the H1:
  - `# W06 | February 3-9, 2026` → `# [[2026-02|Feb]] W06 | February 3-9, 2026`
- If it doesn't exist, leave the H1 as-is (no orphan links)

**7. Output**

Show the generated weekly note. Confirm:
- Number of daily notes processed
- Date range covered
- Number of projects summarized
- Whether decisions were included
- Whether monthly note link was added
