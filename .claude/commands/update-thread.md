---
description: Add new replies from email/Slack/Teams to Thread note
---

**Input:**
- If thread content is pasted below, use that
- If no content provided, read from clipboard using `pbpaste`

**1. Parse the new message**
- Extract sender, timestamp, and body from the pasted reply
- Format using the same pattern as /save-thread:
  `**[[Person Name]] -- [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**`

**2. Find the existing thread note**

Search in `Calendar/` folder for notes with `type: Thread`.

**Matching strategy (combine signals, don't rely on any single one):**
- `with:` property includes the sender or other participants
- `about:` property matches projects/products mentioned in the reply
- Thread section contains matching participants or conversation flow
- Subject line similarity (helpful signal, but don't rely solely on it since subjects get edited for clarity)

**Disambiguation:**
- If exactly one match: proceed automatically
- If multiple matches: show candidates with one-liner and ask user to confirm
- If no matches: ask user if this is a new thread (offer to run /save-thread instead)

**3. Append the new message**
- Add `---` separator after the last message in the Thread section
- Append the formatted new message
- Clean up signatures, email footers, and boilerplate

**4. Update the filename and all references**
- Extract date from the new message
- Rename file from `YYYY-MM-DD Title` to `NEW-DATE Title`
- **Critical:** Search the entire vault for wikilinks referencing the old filename and update them to the new filename
  - Pattern to find: `[[old-filename]]` or `[[old-filename|alias]]`
  - Update to: `[[new-filename]]` or `[[new-filename|alias]]` (preserve aliases)
- Update `created:` property to reflect original thread date (keep as-is)

**5. Update metadata**
- Add any new participants to `with:` property
- Add any new projects mentioned to `about:` property

**5.5. Create missing person notes**
- For any new participants added to `with:`, check if a note exists in any People folder.
- **Search in parallel:** Issue ALL folder searches in a single tool-call batch -- for each new person, search all folders simultaneously:
  - Glob: `Contexts/*/People/{Name}*.md`
- Issue all Glob calls for all new people in one batch. Do not search sequentially.
- If any people don't have notes, ask the user which ones to create:
  - Single missing person: simple yes/no question
  - Multiple missing people: multiSelect checkbox list
- For each person the user selects:
  - Read `Resources/Templates/Person.md` for the current template structure
  - Create a Person note following that template's frontmatter fields
  - Save to `Contexts/[context]/People/[Person Name].md` (use the thread's context)
  - Add H1 with person's full name

**6. Update note content if the new message changes the thread's state**
- **Summary:** Update if the new message resolves a discussion, changes direction, or adds significant new information
- **Key Points:** Update if decisions were made, positions changed, or new action items emerged
- **one-liner:** Update if the thread's focus or outcome has shifted
- Skip updates if the new message is just a minor acknowledgment that doesn't change the thread's substance

**Output:**
- Show the appended message (not the full thread)
- Confirm: filename change, wikilink updates (count)
- If any wikilinks couldn't be updated, list them

**Rules:**
- ALL person names use `[[First Last]]` wikilinks
- Separate messages with `---`
- Preserve existing thread formatting
