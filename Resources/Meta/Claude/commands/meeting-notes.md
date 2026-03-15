---
description: Format rough meeting notes into structured meeting note
---

Format rough meeting notes into a structured meeting note, leveraging vault context for accurate linking and interpretation. Uses the meeting-processor agent for parsing and formatting. Falls back to in-context processing when the agent is unavailable.

**Input:** File path to existing meeting note with frontmatter (optional — auto-detects if omitted)

**Target:** 3-5 minutes, ~10-30 line notes, scannable output, minimal post-editing.

## 0. Auto-Detect (no argument mode)

**Skip this step if `$ARGUMENTS` is provided** — go directly to Step 1.

When invoked with no arguments:

1. Glob `Calendar/` for files matching today's date prefix (e.g., `2026-03-12*.md`)
2. For each match, read the file and check:
   - `type: Meeting` in frontmatter
   - Has `## Notes` section
   - Does NOT have `## Summary` section (already processed)
3. **Results:**
   - **None found** → "No unprocessed meeting notes from today." Stop.
   - **One found** → use that path, proceed to Step 1.
   - **Multiple found** → list them with index numbers (title + `with:` attendees). User picks one, proceed to Step 1.

## 1. Read & Validate

**If the file doesn't exist:** Create it from the appropriate Meeting template. Parse the filename for date and title (e.g., `Calendar/2026-03-13 Some Meeting.md` → date: `2026-03-13`, title: `Some Meeting`).

**Template detection:**
1. **Meeting Occurrence** — title matches an existing Meeting Series note (search `type: Meeting Series` notes by basename/alias). Inherit `series:`, `with:`, `about:` from the series note.
2. **Meeting (1-1)** — title is a person's name (matches a Person note in vault), or exactly one attendee and title suggests 1:1.
3. **Meeting** (generic) — everything else.

If detection is ambiguous, prompt: "Which meeting type? (Meeting Occurrence / 1:1 / Generic Meeting)"

Ask for context and attendees (unless inherited from series). Then create using the matched template structure:

**Meeting Occurrence:**
```markdown
---
type: Meeting
context: "[[Context Name]]"
series: "[[Series Name]]"
about:
  - "[[Inherited from series]]"
with:
  - "[[Inherited from series]]"
aliases:
  - "Series Alias"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# Series Alias
[[YYYY-MM-DD|Month DDth, YYYY]]

## Notes
-
```

**Meeting (1-1):**
```markdown
---
type: Meeting
context: "[[Context Name]]"
about:
with:
  - "[[Person Name]]"
aliases:
  - "1:1 with Person Name"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# 1:1 with Person Name
[[YYYY-MM-DD|Month DDth, YYYY]]

## Notes
-
```

**Meeting (generic):**
```markdown
---
type: Meeting
context: "[[Context Name]]"
about:
with:
  - "[[Person]]"
aliases:
  - "Meeting Title"
one-liner:
created: YYYY-MM-DD
modified:
cssclasses:
---

# Meeting Title
[[YYYY-MM-DD|Month DDth, YYYY]]

## Notes
-
```

Proceed to frontmatter validation below.

Read the file at the provided or detected path. Check frontmatter for required fields:
- `context:` — organizational context
- `with:` — attendees
- `about:` — product/project being discussed

**Ask only if critical fields are empty:**
- Who attended? (if `with:` empty)
- Which context? (if `context:` empty)
- Main subject? (if `about:` empty and unclear from content)

Save the raw note body and all frontmatter values.

## 2. Gather Context

Per document-traversal, follow frontmatter links to build working context. **Maximize parallel reads:**

**Batch 1 (all in parallel — no dependencies between these):**
- Read each Person note in `with:` — aliases, title, discipline, teams
- Read each note in `about:` frontmatter (aliases, sub-items, current state)
- Read the `series:` note if present (recurring meeting context, typical attendees, standing topics)
- Glob for recent meetings matching series or `about:` topics: `Calendar/2026-*.md`
- Read last 3 daily notes from `Calendar/`

**Batch 2 (after Batch 1 completes — uses Glob results):**
- Read 2-3 most recent meetings from Glob results for continuing discussions
- **Open items check:** Check recent meeting next steps for continuation or resolution signals. If the current meeting's content shows a prior next step was completed, note what was resolved.

**Assemble lightweight context:**
```
=== ATTENDEE ALIASES ===
[Name]: [alias1, alias2]

=== SHORTHAND MAP ===
[spoken shorthand] -> [full vault name]

=== PRIOR MEETING ===
Meeting: [name] (YYYY-MM-DD)
Open Next Steps: [unresolved next steps from prior meeting]
```

## 3. Spawn Agent

Spawn a meeting-processor agent via **Task tool** (Sonnet):

```
Read the agent instructions at .claude/agents/meeting-processor.md, then process this meeting.

[Context Bundle from Step 2]

=== RAW NOTES ===
[raw note content from the file]
```

Use the **Task tool** with `subagent_type: "general-purpose"`, `model: "sonnet"`.

The agent returns structured output with `=== SECTION ===` delimiters.

**Fallback:** If the agent fails or returns malformed output, process the notes in-context using the same logic. Don't fail — degrade gracefully. If the user has no transcript and no vault notes, there's nothing to process — ask what they remember.

## 4. Post-Process Agent Output

Parse the agent's structured sections and apply vault-specific enrichment.

### 4a. Entity Resolution

Map shorthand to vault names using alias maps from the context bundle. Search vault for any entities not in the shorthand map — resolve per wikilink discipline (found -> match, zero/multiple -> plain text + ask).

### 4b. Voice Correction

Rewrite to first person where the vault owner is speaking. Other speakers use third person with names.

### 4c. Topic Filtering

All discussion points become flat bullets by default, ordered by importance:
- Decisions, status changes, new information, commitments — one bullet each
- Pure logistics (intros, scheduling, screen sharing) → **drop**
- **Promote to topic section** only when a subject has 3+ related bullets that would be confusing as flat items. Most meetings won't need any topic sections.

### 4d. Continuation Detection

Check if prior meeting's open next steps appear resolved in the notes. Note resolved items for cross-update.

### 4e. Next Steps Candidates

Extract vault-owner commitments. Hold as candidates — do NOT include in draft yet. Apply threshold: decisions and multi-step work only, not simple edits. For items with a future trigger date, flag as potential reminder candidates.

### 4f. Format Output

```markdown
## Summary
[2-3 sentence narrative — what was this meeting about and what changed]

- [Decision, status change, new info, or commitment — one bullet each]
- [All bullets are equal — ordered by importance]
- [Most content lives here as flat bullets]

**Topic A** (only if 3+ related bullets)
- Key point
	- Detail or sub-point
- Another related point
```

**Target: 10-30 lines.** A 1:1 should land around 15 lines. Larger meetings with multiple topics may reach 30.

**One bullet list, not two.** No separate "Key Signals" section. Everything after the Summary narrative is a flat bullet. Topic sections earn their way in at the 3+ threshold.

**Formatting rules:**
- `## Summary` is the only H2 heading
- Topic sections use `**bold text**`, not `##`
- First person (I/me/my) for the vault owner throughout
- No wikilinks yet — Step 5 handles that after approval

**Next steps:**
- Plain-text bullets, not checkboxes. Meeting notes are historical records, not task tracking.
- Only the vault owner's commitments. Other people's next steps stay in relevant topic sections.
- If no commitments in raw notes, omit Next Steps section entirely

**Build wikilink map from resolved entities (4a):**
- **Plain text** (in frontmatter `about:` or `with:`): NO wikilinks in body
- **Wikilink** (mentioned but not in frontmatter): `[[Name]]` on first body mention, plain text after

**Typography normalization:**
- Replace `--` with `—` (em dash) — skip frontmatter delimiters (`---`) and `->` arrows
- Agents don't load writing-style.md; normalize output before presenting

## 5. Write & Open

**Write directly to the file.** No inline draft presentation — the user reviews in Obsidian.

### 5a. Write to File

1. **Frontmatter enrichment:**
	- `about:` → add discovered products/projects from entity resolution (only if vault note exists)
	- `one-liner:` → set from summary if currently empty
	- `with:` is read-only — never modify
	- Preserve all existing frontmatter fields

2. **Apply wikilink map** to the draft

3. **Replace raw notes.** The `## Notes` section (and any content below it) is scaffolding — context for enrichment, not content to preserve. The processed output (Summary + bullets + next steps) replaces it entirely. Do not keep `## Notes` alongside `## Summary`.

4. **Write** to the original file path

5. **Open in Obsidian:** `obsidian open file="<note name>" newtab`

6. **Confirm** with one-liner: "Note written. [N] next steps included." Don't re-output the full note.

### 5b. Next Steps & Reminders
After writing, show next steps candidates (if any) and reminder candidates:
```
Next steps candidates (approve, edit, or skip all):
1. [candidate from agent output]
2. [candidate]

Add as reminder? (for items with future trigger dates)
```

Add approved reminders to `.claude/reminders.md` with date and source link.

### 5c. Iterate
User reviews in Obsidian and requests edits. Apply edits without re-showing the full note — confirm the change concisely.
