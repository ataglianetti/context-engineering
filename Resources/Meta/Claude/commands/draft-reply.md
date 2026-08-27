---
description: Draft reply to a Thread note
---

Draft a reply to an existing Thread note. Drafting happens **in the main loop, not an agent** — subagents don't load `writing-style.md`, so an agent drafts in the vault owner's voice without the voice rules (anti-AI tells, em-dash-zero for email, delivery calibration). Here they're live context.

Before drafting, make sure `rules/core/writing-style.md` guidance is applied — especially the Email & Reply Drafting section and the register table.

## Step 1: Load Thread

**Input (one of the following):**
- Thread note path or wikilink in `$ARGUMENTS` (e.g., `[[2026-01-15 Project status update]]`)
- If invoked immediately after `/save-thread` or `/update-thread`, use the thread from conversation context
- If no input provided, ask which thread to reply to

Read the thread note fully — Summary, Key Points, Open items, and the full Thread section.

## Step 2: Gather Context

Reply mode needs the fullest person profiles — Working With sections inform tone and framing.

### Batch 1 (all in parallel)
- **Read each person note** in `with:` — Glob `Contexts/*/People/`, then read found notes. **Include Working With section** (communication patterns, decision-making style, political dynamics — these directly inform the draft)
- **Read each project note** in `about:` (aliases, current state)
- **Read context's collaborators** — `.claude/rules/{context}/collaborators.md`

### Batch 2 (after Batch 1)
- **Follow `parent:` links** from project notes to read parent portfolio items (reply may need broader context)
- **Recent related threads** — Grep `Calendar/` for `type: Thread` notes with overlapping `about:` (excluding the current thread). Read Summary section of 2-3 most recent — the reply may need to reference prior exchanges.

## Step 3: Draft

Before writing, form:
- **Tone assessment** — register (formal / professional / casual) and the thread's communication pattern; calibrate with Working With context
- **Open items to address** — questions needing answers, commitments to communicate, decisions to convey (the thread's `## Open` block is the starting list)

Then draft, matching thread register, first person for the vault owner. **Bracket unknowns** — when the draft needs a decision the vault owner hasn't made, use `[bracketed placeholders]` ("[specific date TBD]", "[confirm with engineering first]") rather than guessing.

## Step 4: Write Draft to Note & Iterate

**File-first** (per `file-management.md`: thread reply drafts always go to the note). Append at the bottom of the `## Thread` section:

```
---
**[Your Name] - DRAFT**

[draft content]
```

Plain text header — never a wikilink for the vault owner.

In chat, show only:
- **Tone assessment** — one line
- **Coverage** — checkbox audit: what the draft addresses, what it deliberately skips (with reasons)

The user reads the draft in their editor and requests edits; apply them to the note without re-showing the full draft.

## Step 5: Finalize

### 5a. Copy to Clipboard

When the user approves:
- Copy as **plain text** via `copy-rich.sh --plain` or `pbcopy`
- Strip markdown (`**` markers), convert wikilinks to plain names
- Scan for `—` and `…` — em-dashes and trailing ellipses default to ZERO in email/Slack/Teams (writing-style.md); rewrite any out before copying

### 5b. On Send Confirmation

When the user confirms the reply was sent, the draft becomes a normal thread message:
1. Replace the DRAFT header with the standard timestamped header: `**[Your Name] – [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**`
2. If the draft was edited before sending (user pasted a modified version or describes changes), update the message body to match what was actually sent — the saved message must be the sent message, not the draft
3. **If the sent reply is substantive** (resolves an open item, makes a commitment, changes direction), run the `/update-thread` content pass on it: rewrite `## Summary` as current state, refresh `## Key Points`, resolve/add `## Open` items, refresh the one-liner if focus shifted

## Rules

- Draft uses first person (I/me/my) — never refers to vault owner in third person
- Match thread tone — don't go formal when thread is casual, or vice versa
- Working With context from person notes informs framing, not just tone
- **Frame around the strategic question, not the prompt's structure.** For a reply that intersects a project decision, name the question the recipient actually needs answered (ship / keep building / buy instead / stop). External prompt content (a newsletter, critique, deck) becomes evidence reframed to fit — don't mirror its structure point-by-point as a status update.
- **Don't restate what the prior in-thread message established** — the recipient just read it; echoing it back reads as filler. **Point at canonical docs** rather than lifting their bullets into the body (a lifted summary drifts from the source).
- **Own the deliverable.** Anchor on the prior sender's pronouns — if they wrote "we're planning," that "we" includes the vault owner. Don't downgrade co-owned work (positioning, GTM, training) to "[Colleague]'s X"; it undersells the vault owner's role.
- Don't tack on "reply to source" or "share with broader stakeholders" suggestions unless the user confirms those are part of the workflow.
