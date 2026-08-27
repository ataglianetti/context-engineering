---
description: Format rough meeting notes into a structured meeting note, enriched with vault context
---

Turn rough meeting notes into a structured, scannable note — enriched with vault context so names, projects, and shorthand resolve correctly.

**Input:** Path to a meeting note that already has frontmatter and a `## Notes` section (optional — auto-detects if omitted).

**Out of scope:** capture. This command does not record, transcribe, or fetch anything. It starts from whatever is already in `## Notes` — typed bullets, a dictated recap, pasted chat, or output you pasted in from a notetaker. How the raw text got there is your business; wire your own capture step ahead of this if you want one.

**Target:** 10–30 lines of finished content, minimal post-editing.

## 1. Find the Note

**If `$ARGUMENTS` is a path,** use it and skip to Step 2.

**With no argument,** glob `Calendar/` for today's date prefix (e.g. `2026-03-12*.md`) and keep files that have `type: Meeting` in frontmatter, have a `## Notes` section, and do **not** have a `## Summary` section (that means it's already processed).

- None found → "No unprocessed meeting notes from today." Stop.
- One found → use it.
- Multiple → list them with index numbers (title + `with:` attendees) and let the user pick.

**If the file doesn't exist,** create it with the frontmatter for its meeting type (see Step 2), parsing date and title from the filename: `Calendar/2026-03-13 Some Meeting.md` → date `2026-03-13`, title `Some Meeting`.

## 2. Match the Meeting Type

This determines which frontmatter the note carries and, for a recurring meeting, how much context comes for free.

| Type | Detection | Distinguishing frontmatter |
|---|---|---|
| **Meeting Occurrence** | Title matches an existing `type: Meeting Series` note (search by basename or alias) | `series:` wikilink to the parent; `about:` and `with:` inherited from it |
| **1:1** | Title is a person's name matching a Person note, or exactly one attendee | `with:` holds exactly one Person wikilink |
| **Generic Meeting** | Everything else | `with:` holds the attendee list; no `series:` |

If detection is ambiguous, ask: "Meeting Occurrence, 1:1, or generic Meeting?"

**Occurrences inherit from their series note** — `series:`, `about:`, and `with:` all come from the parent rather than being asked for. This is the main reason to keep Meeting Series notes accurate: it's what makes a recurring meeting cheap to file.

For 1:1s and generic meetings, ask for context and attendees if they aren't already in frontmatter.

**Frontmatter contract** — if you keep meeting templates, have them emit this:

- `type: Meeting` and a `context:` wikilink are required — a PostToolUse hook blocks the write without them
- `series:` only on occurrences
- `with:` is **read-only** to this command — it's set at creation and never modified during processing
- If you date the note under its H1, point the wikilink at the daily note (`[[YYYY-MM-DD|Month DDth, YYYY]]`) rather than at the meeting note itself, so the day's notes stay linked together. Convention, not enforced — adapt the format to your own vault.

Save the raw note body and all frontmatter values before processing.

## 3. Gather Context (parallel)

Per `document-traversal.md`, follow the frontmatter links to build working context. **These have no dependencies on each other — read them in parallel:**

- **Each Person note in `with:`** — **aliases only.** Skip email, Working With, and full profiles; this step resolves names, it doesn't need the relationship context that `/draft-reply` does. Reading the whole profile here spends context on nothing.
- **Each `about:` portfolio note** — aliases and shorthand map only
- **The `series:` note**, if present — recurring context, standing topics, typical attendees
- **The most recent prior meeting** in the same series or on the same topics — read only its Summary and any open next steps, for continuation detection

Assemble a lightweight context block:

```
=== ATTENDEE ALIASES ===
[Name]: [alias1, alias2]

=== SHORTHAND MAP ===
[spoken shorthand] → [full vault name]

=== PRIOR MEETING ===
Meeting: [name] (YYYY-MM-DD)
Open items: [unresolved from last time]
```

**Why this step exists:** rough notes are full of shorthand that only resolves against the vault. Skipping it produces a note full of half-names and unlinked projects, which is the failure this command is for.

## 4. Enrich & Format

Process in context using the lightweight map from Step 3. If there are no raw notes and no vault context, there's nothing to work with — ask what the user remembers.

### 4a. Entity Resolution

Map shorthand to vault names using the shorthand map from Step 3, plus any context-specific rules for this meeting's `context:`. Meeting notes live in `Calendar/`, so path-scoped context rules don't auto-load — read the relevant one during this step.

Search the vault for anything not in the map, then resolve per wikilink discipline:

- **Found, and in frontmatter `about:`/`with:`** → plain text in the body (frontmatter is the canonical graph link)
- **Found, not in frontmatter** → `[[Name]]` on first body mention, plain text after
- **Zero or multiple matches** → plain text, and ask. Never invent the missing half of a name or code.

**Glob every spelling variant before matching a first name** — Mark/Marc, Kris/Chris, Erik/Eric, Jon/John, Steven/Stephen. One match on one spelling is a guess when the others weren't checked. Multiple variants matching, or ambiguous context, means ask.

**Check the Definitions folder before expanding an abbreviation.** If the term is defined, use that expansion and wikilink it. If it isn't, ask — don't guess at what an acronym stands for.

### 4b. Voice

Write the vault owner in first person (I/me/my). If the notes were taken by or about someone else running the meeting, put their actions in third person and keep the vault owner first-person where identifiable.

### 4c. Topic Filtering

Every discussion point becomes a flat bullet by default, ordered by importance:

- Decisions, status changes, new information, commitments — one bullet each
- Pure logistics (intros, scheduling, screen sharing) → **drop**
- **Promote to a topic section** only when a subject has 3+ related bullets that would be confusing as flat items. Most meetings need none.

### 4d. Consolidation Gate (MANDATORY — do not skip)

**This is a separate pass, not part of drafting.** After 4c produces a bullet list, run each bullet through the filters below. Two targets, both mandatory: **≤6 top-level bullets** AND **no bullet over ~180 characters** (roughly two sentences). A PostToolUse hook warns on either.

**Both gates or neither.** Hitting the count by folding cut-candidates into the survivors is the failure mode this pass exists to prevent — it converts a list into a wall and the note stops being skimmable. Cutting is the primary remedy; merging is the exception.

**For each bullet, ask:**
1. Does the Summary paragraph already establish this? → **drop**
2. Does another bullet cover the same ground from a different angle? → **merge, but only if the merged bullet stays under ~180 chars.** If it wouldn't, cut the weaker of the two instead.
3. Is this background/context that doesn't affect a decision? → **drop**
4. Is this an implementation detail that doesn't affect scope, cost, or timeline? → **drop**
5. Is this a vendor or third-party claim that isn't differentiating? → **drop** (keep numbers that help compare or decide)
6. "Would I need this to make the next decision or brief someone?" → if no, **cut**

**The em-dash chain is the tell.** A bullet whose clauses are strung together with em-dashes is a bullet that should have been two bullets or one shorter bullet. When a bullet runs long, read it for dashes before rewording: each one usually marks a seam where separate content got welded together during consolidation. Split it, then decide which half survives. Same for a bullet carrying a semicolon-joined second thought.

**Accounting:** After filtering, count bullets and measure the longest. If >6 bullets, go through again — something didn't get cut that should have. If any bullet exceeds ~180 chars, split it and re-run the filters on both halves; the split usually reveals that one half was always droppable. A note that lands at exactly 6 bullets with 300-char bullets has failed this gate, not passed it.

### 4e. Continuation Detection

Check whether the prior meeting's open items (Step 3) appear resolved in these notes. Note what closed.

### 4f. Next Steps Candidates

**Default is NO next steps — zero is the normal outcome.**

A candidate qualifies only with explicit ownership evidence: the vault owner committing in their own words ("I'll send…", "I can take that"), or being assigned by name and accepting. **The quote test** — if you can't point at the sentence where they take the task, it isn't a candidate. Other people's commitments stay as ordinary bullets.

Hold candidates; don't put them in the draft yet.

### 4g. Format Output

````markdown
## Summary
[2-3 sentence narrative — what this meeting was about and what changed]

- [Decision, status change, new info, or commitment — one bullet each]
- [All bullets equal, ordered by importance]

**Topic A** (only if 3+ related bullets)
- Key point
	- Detail or sub-point
````

**Target: 10-30 lines.** A 1:1 lands around 15. A larger multi-topic meeting may reach 30.

**One bullet list, not two.** Everything after the Summary narrative is a flat bullet. Topic sections earn their way in at the 3+ threshold.

**Formatting rules:**
- `## Summary` is the only H2
- Topic sections use `**bold text**`, never `##`
- No wikilinks yet — Step 5 applies them after the entity map is settled
- Normalize `--` to `—`, skipping frontmatter delimiters (`---`) and `->` arrows

## 5. Write & Open

**Write directly to the file.** No inline draft — the user reviews in Obsidian.

1. **Enrich frontmatter:**
	- `about:` → scope to the **vault owner's stake**, not the meeting's full subject matter. `about:` drives portfolio backlinks, so a project's linked meetings should read as "meetings that actually moved it *for me*." Never tag a project just because it came up. Resolution ladder:
		1. Projects the vault owner **owns or actively contributes to** in this meeting (only where a vault note exists).
		2. **No personal stake** (pure observer, or a cross-functional process meeting) → fall back to the meeting's *topic*: if it's a recurring series, that's already captured in the `series:` note — leave `about:` empty rather than duplicate it. Otherwise a topic stub note, if one genuinely warrants existing.
		3. Neither applies → leave `about:` empty. The `with:` list and the notes still record that the meeting happened.
		- **Why:** a cross-team sync got tagged with a project the vault owner only *observed*, surfacing someone else's roadmap work in his portfolio backlinks. The correct scope was the one piece he actually presented; the cross-team framing belonged in the series note.
	- `one-liner:` → set from the summary if empty
	- `related:` → wikilinks to related notes when a multi-session thread is detected (prior meeting from Step 3, or a continuation found in 4e). Leave empty if there's no clear relationship.
	- `with:` is read-only — never modify
	- Preserve every existing field
2. **Apply the wikilink map** from 4a
3. **Replace the raw notes.** `## Notes` and everything under it is scaffolding — input for enrichment, not content to keep. The processed output replaces it. Never leave `## Notes` sitting alongside `## Summary`.
4. **Write** to the original path
5. **Open it:** `obsidian open file="<note name>" newtab`
6. **Confirm in one line:** "Note written. [N] next steps included." Don't re-output the note.

**Then show next-step candidates** — only if 4f produced any — **with the evidence quote**, for batch approval:

```
Next steps candidates (approve, edit, or skip all):
1. Lock presentation roles with the team — "I'll get that locked tomorrow"
```

The quote is the point: it's the quote test made visible, so approval is a judgment on evidence rather than on a plausible-sounding task.

**No candidates → skip this step silently.** Don't announce that there are none, and don't ask whether any bullets should become next steps.

Never propose a reminder from meeting content. If the user says "remind me [thing] on [date]" — here or anywhere — add it to `.claude/reminders.md` with a date and source link. That's the only path in.

**Iterate:** the user reviews in Obsidian and asks for edits. Apply them and confirm concisely — don't re-show the whole note.
