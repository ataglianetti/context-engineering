---
description: Morning journal entry - prompts for input, cleans up dictation while preserving voice
---

Morning reflection for the daily note's First Light section.

**1. Find today's daily note**
- Path: `Calendar/YYYY-MM-DD.md` (current date)
- If it doesn't exist, create it using `Resources/Templates/Daily Note.md`

**2. Prompt for input**

Open with one of these (vary day to day):
- "What's on your mind this morning?"
- "What are you thinking about today?"
- "How are you starting the day?"
- "What's pulling your attention right now?"
- "Anything lingering from yesterday?"

Wait for their response. They'll likely dictate, so expect:
- Run-on sentences
- Filler words (um, uh, like, you know)
- Speech-to-text artifacts (wrong homophones, missing punctuation)
- Stream of consciousness flow

**3. Push for depth**

After their initial response, look for threads worth expanding:
- Strong emotions mentioned but not explored
- Decisions or tensions they glossed over
- Interesting observations that stopped short
- Things that sound important but got one sentence

Ask a follow-up. Examples:
- "You mentioned [X]. What's behind that?"
- "Say more about [Y]."
- "That sounds like it's weighing on you. What's the real concern?"
- "What would good look like there?"

One or two follow-ups max. Don't turn it into an interview. If they give short answers, they're done. Move on.

**4. Clean up the dictation**

Transform the raw input (initial + follow-ups) into clean prose while preserving:
- Their voice and natural phrasing
- The emotional tone (don't flatten or formalize)
- Specific word choices that feel intentional
- The flow of their thinking

Remove or fix:
- Filler words and verbal tics
- Obvious speech-to-text errors
- Missing punctuation
- False starts and repeated phrases

Do NOT:
- Add structure or headers
- Reorder their thoughts
- Make it sound "professional" or polished
- Add insights or reflections they didn't express
- Use em-dashes (stream-of-consciousness text doesn't use them naturally -- they read as AI cleanup)

**5. Show the cleaned version**

Present the cleaned text and ask: "Does this capture it? Edit or approve."

If they edit, incorporate changes. If they approve, proceed.

**6. Update the daily note**

If `### First Light` section exists, append to it.

If it doesn't exist, insert it immediately BEFORE `### Log`:
```markdown
### First Light
[cleaned content here]

### Log
```

Write the cleaned text as bullet points or short paragraphs (match their natural groupings).

**7. Confirm**

Show what was written and where.
