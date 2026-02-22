---
description: Format rough meeting notes into structured meeting note
---

Format rough meeting notes into a structured meeting note, leveraging vault context for accurate linking and interpretation.

**Input:** File path to existing meeting note with frontmatter and rough bullets/outline

## 1. Read & Validate

Read the file at `$ARGUMENTS`. Check frontmatter for required fields:
- `context:` — organizational context
- `with:` — attendees
- `about:` — product/project being discussed

**Ask only if critical fields are empty:**
- Who attended? (if `with:` empty)
- Which context? (if `context:` empty)
- Main subject? (if `about:` empty and unclear from content)

## 2. Gather Context

Follow frontmatter links to build working context:

- **`about:` notes** — Read each linked note for aliases, sub-items, current state
- **`series:` note** — If present, read for recurring meeting context
- **Recent meetings** — Check 2-3 recent meetings in same series or overlapping `about:` topics
- **Open items check:** Scan action items from recent meetings. If current meeting shows a prior action item was completed, mark it `- [x]` in the original note.
- **Recent daily notes** — Scan last few days for related activity

## 3. Entity Search & Frontmatter Enrichment

Search the vault for every notable entity in the raw notes. Resolve informal names to vault notes using aliases and context rules.

**Frontmatter enrichment:**
- **`about:`** — Add discovered projects/products. Only add if a vault note exists.
- **`with:` is read-only.** Never modify.

**Body wikilinks** for entities frontmatter doesn't capture. Anything in frontmatter uses plain text in body. Body wikilinks appear once on first mention, plain text after.

## 4. Format

Preserve existing frontmatter. Fill gaps:
- Add `one-liner:` if empty

Replace raw content with structured output:

```markdown
## Summary
[2-3 sentences: key themes and outcomes]

**Topic A**
- Key point
	- Detail or sub-point

**Topic B**
- Key point

## Action Items
- Task I committed to
- Another task I committed to
```

**Summarization quality:**
- Each `**Topic**` section = one distinct discussion thread
- `## Summary` must not merge threads discussed separately
- Name specific artifacts or data sources. If notes don't name them, don't invent a label.

## 5. Formatting Rules

**Structure:**
- `## Summary` and `## Action Items` are the only H2 headings
- Topic sections use `**bold text**`, not `##` headings

**Action items:**
- Only the vault owner's commitments get checkboxes (`- [ ]`)
- Other people's next steps stay as plain bullets in topic sections
- If no checkboxes in raw notes, omit Action Items section entirely

**Content:**
- Use frontmatter context to interpret ambiguous bullets
- Keep bullets concise
- Preserve all existing frontmatter fields
- Use first person (I/me/my) for the vault owner
