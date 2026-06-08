---
description: Format meeting notes into a structured meeting note, enriched with vault context
---

Format a meeting note from rough notes (bullets, dictated recap, pasted chat, or transcription-tool output), enriched with vault context for entity accuracy. Uses the meeting-processor agent for parsing and formatting, with the orchestrator handling vault operations and enrichment.

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

## 1. Read & Match

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

**Date wikilink format (mandatory):** The line below H1 must be `[[YYYY-MM-DD|Month DDth, YYYY]]` — e.g., `[[2026-04-01|April 1st, 2026]]`. Link target is always the daily note (`YYYY-MM-DD`), never the meeting note itself. Alias uses ordinal day (`1st`, `2nd`, `3rd`). No day names. No year omission. Enforced by hook.

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

## 2. Gather Context (parallel)

Per document-traversal, follow frontmatter links to build working context. **Maximize parallel reads — no dependencies between these:**

- **Read each Person note** in `with:` — aliases, title, discipline, teams
- **Read each `about:` portfolio note** — aliases and shorthand map only
- **Read the `series:` note** if present (recurring meeting context, typical attendees, standing topics)
- **Read 1 most recent meeting** in series or about the same topics (Summary + Next Steps sections only — for continuation detection)

**Assemble lightweight context:**
```
=== ATTENDEE ALIASES ===
[Name]: [alias1, alias2]

=== SHORTHAND MAP ===
[spoken shorthand] → [full vault name]

=== PRIOR MEETING ===
Meeting: [name] (YYYY-MM-DD)
Prior next steps: [unresolved items from last meeting]
```

## 3. Speaker Resolution (simplified)

**Skip entirely if:** The vault owner is the note creator AND the vault owner is NOT in `with:` as an attendee (meaning they organized/ran the meeting). In this case, Me: = vault owner.

**Quick check:** Is the vault owner an attendee (in `with:`) rather than the organizer? If so, the first-person speaker in the raw notes is likely the organizer, not the vault owner.

**Build speaker map:**
- Me: = vault owner → use first person (I/me/my)
- Me: = someone else → name them, third person. Vault owner's contributions only if identifiable.

## 4. Enrich & Format

Spawn a meeting-processor agent via **Task tool** (Sonnet) to parse and structure the raw notes, then post-process its output. **Fallback:** if the agent fails or returns malformed output, process the notes in-context using the same logic. Don't fail — degrade gracefully. If the user has no raw notes and no vault context, there's nothing to process — ask what they remember.

Using the structured output and the lightweight context from Step 2:

### 4a. Entity Resolution
Map shorthand to vault names using the **shorthand map from the `about:` portfolio note** (Step 2) plus the meeting `context:`'s portfolio rules (e.g., `rules/<context>/portfolio.md`) — these hold the project-specific synonyms (codes, product nicknames). Because meeting notes live in `Calendar/`, the context's path-scoped rules don't auto-load; read the relevant context portfolio rule during this step. Search the vault for any entities not in the map — resolve per wikilink discipline (found → match, zero/multiple → plain text + ask).

**Transcription caveats.** Speech-to-text and rough recaps mangle names and can bleed content across meetings. Resolve before wikilinking:
- **Known name mistranscriptions.** Some names get misheard (homophones). A name that doesn't fit the attendee list is also a contamination signal.
- **Cross-contamination between meetings.** A summary can pull a reference from a different meeting into this one. Verify each claim against the attendee list and meeting scope before including it — a name or topic that doesn't fit the attendees is a contamination signal.
- **Spoken product/code shorthand.** Hyphenated product codes often come through garbled. Resolve to the canonical product name or code per the `about:` note's shorthand map and the context's portfolio rules. The per-project mappings live with the context, not in this command.

**Abbreviation expansion — check Definitions before guessing.** When the notes use a domain or business abbreviation, check the Definitions folders before expanding it. If the term exists, use the defined expansion and wikilink it; if it's missing from Definitions, ask rather than guess.

**Name matching — glob ALL spelling variants.** When resolving a first name, glob every common spelling (Mark/Marc, Kris/Chris, Erik/Eric) before matching. A single match on one spelling is effectively a guess when other spellings weren't checked. If multiple variants match, or context is ambiguous, ask. This is stricter than hard-walls.md's "zero/multiple → ask."

### 4b. Voice Correction
Rewrite to first person where Me: = vault owner. If Me: = someone else, rewrite their actions to third person, vault owner to first person where identifiable.

### 4c. Topic Filtering
All discussion points become flat bullets by default, ordered by importance:
- Decisions, status changes, new information, commitments — one bullet each
- Pure logistics (intros, scheduling, screen sharing) → **drop**
- **Promote to topic section** only when a subject has 3+ related bullets that would be confusing as flat items. Most meetings won't need any topic sections.

### 4d. Consolidation Gate (MANDATORY — do not skip)

**This is a separate pass, not part of drafting.** After 4c produces a bullet list, run each bullet through the filters below. The goal is ≤6 top-level bullets. A PostToolUse hook warns if you exceed this.

**For each bullet, ask:**
1. Does the Summary paragraph already establish this? → **drop**
2. Does another bullet cover the same ground from a different angle? → **merge**
3. Is this background/context that doesn't affect a decision? → **drop**
4. Is this an implementation detail that doesn't affect scope, cost, or timeline? → **drop**
5. Is this a vendor claim that isn't differentiating? → **drop** (keep numbers that help compare or decide)
6. "Would I need this to make the next decision or brief someone?" → if no, **cut**

**Accounting:** After filtering, count bullets. If >6, go through again — something didn't get cut that should have. State what was dropped and why (internally, not to user).

### 4f. Continuation Detection
Check if prior meeting's open next steps appear resolved in the notes. Note resolved items.

### 4g. Next Steps Candidates
Extract vault-owner commitments. Hold as candidates — do NOT include in draft yet. Apply the same threshold from meeting-processor.md: decisions and multi-step work only, not simple edits. For items with a future trigger date, flag as potential reminder candidates.

### 4h. Format Output

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
	- `related:` → populate with wikilinks to related notes when a multi-session thread is detected (e.g., prior meeting on the same topic surfaced in Step 2, or continuation detected in Step 4d). Leave empty if no clear relationship exists.
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
1. [candidate]
2. [candidate]

Add as reminder? (for items with future trigger dates)
```

Add approved reminders to `.claude/reminders.md` with date and source link.

### 5c. Iterate
User reviews in Obsidian and requests edits. Apply edits without re-showing the full note — confirm the change concisely.
