---
description: Format rough meeting notes into structured meeting note
---

Format rough meeting notes into a structured meeting note, leveraging vault context for accurate linking and interpretation. Uses the meeting-processor agent for parsing and formatting.

**Input:** File path to existing meeting note with frontmatter and rough bullets/outline

**Target:** 3-5 minutes, ~30-50 line notes, scannable output, minimal post-editing.

## 1. Read & Validate

Read the file at `$ARGUMENTS`. Check frontmatter for required fields:
- `context:` -- organizational context
- `with:` -- attendees
- `about:` -- product/project being discussed

**Ask only if critical fields are empty:**
- Who attended? (if `with:` empty)
- Which context? (if `context:` empty)
- Main subject? (if `about:` empty and unclear from content)

Save the raw note body and all frontmatter values.

## 2. Gather Context

Per document-traversal, follow frontmatter links to build working context. **Maximize parallel reads:**

**Batch 1 (all in parallel -- no dependencies between these):**
- Read each Person note in `with:` -- aliases, title, discipline, teams
- Read each note in `about:` frontmatter (aliases, sub-items, current state)
- Read the `series:` note if present (recurring meeting context, typical attendees, standing topics)
- Glob for recent meetings matching series or `about:` topics: `Calendar/2026-*.md`
- Read last 3 daily notes from `Calendar/`

**Batch 2 (after Batch 1 completes -- uses Glob results):**
- Read 2-3 most recent meetings from Glob results for continuing discussions
- **Open items check:** Scan action items from those recent meetings. If the current meeting's content shows a prior action item was completed, mark it `- [x]` in the original note and mention what was resolved.

**Assemble lightweight context:**
```
=== ATTENDEE ALIASES ===
[Name]: [alias1, alias2]

=== SHORTHAND MAP ===
[spoken shorthand] -> [full vault name]

=== PRIOR MEETING ===
Meeting: [name] (YYYY-MM-DD)
Open Items: [unchecked action items]
```

## 3. Spawn Agent

Spawn a meeting-processor agent via **Task tool** (Sonnet):

```
Read the agent instructions at Resources/Templates/Agents/meeting-processor.md, then process this meeting.

[Context Bundle from Step 2]

=== RAW NOTES ===
[raw note content from the file]
```

Use the **Task tool** with `subagent_type: "general-purpose"`, `model: "sonnet"`.

The agent returns structured output with `=== SECTION ===` delimiters.

**Fallback:** If the agent fails or returns malformed output, process the notes in-context using the same logic. Don't fail -- degrade gracefully. If the user has no transcript and no vault notes, there's nothing to process -- ask what they remember.

## 4. Post-Process Agent Output

Parse the agent's structured sections and apply vault-specific enrichment.

### 4a. Entity Resolution

Map shorthand to vault names using alias maps from the context bundle. Search vault for any entities not in the shorthand map -- resolve per wikilink discipline (found -> match, zero/multiple -> plain text + ask).

### 4b. Voice Correction

Rewrite to first person where the vault owner is speaking. Other speakers use third person with names.

### 4c. Topic Filtering

Compare topic sections against the note's `about:` frontmatter:
- Topics related to `about:` projects -> **keep with detail** (bold heading + nested bullets)
- Other topics -> **compress to one-line Key Signals** (decisions, status shifts, brief mentions)
- Pure logistics (intros, scheduling, screen sharing) -> **drop**

### 4d. Continuation Detection

Check if prior meeting's open action items appear resolved in the notes. Note resolved items for cross-update.

### 4e. Action Item Candidates

Extract vault-owner commitments. Hold as candidates -- do NOT include in draft yet. Apply threshold: decisions and multi-step work only, not simple edits.

### 4f. Format Output

```markdown
## Summary
[2-3 sentence narrative -- what was this meeting about and what changed]

Key signals:
- [Decision, risk flag, status shift -- one bullet each]
- [Topics NOT expanded below get signal bullets here]

**Topic A**
- Key point
	- Detail or sub-point

**Topic B**
- Key point
```

**Key Signals rule:** Key Signals and topic sections are complementary, not overlapping. Signals cover decisions (one-liner), status shifts, brief context mentions, and topics NOT expanded below. If a Key Signal could be copy-pasted as a topic section's first bullet, it's redundant -- rewrite or remove.

**Formatting rules:**
- `## Summary` and `## Action Items` are the only H2 headings
- Topic sections use `**bold text**`, not `##`
- First person (I/me/my) for the vault owner throughout
- No wikilinks yet -- Step 5 handles that after approval

**Build wikilink map from resolved entities (4a):**
- **Plain text** (in frontmatter `about:` or `with:`): NO wikilinks in body
- **Wikilink** (mentioned but not in frontmatter): `[[Name]]` on first body mention, plain text after

**Typography normalization:**
- Replace `--` with em dashes in body text -- skip frontmatter delimiters (`---`) and `->` arrows
- Agents don't load writing-style.md; normalize output before presenting

## 5. Present & Write

**Never auto-write.** Show draft, iterate, then write on approval.

### 5a. Present Draft
Show full formatted note inline in conversation (Summary + Key Signals + topic sections). Target ~30-50 lines.

### 5b. Action Item Candidates
Below the draft, show candidates (if any):
```
Action item candidates (approve, edit, or skip all):
1. [candidate from agent output]
2. [candidate]
```

### 5c. Iterate
User can request edits (move topic to brief, expand a section, reword a signal). Apply edits without re-showing the full note -- confirm the change concisely.

### 5d. On Approval
When user says "looks good", "yes", "write it", etc.:

1. **Frontmatter enrichment:**
	- `about:` -> add discovered products/projects from entity resolution (only if vault note exists)
	- `one-liner:` -> set from summary if currently empty
	- `with:` is read-only -- never modify
	- Preserve all existing frontmatter fields

2. **Apply wikilink map** to the approved draft

3. **Write** to the original file path

4. **Cross-update** resolved prior action items (`- [ ]` -> `- [x]` in source meeting notes)

5. **Confirm** with one-liner: "Note written. [N] action items included." Don't re-output the full note.
