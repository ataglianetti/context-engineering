---
description: Draft reply to a Thread note
---

Draft a reply to an existing Thread note. Uses the thread-processor agent (mode: `reply`) with full person context (including Working With sections) to calibrate tone and coverage.

## Step 1: Load Thread

**Input (one of the following):**
- Thread note path or wikilink in `$ARGUMENTS` (e.g., `[[2026-01-15 Project status update]]`)
- If invoked immediately after `/save-thread`, use the thread from conversation context
- If no input provided, ask which thread to reply to

Read the thread note from Calendar folder. Parse the full Thread section to understand the conversation.

## Step 2: Gather Context

Follow the thread note's frontmatter links to build a rich context bundle. Reply mode needs the fullest person profiles -- Working With sections inform tone and framing.

### Batch 1 (all in parallel)

- **Read each person note** in `with:` -- Glob People folders (`Contexts/*/People/`) for each name, then read found notes. **Include Working With section** (communication patterns, decision-making style, political dynamics -- these directly inform the draft)
- **Read each project note** in `about:` -- read directly from vault (aliases, current state)
- **Read context's collaborators** -- `.claude/rules/{context}/collaborators.md`

### Batch 2 (after Batch 1)

- **Follow `parent:` links** from project notes to read parent portfolio items (reply may need broader context)
- **Recent related threads** -- Grep `Calendar/` for `type: Thread` notes with overlapping `about:` (excluding the current thread). Read Summary section of 2-3 most recent -- the reply may need to reference prior exchanges.

### Assemble Context Bundle

Format as structured text for the agent:
- `=== THREAD MODE ===` -> `reply`
- `=== PARTICIPANT PROFILES ===` -> from person note reads (with Working With content)
- `=== PROJECT/PRODUCT SCOPE ===` -> from project note reads
- `=== ORGANIZATIONAL CONTEXT ===` -> from thread's `context:` + collaborators
- `=== RECENT RELATED THREADS ===` -> summaries from recent matching threads
- `=== EXISTING THREAD STATE ===` -> current summary, key points, and one-liner

## Step 3: Spawn Agent

Spawn thread-processor agent via **Task tool** (Sonnet):

```
Read the agent instructions at .claude/agents/thread-processor.md, then draft a reply.

[Context Bundle]

=== THREAD CONTENT ===
[full thread content from the note body]
```

The agent returns: tone assessment, draft reply, and coverage checklist.

**Fallback:** If the agent fails or returns malformed output, draft the reply in-context using the same context bundle. Don't fail -- degrade gracefully.

## Step 4: Present and Iterate

### 4a. Show Draft

Present to the user:
- **Tone assessment** -- register and thread dynamic from agent
- **Draft reply** -- the full text
- **Coverage** -- what's addressed, what's not (with reasons)

### 4b. Iterate

Ask for feedback. Continue refining until the user is satisfied.

For **significant rewrites** (tone shift, different approach, major content changes): re-spawn the agent with updated instructions appended to the context bundle.

For **minor edits** (word choice, small additions, removing a line): edit in-context without re-spawning.

## Step 5: Finalize

### 5a. Add Draft to Thread Note

Append the draft at the bottom of the Thread section:
```
---
**[Your Name] - DRAFT**

[draft content here]
```

### 5b. Copy to Clipboard

When the user approves the draft:
- Copy to clipboard as **plain text** using `copy-rich.sh --plain` or:
  ```bash
  cat << 'EOF' | pbcopy
  plain text content here
  EOF
  ```
- Strip markdown formatting (remove `**` bold markers, wikilinks, etc.)
- Convert wikilinks to plain names: `[[John Smith]]` -> `John Smith`
- Use regular hyphens, not en-dashes

### 5c. Update Thread Note (after sent)

When the user confirms they've sent the reply:
- Update the DRAFT header with actual date/time:
  `**[Your Name] -- [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**`
- Save the updated note

## Rules

- Draft uses first person (I/me/my) -- never refers to vault owner in third person
- Match thread tone -- don't go formal when thread is casual, or vice versa
- Bracket unknowns: `[specific date TBD]`, `[confirm with engineering first]`
- Working With context from person notes informs framing, not just tone
