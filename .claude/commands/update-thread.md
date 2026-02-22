---
description: Add new replies from email/Slack/Teams to Thread note
---

**Input:**
- If thread content is pasted below, use that
- If no content provided, read from clipboard using `pbpaste`

**1. Parse the new message**
- Extract sender, timestamp, body
- Format: `**[[Person Name]] -- [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**`

**2. Find the existing thread note**

Search `Calendar/` for `type: Thread` notes.

**Matching strategy (combine signals):**
- `with:` includes the sender or participants
- `about:` matches mentioned projects
- Thread section contains matching participants
- Subject line similarity

**Disambiguation:**
- One match: proceed
- Multiple: show candidates, ask user
- None: offer to run /save-thread instead

**3. Append the new message**
- Add `---` separator after last message
- Append formatted new message
- Clean up signatures and boilerplate

**4. Update filename and references**
- Rename file with new date: `NEW-DATE Title`
- Search vault for wikilinks referencing old filename and update them

**5. Update metadata**
- Add new participants to `with:`
- Add new projects to `about:`

**5.5. Create missing person notes**
- For new participants, check for existing notes
- Offer to create missing ones (same as /save-thread)

**6. Update note content if thread state changed**
- Update Summary, Key Points, one-liner if new message resolves discussion or adds significant info
- Skip updates for minor acknowledgments

**Output:**
- Show appended message
- Confirm filename change and wikilink update count
