---
description: Generate weekly status update for all projects in a context
---

Generate a status update for projects within a context.

**Input:** $ARGUMENTS
- Required: Context name
- Optional: Time window (default: 1 week)
- Examples: "Work", "Side Projects 2 weeks", "Work past month"

**Workflow:**

1. **Parse arguments:**
   - Extract context name
   - Extract time window if specified, otherwise default to 1 week
   - Calculate date range

2. **Find all projects in context:**
   - Scan Portfolio folder for the specified context

3. **For each project, gather activity from the time window:**
   - Calendar entries (meetings, working sessions) with `about:` linking to project
   - Daily notes mentioning the project
   - Recently modified Documents in project folder
   - Work item status changes (completed, started, blocked)

4. **Ask user format preference:**
   - Bullets or paragraph?

5. **Generate status update per project:**
   - Focus on: decisions made, progress, blockers, next steps
   - Keep concise: 2-4 bullets OR 2-3 sentences per project
   - Skip projects with no activity in the time window
   - Output directly to terminal for user to copy/paste

**Output style:**
- Tighter is better -- short sentences, just the facts
- Status-focused: what shipped, what's in progress, what's blocked
- No narrative or exposition -- details live in project notes
- Split distinct features even if they ship together
- Use "post-launch refinements identified" instead of listing them
- Skip background work, infrastructure issues, or items on hold unless user asks

**Example (paragraph style):**
> **Feature A:** Feature complete and deployed to lower environment, with release scheduled for next week. Steering committee identified post-launch refinements.
>
> **Feature B:** Feature complete and deployed to lower environment, with release scheduled for next week. Product eval confirmed implementation matches spec. Demo with steering committee revealed post-launch refinements.
>
> **Feature C:** Search API work is complete, waiting on final design comps. Will review with stakeholders next week.
