---
description: Process article/video into summarized note with key insights
---

Process a resource (article, video, PDF) into a Reference note:

**Input:** URL or file path to resource

**Workflow:**

1. **Fetch and analyze** the resource:
   - For URLs: clean tracking parameters (utm_*, ref, source), upgrade http to https
   - Use WebFetch to retrieve content
   - For files: Read directly
   - Identify: title, author, date, source type

2. **Search vault** for related content:
   - Check if already captured
   - Find related Documents, Portfolio items, or people
   - Identify which context this belongs to

3. **Extract key insights:**
   - Core argument/thesis (1-2 sentences)
   - Key takeaways (3-5 bullets max)
   - Actionable implications for user's work
   - Notable quotes (1-2 max, only if valuable)

4. **Ask user** to confirm filename and location (default: `Resources/Reference/`)

5. **Read template** from `Resources/Templates/Reference.md`

6. **Create Reference note** with proper frontmatter:
   - Fill in `source-url:`, `source-author:`, `source-date:`
   - Add `topics:`, `related:`, `context:` as appropriate

**Style:**
- Dense summarization — insights, not regurgitation
- Focus on what's actionable
- Link to related vault notes
