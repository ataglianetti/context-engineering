---
description: Generate weekly summary from daily notes
---

Generate a weekly summary synthesizing daily note logs into a consolidated view.

**Arguments:**
- No argument: current week (or most recent completed week if Monday)
- Week specifier: "W05", "2026-W05", "last week"

**1. Determine target week**
- Week runs Monday-Sunday (ISO week)
- Find all daily notes for that week: `Calendar/YYYY-MM-DD.md`

**2. Read daily notes**
- Extract `### Log` section from each
- Track all projects mentioned across the week

**3. Check memory.md for decisions**
- Find entries dated within target week

**4. Synthesize weekly summary**

For each project:
- Consolidate activity into narrative summary (1-2 sentences)
- Don't list individual items; synthesize
- **Synthesis guardrails:** Do not connect unrelated threads. Keep them as separate clauses.
- For code work: fold mapped repos into project summary, use repo name for unmapped

**5. Generate the weekly note**

Path: `Calendar/YYYY-Www.md`

```markdown
---
type: Journal
created: YYYY-MM-DD
week: YYYY-Www
---

# Www | Month DD-DD, YYYY

## Summary

**Context A**
- [[Project]] - Week's arc summary (1-2 sentences)

## Decisions
- Decision text (from memory.md, dated this week)

## Open Items

**Carry-Forward**
- Item — *Source Meeting, Date*

**Completed This Week**
- Item — *Source Meeting, completed Date*
```

Rules:
- Context headers as bold text
- Each project appears once with synthesized summary
- Decisions section only if memory.md has entries from that week
- Open Items from meeting note action item scan (plain bullets, not checkboxes)
