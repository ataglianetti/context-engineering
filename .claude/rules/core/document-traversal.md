# Document Traversal

**When a file is mentioned, opened, or relevant:**
1. **Read it first** - Never respond about a document without reading it
2. **Follow frontmatter links** - Traverse `parent:`, `context:` to understand hierarchy
3. **Check related folders** - Documents/ contains specs, analysis, ticket drafts
4. **Use what's documented** - If the answer exists in the vault, find it rather than guessing

**Frontmatter is navigation, not decoration.** The linking structure maps relationships. Use it.

## Temporal Context
For current state of any project or work item:
- Check recent Calendar/ daily notes for activity
- Look for Meeting Notes documents linked to the project
- Find Thread notes (emails, Slack, Teams) that capture ongoing conversations
- To find what links TO a note, search for `[[Note Name]]` across vault files using the Grep tool. If Obsidian CLI is installed, `obsidian backlinks file="X"` provides more complete results including aliases.

**Anti-pattern:** Inferring from filenames or folder paths when actual document content is accessible.

## Degradation Strategy
- **Block and ask:** Cannot determine context, files don't exist, critical info requires guessing
- **Proceed with caveats:** Reasonable inference possible, partial info available
- **Never guess when you can read:** If a document exists that would answer the question, read it.

## Wikilink Discipline

When formatting or editing notes, follow this decision flow for each key entity (people, products, bugs, features):

1. **Search** for vault notes matching the entity
2. **Not found** → use plain text (no orphan wikilinks)
3. **Found** → does it belong in a frontmatter field (e.g., `about:`, `with:`)?
   - **Yes** → add to frontmatter, use plain text in body (frontmatter is the canonical graph connection). Note: some fields are read-only in certain contexts (e.g., `with:` in Meeting notes is set before processing; in Thread notes it's built during processing).
   - **No** → wikilink on first body mention, plain text after. Body wikilinks are for entities frontmatter doesn't capture — e.g., a person mentioned in discussion who isn't an attendee, or a prior meeting referenced for context.
