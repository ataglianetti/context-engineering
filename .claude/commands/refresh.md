---
description: Re-onboarding interview to refresh Claude rules and context. Dictation-friendly.
---

Conversational interview to update your Claude rules. Designed for dictation (natural speech).

**1. Read current state**

Read these files to understand what's already documented:
- Rules in `rules/core/` (user-profile.md, memory.md, thinking-partner.md)
- Context-specific rules in `rules/` subdirectories

**2. Area selection**

Use AskUserQuestion with multiSelect to ask which areas need refreshing:

| Option | Label | Description |
|--------|-------|-------------|
| 1 | How we work together | Communication style, output preferences, pacing |
| 2 | Current priorities | What you're focused on, blockers, active work |
| 3 | Context areas | Organization-specific updates (team, dynamics, products) |

**3. Interview loop**

For each selected area:
1. State what's currently documented (brief summary)
2. Ask the interview question
3. Wait for response (expect dictation)
4. If short answer, ask one follow-up
5. Summarize what you heard before moving to next area

**4. Process dictation**
Clean up responses: remove filler, fix speech-to-text errors, preserve voice and meaning.

**5. Confirm before saving**
Present summary of all proposed changes. Wait for confirmation.

**6. Apply updates**
Edit relevant files, preserving structure.

**7. Summarize what changed**
Brief list of updated files and what changed in each.

---

## Dictation tips
- Speak naturally, Claude will clean up
- "That's right" / "add that" / "change that" for confirmations
- One area at a time, as deep as you want
