---
description: Save email/Slack/Teams thread as Thread note
---

Save a raw email/Slack/Teams thread as a structured Thread note in the vault. Processing happens in-context (no agent spawn — the raw thread is already in this context; a subagent would only duplicate the payload and add a parse-failure mode).

Summarization follows `rules/vault/summarization.md`. Entity resolution follows `rules/vault/entity-resolution.md`. Read both before processing if not already in context.

## Step 1: Read Input

- If thread content is pasted in `$ARGUMENTS`, use that
- If no content provided, read from clipboard using `pbpaste`

## Step 2: Gather Context

### Quick Scan

Lightweight parse of raw input to extract discovery signals:
- **Email addresses** — scan for `@domain.com` patterns
- **Sender names** — from "From:" headers, message attributions, greeting lines
- **Org signals** — map email domains to contexts. Keep the mapping in your context rules, e.g. `@acme.com` → Acme Corp; unrecognized domains → Personal, or ask if ambiguous
- **Product/project mentions** — scan for known product names, codes, project references

### Batch 1 (all in parallel)

Using quick-scan results, fire all searches simultaneously:

**Person searches** — for each extracted name, Glob every People folder, covering all spelling variants per `entity-resolution.md`:
- `Contexts/*/People/{Name}*.md`

**Project searches** — for each mentioned product/project, Glob every Portfolio folder:
- `Contexts/*/Portfolio/**/{Name}*.md`

**Context collaborators** — based on the detected org signal:
- Read `.claude/rules/{context}/collaborators.md`

### Batch 2 (after Batch 1 results)

**Read found person notes** — in parallel. Extract: aliases, title, discipline, teams, Working With section.

**Read found project/product notes** — in parallel. Extract: aliases (shorthand map), current state, `parent:` frontmatter.

**Follow parent links** — read parent portfolio items (e.g., if a sub-project is found, read its parent).

**Recent related threads** — Grep `Calendar/` for `type: Thread` notes with overlapping `about:` references. Read Summary section of 2-3 most recent for continuation context. (If the paste looks like a continuation of one of them, offer `/update-thread` instead of creating a duplicate.)

## Step 3: Process In-Context

### 3a. Parse Messages

For each message in the thread:
- **Sender** — from email headers, chat username, or message attribution; resolve to full name via person-note aliases. Email fallback: `jane.doe@company.com` → "Jane Doe" (capitalize, replace dots) — flag as a candidate, don't assert.
- **Timestamp** — normalize to `YYYY-MM-DD h:mm AM/PM`.
- **Clean body** — strip signatures, footers, legal disclaimers, "On [date] X wrote:" chains, "Sent from my iPhone" boilerplate. **Verbatim otherwise** — preserve the actual words written; never summarize or paraphrase message bodies.
- **Order chronologically** — oldest first.

### 3b. Summarize

- **Summary** — 2-3 sentence narrative arc + "Key signals:" bullets (decisions, commitments, position shifts — one line each; skip pleasantries/logistics)
- **Key Points** — decisions, commitments, important context **not already carried by the Summary**. Omit the section if nothing qualifies — don't pad, don't restate.
- **Open items** — unresolved commitments/questions as of the last message, each with an owner
- **Metadata** — one-liner (≤300 chars, one sentence), suggested title (no date prefix), context with rationale

Preserve disagreements — if people disagree in the thread, show both positions. Compression removes, it never reinterprets.

### 3c. Entity Resolution

Resolve person and project candidates per `rules/vault/entity-resolution.md` (spelling-variant globbing, partial-identifier wall, Definitions check for abbreviations, canonical-spelling cross-check). Person names → `with:`; projects → `about:`; body wikilinks per the Rules section below.

## Step 4: Build the Note

### 4a. Frontmatter

```yaml
---
type: Thread
context: "[[{context}]]"
about:
  - "[[{resolved project}]]"
with:
  - "[[{resolved person}]]"
one-liner: {one-liner}
related:
aliases:
  - {suggested-title}
created: {date of FIRST message}
tags:
modified:
cssclasses:
---
```

Populate `related:` with wikilinks to prior threads on the same topic when Batch 2 surfaced a clear continuation relationship; leave empty otherwise.

### 4b. Body

```markdown
# {suggested-title}

## Summary
{2-3 sentence narrative}

Key signals:
- {signal}

## Key Points
{only if it adds beyond Summary}

## Open (as of {date of last message})
- {unresolved item} — {owner}

## Thread
**Person Name – [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**

{message body}

---

{next message...}
```

Omit `## Key Points` and `## Open` when empty. **Never create `## Reply` / `## Reply Sent` sections** — the vault owner's sent replies are ordinary `## Thread` messages; drafts are handled by `/draft-reply`.

### 4c. Person Note Creation

For people in `with:` who don't have vault notes:
- **Single missing person:** simple yes/no question
- **Multiple missing people:** multiSelect checkbox list
- For each person the user selects:
	- Check an existing Person note for the frontmatter fields in use (contract: `rules/vault/vault-structure.md`)
	- Create the Person note with those fields
	- Save to `Contexts/[context]/People/[Person Name].md`
	- Add H1 with person's full name

### 4d. Person Note Updates from Signatures

Check email signatures for metadata. Only update when: person note exists AND target field is currently empty AND signature is clear and unambiguous.

Fields to extract (strict list): `title:`, `company:`, `email:`

Never extract: phone numbers, addresses, social links, marketing taglines.

## Step 5: Write & Open

**Write directly to the file.** No inline draft presentation — the user reviews in their editor.

1. Save to `Calendar/{YYYY-MM-DD} {suggested-title}.md` — **date = FIRST message date** (thread start). The filename never changes as the thread grows; `modified:` carries recency.
2. Do NOT add to daily note (`/daily-note` gathers work at end of day)
3. Open it: `obsidian open file="<note name>" newtab` (skip if you don't use the Obsidian CLI)
4. Confirm with one line. Apply requested edits without re-showing the full note.

## Step 6: Reminders & Hot State

After writing:

1. **Reminder candidates** — vault-owner commitments with a future trigger date, drawn from the Open items. Show them; add approved ones to `.claude/reminders.md` with a date and source link. Most items don't need this — only ones that would otherwise be forgotten.
2. **Hot-state flag** — check the resolved `about:` projects against `memory.md` Open Threads and `work-state.md` Active rows. If the thread resolves, advances, or contradicts one, surface a one-line flag: "This touches [X] — [what changed]." Surface only; work-state and memory updates happen at session close per `session-protocol.md`.

## Rules

- Person names in `with:` frontmatter → plain text in body (frontmatter is the canonical graph connection)
- Person names NOT in `with:` → `[[First Last]]` wikilink on first body mention, plain text after
- The vault owner is [Your Name] — plain text, no wikilink, as sender in speaker headers
- Project references in Summary/Key Points → `[[Full Note Name|Short Alias]]` on first mention, plain text after
- Separate messages with `---`
- Chronological order (oldest first)
- One-liner ≤300 chars; Summary narrative 2-3 sentences; Key Points ≤8 bullets (`validate-thread-budget.sh` warns past these)
