---
description: Save email/Slack/Teams thread as Thread note
---

Save a raw email/Slack/Teams thread as a structured Thread note in the vault. Uses the thread-processor agent for parsing and summarization, with orchestrator handling all vault operations.

## Step 1: Read Input

- If thread content is pasted in `$ARGUMENTS`, use that
- If no content provided, read from clipboard using `pbpaste`
- Store the raw thread text for both quick-scan and agent consumption

## Step 2: Gather Context

Before spawning the agent, assemble a context bundle so the agent can produce accurate output.

### Quick Scan (orchestrator)

Lightweight parse of raw input to extract discovery signals:
- **Email addresses** — scan for `@domain.com` patterns
- **Sender names** — from "From:" headers, message attributions, greeting lines
- **Org signals** — map email domains to contexts based on your organizational setup
- **Product/project mentions** — scan for known product names, codes, project references

### Batch 1 (all in parallel)

Using quick-scan results, fire all searches simultaneously:

**Person searches** — for each extracted name, Glob People folders:
- `Contexts/*/People/{Name}*.md`

**Project searches** — for each mentioned product/project, Glob Portfolio folders:
- `Contexts/*/Portfolio/**/{Name}*.md`

**Context collaborators** — based on detected org signal:
- Read `.claude/rules/{context}/collaborators.md`

### Batch 2 (after Batch 1 results)

Using found files from Batch 1:

**Read found person notes** — in parallel. Extract: aliases, title, discipline, teams, Working With section.

**Read found project/product notes** — in parallel. Extract: aliases, current state, `parent:` frontmatter.

**Follow parent links** — read parent portfolio items (e.g., if a sub-project is found, read its parent).

**Recent related threads** — Grep `Calendar/` for `type: Thread` notes with overlapping `about:` references. Read Summary section of 2-3 most recent for continuation context.

### Assemble Context Bundle

Format the gathered context as structured text for the agent (see `agents/thread-processor.md` Context Bundle format):
- `=== THREAD MODE ===` → `save`
- `=== PARTICIPANT PROFILES ===` → from person note reads
- `=== PROJECT/PRODUCT SCOPE ===` → from project note reads
- `=== ORGANIZATIONAL CONTEXT ===` → detected context + relevant collaborators
- `=== RECENT RELATED THREADS ===` → summaries from recent matching threads

## Step 3: Spawn Agent

Spawn thread-processor agent via **Task tool** (Sonnet):

```
Read the agent instructions at .claude/agents/thread-processor.md, then process this thread.

[Context Bundle]

=== RAW THREAD ===
[raw thread content]
```

The agent returns structured output with `=== SECTION ===` delimiters.

**Fallback:** If the agent fails or returns malformed output (missing required sections), process the thread in-context using the same logic. Don't fail — degrade gracefully.

## Step 4: Post-Processing

Parse the agent's structured output and build the Thread note.

### 4a. Entity Resolution

**Person candidates** — from agent's `PERSON_CANDIDATES` section:
1. For each candidate, search vault (if not already found in Batch 1)
2. Exactly one match → use it as wikilink
3. No match → plain text, add to "missing persons" list
4. Multiple matches → ask user to disambiguate

**Project candidates** — from agent's `PROJECT_CANDIDATES` section:
1. Search vault for each candidate
2. Found → use as wikilink in `about:` and body (first mention: `[[Full Name|Alias]]`, subsequent: plain text)
3. Not found → plain text only

### 4b. Frontmatter Assembly

Build frontmatter from agent output + entity resolution:
```yaml
---
type: Thread
context: "[[{agent context}]]"
about:
  - "[[{resolved project}]]"
with:
  - "[[{resolved person}]]"
one-liner: {agent one-liner}
aliases:
  - {agent suggested-title}
created: {date of first message}
tags:
modified:
cssclasses:
---
```

### 4c. Body Assembly

```markdown
# {agent suggested-title}

## Summary
{agent SUMMARY — with wikilinks applied to first project mentions using [[Full Name|Alias]] format}

## Key Points
{agent KEY_POINTS — if present, with wikilinks applied}

## Thread
{agent MESSAGES — formatted as:}
**Person Name – [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**

{message body}

---

{next message...}
```

### 4d. Person Note Creation

For people in `with:` list who don't have vault notes:
- **Single missing person:** simple yes/no question
- **Multiple missing people:** multiSelect checkbox list
- For each person the user selects:
	- Read `Resources/Templates/Person.md` for current template structure
	- Create Person note following that template's frontmatter fields
	- Save to `Contexts/[context]/People/[Person Name].md`
	- Add H1 with person's full name

### 4e. Person Note Updates from Signatures

Check email signatures in the agent's parsed messages for metadata. Only update when:
- Person note exists AND
- Target field is currently empty AND
- Signature contains clear, unambiguous information

Fields to extract (strict list): `title:`, `company:`, `email:`

Never extract: phone numbers, addresses, social links, marketing taglines.

### 4f. Save

- Save Thread note to `Calendar/{YYYY-MM-DD} {suggested-title}.md`
- Date = most recent message date
- Do NOT add to daily note (`/daily-note` gathers work at end of day)

**Output:** Show the formatted note. Ask user to review before saving to Calendar.

## Rules

- Person names in `with:` frontmatter → plain text in body (frontmatter is the canonical graph connection)
- Person names NOT in `with:` → `[[First Last]]` wikilink on first body mention, plain text after
- The vault owner is [Your Name] — use plain text (no wikilink) as sender in speaker headers
- Project references in Summary/Key Points → `[[Full Note Name|Short Alias]]` on first mention, plain text after
- Separate messages with `---`
- Chronological order (oldest first)
