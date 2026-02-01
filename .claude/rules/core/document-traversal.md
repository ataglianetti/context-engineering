# Document Traversal

**When a file is mentioned, opened, or relevant:**
1. **Read it first** - Never respond about a document without reading it
2. **Follow frontmatter links** - Traverse `parent:`, `context:` to understand hierarchy
3. **Check related folders** - Documents/ contains specs, analysis, drafts
4. **Use what's documented** - If the answer exists in the vault, find it rather than guessing

**Frontmatter is navigation, not decoration.** The linking structure maps relationships. Use it.

## Temporal Context
For current state of any project or work item:
- Check recent Calendar/ daily notes for activity
- Look for Meeting Notes documents linked to the project
- Find Thread notes (emails, Slack, Teams) that capture ongoing conversations

**Anti-pattern:** Inferring from filenames or folder paths when actual document content is accessible.

## Degradation Strategy
- **Block and ask:** Cannot determine context, files don't exist, critical info requires guessing
- **Proceed with caveats:** Reasonable inference possible, partial info available
- **Never guess when you can read:** If a document exists that would answer the question, read it.
