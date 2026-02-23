---
description: Evening journal entry - prompts for reflection, cleans up dictation while preserving voice
---

Evening reflection for the daily note's Last Light section.

**1. Find today's daily note**
- Path: `Calendar/YYYY-MM-DD.md` (current date)
- If it doesn't exist, create it using `Resources/Templates/Daily Note.md`

**2. Prompt for input**

Open with one of these (vary day to day):
- "How did today go?"
- "What stood out today?"
- "What's staying with you from today?"
- "Anything unfinished on your mind?"
- "What would you do differently?"

Wait for their response. They'll likely dictate, so expect:
- Run-on sentences
- Filler words (um, uh, like, you know)
- Speech-to-text artifacts (wrong homophones, missing punctuation)
- Stream of consciousness flow

**3. Push for depth**

After their initial response, look for threads worth expanding:
- Strong emotions mentioned but not explored
- Wins or frustrations they brushed past
- Unresolved tensions from the day
- Lessons or realizations that got one sentence

Ask a follow-up. Examples:
- "You mentioned [X]. What made that significant?"
- "Say more about [Y]."
- "Sounds like that landed. Why?"
- "What are you taking from that?"

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

If `### Last Light` section exists, append to it.

If it doesn't exist, insert it immediately AFTER the `### Log` section (after all log content):
```markdown
### Log
[existing log content]

### Last Light
[cleaned content here]
```

Write the cleaned text as bullet points or short paragraphs (match their natural groupings).

**7. Confirm**

Show what was written and where.
