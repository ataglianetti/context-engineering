---
description: Add new replies from email/Slack/Teams to Thread note
---

Add a new message to an existing Thread note. Uses the thread-processor agent (mode: `update`) to assess whether the message is substantive and update summary/key points only when warranted.

## Step 1: Read Input

- If thread content is pasted in `$ARGUMENTS`, use that
- If no content provided, read from clipboard using `pbpaste`

## Step 2: Find the Existing Thread

Search `Calendar/` for notes with `type: Thread`.

**Matching strategy (combine signals, don't rely on any single one):**
- `with:` property includes the sender or other participants
- `about:` property matches projects/products mentioned in the reply
- Thread section contains matching participants or conversation flow
- Subject line similarity (helpful signal, but subjects get edited for clarity)

**Disambiguation:**
- Exactly one match → proceed automatically
- Multiple matches → show candidates with one-liner, ask user to confirm
- No matches → ask user if this is a new thread (offer to run `/save-thread` instead)

Read the matched thread note fully.

## Step 3: Gather Context

The thread note already has `with:`, `about:`, and `context:` frontmatter. Follow document-traversal to build the context bundle.

### Batch 1 (all in parallel)

- **Read each person note** in `with:` — Glob People folders for each name, then read found notes (aliases, title, discipline, teams)
- **Read each project note** in `about:` — read directly from vault (aliases, current state)
- **Quick-scan new message** for names NOT in existing `with:` → parallel person search across People folders
- **Read context's collaborators** — `.claude/rules/{context}/collaborators.md`

### Batch 2 (after Batch 1)

- **Read person notes for new participants** found in quick-scan
- **Follow `parent:` links** from project notes to read parent portfolio items
- **Recent related threads** — Grep `Calendar/` for `type: Thread` notes with overlapping `about:` (excluding the current thread). Read Summary section of 2-3 most recent for continuation context.

### Assemble Context Bundle

Format as structured text for the agent:
- `=== THREAD MODE ===` → `update`
- `=== PARTICIPANT PROFILES ===` → from person note reads
- `=== PROJECT/PRODUCT SCOPE ===` → from project note reads
- `=== ORGANIZATIONAL CONTEXT ===` → from thread's `context:` + collaborators
- `=== RECENT RELATED THREADS ===` → summaries from recent matching threads
- `=== EXISTING THREAD STATE ===` → current summary, key points, and one-liner from the thread note

## Step 4: Spawn Agent

Spawn thread-processor agent via **Task tool** (Sonnet):

```
Read the agent instructions at .claude/agents/thread-processor.md, then process this update.

[Context Bundle]

=== NEW MESSAGE ===
[raw new message content]
```

The agent returns structured output with `=== SECTION ===` delimiters, including a `CHANGE_ASSESSMENT` of SUBSTANTIVE or MINOR.

**Fallback:** If the agent fails or returns malformed output, process in-context. Don't fail — degrade gracefully.

## Step 5: Post-Processing

Parse the agent's structured output and update the thread note.

### 5a. Append New Message

- Add `---` separator after the last message in the Thread section
- Append the formatted new message from agent's `NEW_MESSAGE` section:
  ```
  **Person Name – [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**

  {clean message body}
  ```
- Use plain text for sender name (people in `with:` are already graph-connected via frontmatter)

### 5b. Update Filename and References

- Extract date from the new message
- Rename file from `YYYY-MM-DD Title` to `NEW-DATE Title`
- **Critical:** Search the entire vault for wikilinks referencing the old filename and update them to the new filename
	- Pattern to find: `[[old-filename]]` or `[[old-filename|alias]]`
	- Update to: `[[new-filename]]` or `[[new-filename|alias]]` (preserve aliases)
- Preserve `created:` property (keep original thread start date)

### 5c. Update Metadata

- Add any new participants to `with:` property (from agent's `PERSON_CANDIDATES`)
- Add any new projects to `about:` property (from agent's `PROJECT_CANDIDATES`)
- Resolve new candidates against vault (same entity resolution as save-thread Step 4a)

### 5d. Person Note Creation

For new participants added to `with:` who don't have vault notes:
- **Single missing person:** simple yes/no question
- **Multiple missing people:** multiSelect checkbox list
- For each person the user selects:
	- Read `Resources/Templates/Person.md` for current template structure
	- Create Person note following that template's frontmatter fields
	- Save to `Contexts/[context]/People/[Person Name].md`
	- Add H1 with person's full name

### 5e. Update Content (conditional on CHANGE_ASSESSMENT)

**If SUBSTANTIVE:**
- Update `## Summary` with agent's `UPDATED_SUMMARY` (apply wikilinks to project references)
- Update `## Key Points` with agent's `UPDATED_KEY_POINTS` (if present)
- Update `one-liner:` in frontmatter with agent's `UPDATED_ONE_LINER` (if focus shifted)

**If MINOR:**
- Skip content updates — the message is appended but summary/key points remain unchanged

### 5f. Save

Write the updated thread note.

**Output:**
- Show the appended message (not the full thread)
- Show change assessment (SUBSTANTIVE/MINOR) and what was updated
- Confirm: filename change, wikilink updates (count)
- If any wikilinks couldn't be updated, list them

## Rules

- Person names in `with:` frontmatter → plain text in body (frontmatter is the canonical graph connection)
- Person names NOT in `with:` → `[[First Last]]` wikilink on first body mention, plain text after
- The vault owner ([Your Name]) → plain text as sender in speaker headers
- Separate messages with `---`
- Preserve existing thread formatting
- Chronological order maintained
