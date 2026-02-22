---
description: Generate status update for projects in a context
---

Generate a status update for projects within a context.

**Input:** $ARGUMENTS
- Required: Context name
- Optional: Time window (default: 1 week)
- Examples: "Marketing", "Engineering 2 weeks", "past month"

**Workflow:**

1. **Parse arguments** — extract context and time window

2. **Find all projects in context** — Portfolio items in the context's Portfolio folder

3. **For each project, gather activity from the time window:**
   - Calendar entries (meetings) with `about:` linking to project
   - Daily notes mentioning the project
   - Recently modified Documents in project folder

4. **Ask format preference** — bullets or paragraph

5. **Generate status update per project:**
   - Focus on: decisions made, progress, blockers, next steps
   - 2-4 bullets OR 2-3 sentences per project
   - Skip projects with no activity
   - Output to terminal for copy/paste

**Output style:**
- Tighter is better — short sentences, just the facts
- Status-focused: what shipped, what's in progress, what's blocked
- No narrative or exposition
