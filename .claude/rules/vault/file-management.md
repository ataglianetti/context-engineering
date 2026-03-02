# File Management

## Soft Walls
- Prefer editing existing notes over creating new ones
- Use clean filenames; folder structure provides context
- Internal codes go in frontmatter `aliases:`
- Current year daily notes in `Calendar/` root; year folders for archives only

## Portfolio Structure
- Portfolio items use the folder pattern (`ItemName/ItemName.md + Documents/`) when the org is tracking them -- meaning they have a roadmap or financial ticket in `external:`
- Items without tracked tickets stay as flat .md files -- they're ideas, bug fixes, or enhancements to shipped features
- When an item gets its first tracked ticket, promote it to a folder and create the Documents/ subfolder
- Shipped features with active sub-work keep their existing structure -- the sub-items handle their own folder promotion independently

## Content Patterns
- Portfolio items: minimal metadata containers
- Real analysis: Documents or Calendar
- Meeting notes: concise bullets
- Meeting topic sections use `**bold text**`, not `##` headings
- `## Summary` and `## Action Items` are the only H2s in meeting content
- Key Signals and topic sections are complementary, not overlapping — signals cover decisions (one-liner), status shifts, and topics NOT expanded in topic sections below. If a signal duplicates a topic section's first bullet, rewrite or remove it.
- Action items: checkboxes (`- [ ]` open, `- [x]` done) live in meeting notes only — meeting notes are the single source of truth. Only the vault owner's commitments get checkboxes; others' next steps stay as plain bullets in topic sections. Daily and weekly notes reference open items as plain text with source links; `/today` surfaces them on demand.
- New notes: do NOT add to daily note (`/daily-note` gathers work at end of day)
- Monthly note Highlights: user-authored only, never auto-generated or modified by commands
- H1 headings: Meeting, Person, Thread, and Document types include H1; other note types skip H1
- Thread replies: when drafting a reply to a Thread note, always write the draft to the note (not just the conversation), even if `/draft-reply` wasn't explicitly invoked

## Proactive Behavior
- Generally proactive, but for code changes: discuss approach before writing
- Suggest rule updates when context seems stale
- Flag blockers and dependencies
