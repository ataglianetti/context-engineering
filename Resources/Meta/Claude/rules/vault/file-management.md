# File Management

## Soft Walls
- Prefer editing existing notes over creating new ones
- Use clean filenames; folder structure provides context
- Internal codes go in frontmatter `aliases:`
- Current year daily notes in `Calendar/` root; year folders for archives only

## Portfolio Structure
- Portfolio items use the folder pattern (`ItemName/ItemName.md + Documents/`) when the org is tracking them — meaning they have a roadmap or tracking ticket in `external:`
- Items without roadmap/tracking tickets stay as flat .md files — they're ideas, bug fixes, or enhancements to shipped features
- When an item gets its first roadmap or tracking ticket, promote it to a folder and create the Documents/ subfolder
- Shipped features with active sub-work keep their existing structure — the sub-items handle their own folder promotion independently

## Content Patterns
- Portfolio items: minimal metadata containers
- Real analysis: Documents or Calendar
- Meeting notes: concise bullets. Target 10-30 lines of content.
- Meeting format: `## Summary` (2-3 sentences) → flat bullet list (decisions, status changes, new info, commitments — ordered by importance) → `**Topic**` sections only when a subject needs 3+ related bullets that would be confusing as flat items. Most meetings won't need topic sections.
- `## Summary` is the only H2 in meeting content (besides `## Notes` for raw capture)
- Topic sections use `**bold text**`, not `##` headings
- Next steps in meeting notes are **plain-text bullets**, not checkboxes. They're part of the historical record, not a task system. Only the vault owner's commitments are listed; others' next steps stay in topic sections. Format: `**Next Steps**` bold heading with plain bullets underneath.
- Reminders: when a next step genuinely needs a future nudge (deferred work, follow-up on a specific date), add it to `.claude/reminders.md` with a date and source link. Most next steps don't need this — only items that would otherwise be forgotten.
- New notes: do NOT add to daily note (`/daily-note` gathers work at end of day)
- Monthly note Highlights: user-authored only, never auto-generated or modified by commands
- H1 headings: Meeting, Person, Thread, and Document types include H1; other note types skip H1
- Thread replies: when drafting a reply to a Thread note, always write the draft to the note (not just the conversation), even if `/draft-reply` wasn't explicitly invoked

## Proactive Behavior
- Generally proactive, but for code changes: discuss approach before writing
- Suggest rule updates when context seems stale
- Flag blockers and dependencies
