---
description: Format rough meeting notes into structured meeting note
---

Format rough meeting notes into a structured meeting note, leveraging vault context for accurate linking and interpretation.

**Input:** File path to existing meeting note with frontmatter and rough bullets/outline

## 1. Read & Validate

Read the file at `$ARGUMENTS`. Check frontmatter for required fields:
- `context:` -> organizational context
- `with:` -> attendees
- `about:` -> product/project being discussed

**Ask only if critical fields are empty:**
- Who attended? (if `with:` empty)
- Which context? (if `context:` empty)
- Main subject? (if `about:` empty and unclear from content)

## 2. Gather Context

Per document-traversal, follow frontmatter links to build working context. **Maximize parallel reads:**

**Batch 1 (all in parallel -- no dependencies between these):**
- Read each note in `about:` frontmatter (aliases, sub-items, current state)
- Read the `series:` note if present (recurring meeting context, typical attendees, standing topics)
- Glob for recent meetings matching series or `about:` topics: `Calendar/2026-*.md`
- Read last 3 daily notes from `Calendar/`

**Batch 2 (after Batch 1 completes -- uses Glob results):**
- Read 2-3 most recent meetings from Glob results for continuing discussions
- **Open items check:** Scan action items from those recent meetings. If the current meeting's content shows a prior action item was completed (e.g., "I sent the mappings"), mark it `- [x]` in the original note and mention what was resolved.

This context informs: interpreting shorthand, linking to prior discussions, identifying entities that appear in the raw notes.

## 3. Entity Search & Frontmatter Enrichment

Before formatting, search the vault for every notable entity in the raw notes. Resolve informal names (spoken shorthand, codes, abbreviations) to vault notes using aliases and context rules (e.g., spoken shorthand to vault note aliases).

**Frontmatter enrichment:**
- **`about:`** -> Add discovered products/projects. Keep the parent (e.g., parent project) and add specific items alongside it (e.g., parent project and specific sub-items). Only add if a vault note exists.
- **`with:` is read-only.** Attendees are set before this command runs. Never modify.

**Body wikilinks are the fallback** for entities frontmatter doesn't capture:
- A person mentioned who wasn't an attendee -- determine *why* they're mentioned. If referenced because of a prior meeting or conversation, link to that meeting/thread note, not the person. If referenced independently (e.g., "we should loop in them"), wikilink the person once on first mention.
- A prior meeting or thread referenced for context -> link to that note
- Any other entity not covered by frontmatter fields

Per wikilink discipline: anything in frontmatter uses plain text in body. Body wikilinks appear once on first mention, plain text after.

## 4. Format

Preserve existing frontmatter. Fill gaps:
- Add `one-liner:` if empty (brief meeting purpose)
- `about:` should already be enriched from step 3

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

**Summarization quality** (see `rules/vault/summarization.md`):
- Each `**Topic**` section maps to one distinct discussion thread. Two concerns about the same product = two sections.
- `## Summary` must not merge threads that were discussed separately.
- Name specific artifacts or data sources from the raw notes. If the notes don't name them, don't invent a label.

## 5. Formatting Rules

**Structure:**
- `## Summary` and `## Action Items` are the only H2 headings
- Topic sections use `**bold text**`, not `##` headings
- Collapse over-categorized headings from transcription tools into fewer, tighter groupings

**Action items:**
- Keep action items as checkboxes (`- [ ]`). Only the vault owner's commitments get checkboxes -- other people's next steps stay as plain bullets in topic sections.
- Signaled by checkboxes (`- [ ]`) in raw notes
- Only extract items where the user committed to doing something
- Other people's work/next steps stay in relevant topic sections
- If no checkboxes in raw notes, omit Action Items section entirely

**Content:**
- Use frontmatter context to interpret ambiguous bullets
- Keep bullets concise
- Group related points under clear topic sections
- Preserve all existing frontmatter fields
- Use first person (I/me/my) for the vault owner -- never the vault owner's name in third person. These are my notes.
