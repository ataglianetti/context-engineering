---
description: Process article/video into summarized note with key insights
---

Process a resource (article, video, PDF) into a Reference note:

**Input:** URL or file path to resource

**Workflow:**

1. **Fetch and analyze** the resource:
   - For URLs: clean tracking parameters first (utm_*, ref, source, etc.), upgrade http -> https
   - Use WebFetch to retrieve content
   - For files: Read the file directly
   - Identify: title, author, date, source type

2. **Search vault** for related content:
   - Check if resource already captured
   - Find related Documents, Portfolio items, or people
   - Identify which context this belongs to (or vault-wide)

3. **Extract key insights:**
   - Core argument/thesis (1-2 sentences)
   - Key takeaways (3-5 bullets max)
   - Actionable implications for user's work
   - Notable quotes (1-2 max, only if valuable)

4. **Ask user** to confirm:
   - Suggest filename based on content
   - Default location: `Resources/Reference/`
   - Confirm before creating

5. **Use the Reference frontmatter contract** in `rules/vault/vault-structure.md`

6. **Create Reference note** with template frontmatter:
   - Fill in `source-url:`, `source-author:`, `source-date:` from resource
   - Add `topics:` based on content themes
   - Add `related:` links to vault notes found in step 2
   - Set `context:` if clearly tied to one (otherwise omit)

**Style:**
- Dense summarization - insights, not regurgitation
- Focus on what's actionable for user's work
- Link to related vault notes where relevant
- No fluff - capture essence only
