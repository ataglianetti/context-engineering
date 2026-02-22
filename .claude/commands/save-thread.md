---
description: Save email/Slack/Teams thread as Thread note
---

**Input:**
- If thread content is pasted below, use that
- If no content provided, read from clipboard using `pbpaste`

Format this thread as an Obsidian "Thread" note using the frontmatter structure defined in `Resources/Templates/Thread.md`.

**1. People — `with` property**
- Extract all people mentioned and convert to wikilinks.
- Use proper list formatting:
  ```yaml
  with:
    - "[[Person Name]]"
  ```

**1.5. Create missing person notes**
- For each person in `with`, check if a note exists in any People folder under `Contexts/`
- If missing, ask user which ones to create (multiSelect for multiple)
- For each selected: read `Resources/Templates/Person.md`, create note in `Contexts/[context]/People/[Person Name].md`

**2. Context — `context` property**
- Set based on thread content. If ambiguous, ask user.

**3. Related projects — `about` property**
- Only add items that exist as notes in the vault.

**4. One-liner**
- Concise one-line summary in `one-liner:` frontmatter.

**5. Body content formatting**

- **Summary:** 2-3 sentence summary. Use `[[Full Note Name|Short Alias]]` format for project references.
- **Key Points:** (only if applicable) — decisions, action items, important context.
- **Thread:** section
  - Order messages chronologically (oldest first)
  - Header format: `**[[Person Name]] -- [[YYYY-MM-DD|M/D/YYYY]] h:mm AM/PM**`
  - Clean up formatting, remove signatures and boilerplate
  - Separate messages with `---`

**6. Title, filename, and aliases**
- Filename: `YYYY-MM-DD Descriptive title`
- Add descriptive title to `aliases:`

**7. Update person notes from signatures**

Check email signatures for metadata. Only update when person note exists AND target field is empty AND signature has clear data.

Fields to extract: `title:`, `company:`, `email:`

Never extract: phone numbers, addresses, social links, marketing content.

**8. Save the note**
- Save to Calendar folder.
- Do NOT add to daily note.

**9. Copy reply to clipboard**
When user drafts a response, copy as plain text:
```bash
cat << 'EOF' | pbcopy
plain text content here
EOF
```
