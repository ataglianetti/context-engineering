---
description: Re-onboarding interview to refresh Claude rules and context. Dictation-friendly.
---

Conversational interview to update your Claude rules. Designed for dictation (natural speech).

**1. Read current state**

Read these files to understand what's already documented:
- `.claude/rules/core/user-profile.md`
- `.claude/rules/core/memory.md`
- `.claude/rules/[context-1]/context.md`
- `.claude/rules/[context-1]/collaborators.md`
- `.claude/rules/[context-1]/portfolio.md` (if it exists)
- `.claude/rules/[context-2]/context.md`
- `.claude/rules/[context-2]/collaborators.md`

**2. Area selection**

Use AskUserQuestion with multiSelect to ask which areas need refreshing:

| Option | Label | Description |
|--------|-------|-------------|
| 1 | How we work together | Communication style, output preferences, pacing |
| 2 | Current priorities | What you're focused on, blockers, active work |
| 3 | [Context 1] context | Team, products, org dynamics, current challenges |
| 4 | [Context 2] context | Team, products, org dynamics, current challenges |
| 5 | Personal context | Side projects, content creation, personal goals |

**3. Interview loop**

For each selected area, conduct a brief conversational interview:

| Area | Files to Update | Interview Prompt |
|------|-----------------|------------------|
| How we work together | `user-profile.md` | "How has your working style evolved? Any changes to pacing, depth, or how you want me to push back?" |
| Current priorities | `memory.md` | "What's top of mind right now? What are you actively working on, and what's blocking you?" |
| [Context 1] context | `[context-1]/context.md`, `[context-1]/collaborators.md`, `[context-1]/portfolio.md` (if exists) | "Any changes in [Context 1]? Team shifts, product updates, pressure situations?" |
| [Context 2] context | `[context-2]/context.md`, `[context-2]/collaborators.md` | "Any changes in [Context 2]? Team shifts, product updates, how you're navigating leadership?" |
| Personal context | `user-profile.md`, `memory.md` | "What's happening in your personal projects? Any updates to side projects, content you're creating, or other activities?" |

For each area:
1. State what's currently documented (brief summary)
2. Ask the interview question
3. Wait for response (expect dictation: run-on sentences, filler words, stream of consciousness)
4. If they gave a short answer, ask one follow-up to go deeper
5. When done with an area, summarize what you heard before moving to the next

**4. Process dictation**

Clean up their responses:
- Remove filler words (um, uh, like, you know)
- Fix obvious speech-to-text errors
- Preserve their voice and meaning
- Extract concrete updates (people, roles, priorities, preferences)

**5. Confirm before saving**

Present a summary of all proposed changes across all areas:
"Here's what I'll update:

**[Area 1]:**
- [bullet points of changes]

**[Area 2]:**
- [bullet points of changes]

Does this capture it, or should I adjust anything?"

Wait for confirmation. Handle:
- "yes" / "that's right" / "looks good" -> proceed to save
- Corrections -> incorporate and re-confirm
- "add [X]" -> include additional point

**6. Apply updates**

Edit each relevant file:
- Preserve existing structure and sections
- Update only the specific sections that changed
- For memory.md: also update "Last Session" with today's date and "Refreshed context via /refresh"
- Update "Last updated" timestamp in memory.md

**7. Summarize what changed**

Show a brief summary:
"Updated:
- `user-profile.md`: [what changed]
- `memory.md`: [what changed]
- ..."

---

## Dictation tips (for user)
- Speak naturally, Claude will clean up transcription
- Use numbers for selections ("one and three")
- "That's right" / "add that" / "change that" for confirmations
- One area at a time, as deep as you want to go
