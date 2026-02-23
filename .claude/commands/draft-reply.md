---
description: Draft reply to a Thread note
---

**Input (one of the following):**
- Thread note path or wikilink (e.g., `[[2026-01-15 Project status update]]`)
- If invoked immediately after `/save-thread`, use the thread from conversation context
- If no input provided, ask which thread to reply to

**1. Load the thread**

If given a path or wikilink:
- Read the thread note from Calendar folder
- Parse the Thread section to understand the conversation

If using conversation context:
- Use the thread content already discussed in this session

**1.5. Load people context**

Read person notes for all participants in the thread's `with:` list. **Search in parallel:** Issue ALL person note searches in a single tool-call batch:
- For each person in `with:`, search all People folders simultaneously:
  - Glob: `Contexts/*/People/{Name}*.md`
- Issue all Glob calls for all people in one batch. Do not search sequentially.

Then read all found person notes in a single parallel batch. Focus on:
- `## Working With` section -- communication patterns, decision-making style, political dynamics
- `title:` frontmatter -- role context for tone calibration

Skip if:
- Person note doesn't exist
- Person note has no `## Working With` section (nothing useful beyond what collaborators.md provides)

This context informs Step 3 (draft generation) -- tone, framing, what to emphasize or avoid based on who you're writing to.

**2. Analyze the thread**

Identify:
- Who sent the last message
- Open questions or requests requiring response
- Action items assigned to [Your Name]
- Decisions that need to be communicated
- Tone and formality level of the conversation

**3. Generate the draft**

Create a reply that:
- Matches the tone and formality of the thread
- Accounts for recipient communication patterns from person notes (e.g., framing closures as "we evaluated and confirmed" for someone who needs visible diligence)
- Addresses all open questions or action items
- Uses bracketed placeholders for decisions you need to make (e.g., `[specific date TBD]`, `[confirm with engineering first]`)
- Is complete enough to send with light editing

**4. Add draft to the thread note**

Append the draft at the bottom of the Thread section:
```
---
**[Your Name] - DRAFT**

[draft content here]
```

**5. Iterate with the user**

Present the draft and ask for feedback. Continue refining until the user is satisfied.

**6. Copy final reply to clipboard**

When the user approves the draft:
- Copy to clipboard as **plain text**
- Strip markdown formatting (remove `**` bold markers, wikilinks, etc.)
- Convert wikilinks to plain names: `[[John Smith]]` becomes `John Smith`
- Use regular hyphens, not en-dashes
- Use this command pattern:
  ```bash
  cat << 'EOF' | pbcopy
  plain text content here
  EOF
  ```

**7. Update the thread note**

After the user confirms they've sent the reply:
- Update the DRAFT header with actual date/time: **[Your Name] - [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**
- Save the updated note
