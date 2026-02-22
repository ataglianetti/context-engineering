---
description: Draft reply to a Thread note
---

**Input:**
- Thread note path or wikilink
- If invoked after /save-thread, use conversation context
- If no input, ask which thread

**1. Load the thread**
- Read thread note from Calendar folder
- Parse Thread section for conversation flow

**1.5. Load people context**
- Read person notes for each participant in `with:`
- Focus on `## Working With` section for communication patterns
- Skip if person note has no Working With section

**2. Analyze the thread**
- Who sent the last message
- Open questions or requests
- Action items assigned to user
- Tone and formality level

**3. Generate the draft**
- Match tone and formality of the thread
- Account for recipient communication patterns from person notes
- Address open questions or action items
- Use bracketed placeholders for decisions needed
- Complete enough to send with light editing

**4. Add draft to thread note**
Append at bottom of Thread section:
```
---
**[User Name] - DRAFT**

[draft content]
```

**5. Iterate with user**
Present draft, ask for feedback, refine until approved.

**6. Copy final reply to clipboard**
When approved, copy as plain text (strip markdown, convert wikilinks to plain names).

**7. Update the thread note**
After user confirms they've sent it, update DRAFT header with actual date/time.
