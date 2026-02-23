# File Management

## Soft Walls
- Prefer editing existing notes over creating new ones
- Use clean filenames; folder structure provides context
- Internal codes go in frontmatter `aliases:`
- Current year daily notes in `Calendar/` root; year folders for archives only

## Content Patterns
- Portfolio items: minimal metadata containers
- Real analysis: Documents or Calendar
- Meeting notes: concise bullets
- Meeting topic sections use `**bold text**`, not `##` headings
- `## Summary` and `## Action Items` are the only H2s in meeting content
- Action items: checkboxes (`- [ ]` open, `- [x]` done) live in meeting notes only — meeting notes are the single source of truth. Only the vault owner's commitments get checkboxes; others' next steps stay as plain bullets in topic sections. Daily and weekly notes reference open items as plain text with source links; `/today` surfaces them on demand.
- New notes: do NOT add to daily note (`/daily-note` gathers work at end of day)
- H1 headings: Meeting, Person, Thread, and Document types include H1; other note types skip H1
- Thread replies: when drafting a reply to a Thread note, always write the draft to the note (not just the conversation), even if `/draft-reply` wasn't explicitly invoked

## Proactive Behavior
- Generally proactive, but for code changes: discuss approach before writing
- Suggest rule updates when context seems stale
- Flag blockers and dependencies
