---
description: Add new replies from email/Slack/Teams to Thread note
---

Add new messages to an existing Thread note. Processing happens in-context (no agent spawn). The summary is maintained as **current state** — it gets rewritten, never appended to; chronology lives in the messages.

Summarization follows `rules/vault/summarization.md`. Entity resolution follows `rules/vault/entity-resolution.md`.

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

## Step 3: Dedup Against Existing Messages

The most common input is the **entire chain pasted again**, not just the new reply. Before anything else:

1. Parse every message in the paste (sender, timestamp, body — same parsing rules as `/save-thread` Step 3a).
2. Match each against messages already in `## Thread` by sender + timestamp; where timestamps are missing or reformatted, match on sender + opening ~100 chars of body.
3. Keep only genuinely new messages. **Never append a message that's already saved.**
4. Report the split: "N messages in paste, M already saved, appending K."

If K = 0, say so and stop (nothing to add).

## Step 4: Gather Context

Skip or slim this step for trivial updates (a one-line "thanks" needs no context bundle). For substantive new messages:

### In parallel
- **Read person notes** for senders of the new messages (Glob `Contexts/*/People/`, all spelling variants)
- **Quick-scan new messages** for names NOT in existing `with:` → person search
- **Read project notes** in `about:` if the new messages shift scope (aliases, current state)
- **Read context collaborators** — `.claude/rules/{context}/collaborators.md` — if new participants appeared

## Step 5: Update the Note

### 5a. Insert New Messages Chronologically

Insert each new message **by timestamp among the existing messages** — not blindly at the bottom. A reply can arrive out of order (forwards, cross-timezone copies); the `## Thread` section must stay oldest-first throughout.

Format:
```
**Person Name – [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**

{clean message body}
```
- `---` separator between messages
- Plain text for sender names in `with:` (already graph-connected via frontmatter); the vault owner is always plain text
- **Do not rename the file.** The filename stays anchored to the thread-start date permanently. `modified:` (and the frontmatter timestamp) carry recency. Preserve `created:`.

### 5b. Assess the Change

**SUBSTANTIVE:** resolves a discussion, changes direction, adds significant new information, introduces decisions or new commitments.
**MINOR:** acknowledgments, scheduling confirmations, "thanks" / "got it", forwarding without commentary.

### 5c. Update Content (SUBSTANTIVE only)

- **Rewrite `## Summary` as current state** — 2-3 sentence narrative of where the thread stands now + refreshed "Key signals:" bullets. **Never append dated paragraphs ("On 6/8… On 6/19…")** — that turns the summary into an accretion log; the chronology already lives in the messages. Detail displaced by the rewrite must exist in the messages below or a linked note before it's cut; if it exists nowhere else (in-session analysis, external figures), keep it in Key Points or move it to the appropriate Document and link it.
- **Update `## Key Points`** — decisions/numbers not already carried by the Summary. Resolve superseded points; cap ~8 bullets.
- **Maintain `## Open (as of {date})`** — remove items the new messages settle, add new unresolved items with owners, refresh the as-of date to the latest message. Create the section if open items now exist; remove it if everything closed.
- **Update `one-liner:`** if the focus shifted (≤300 chars).

**MINOR:** append the message(s) only; content stands.

### 5d. Metadata & People

- Add new participants to `with:`, new projects to `about:` (entity resolution per `rules/vault/entity-resolution.md`)
- **Person note creation** for new participants without vault notes (same flow as `/save-thread` Step 4c)
- **Signature enrichment** for new senders (same strict rules as `/save-thread` Step 4d: existing note + empty field + unambiguous signature; `title:`/`company:`/`email:` only)

### 5e. Write

Write the updated note directly (file-first — no inline re-presentation).

**Output (one short block):**
- Dedup split (from Step 3) and where the new messages were inserted (end vs. mid-thread)
- Change assessment (SUBSTANTIVE/MINOR) and what was updated (summary / key points / open / one-liner)

## Step 6: Reminders & Hot State

Same as `/save-thread` Step 6: surface reminder candidates from new/changed Open items (approved → `.claude/reminders.md`), and flag when the update touches a `memory.md` Open Thread or `work-state.md` Active project ("This touches [X] — [what changed]"). Surface only — state updates happen at session close.

## Rules

- Chronological order maintained — oldest first, always, including mid-thread inserts
- Message bodies are ground truth: verbatim (minus signatures/boilerplate), never summarized or edited after saving
- Never create `## Reply` / `## Reply Sent` sections — sent replies are ordinary `## Thread` messages (drafts belong to `/draft-reply`)
- Summary = current state, rewritten; Key Points = what the Summary doesn't carry; no triple-stating across Summary/Key Points/messages
- One-liner ≤300 chars; Summary narrative 2-3 sentences; Key Points ≤8 bullets (`validate-thread-budget.sh` warns past these)
- Preserve existing thread formatting and all frontmatter not explicitly updated
