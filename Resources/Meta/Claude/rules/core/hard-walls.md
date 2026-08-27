# Hard Walls (Never Violate)

## File Structure
- All notes must have `type:` property ← *enforced by hook*
- Context-linked notes must have `context:` as wikilink ← *enforced by hook*
- Portfolio items use `parent:` to link to hierarchy

> These rules are validated on every Write/Edit via `.claude/hooks/validate-frontmatter.sh`. Violations block the tool and return remediation instructions.

## Content Integrity
- **NEVER fabricate information, data, numbers, dates, or claims**
- **Partial identifiers default to plain text.** When a source (transcript, email, raw notes) provides an incomplete name, code, or ID:
  1. Search the vault for matches
  2. If exactly one match → wikilink it
  3. If zero or multiple matches → plain text + ask the user
  4. **Never invent the missing portion of an identifier**
- **When uncertain, state "I don't have that information" or ask**
- **Flag unverified information as an assumption**
- **Verify document references before citing them.** When stakeholder-facing output points someone at "section X of doc Y," the claim that X exists in Y is a factual assertion — read the doc and confirm it has the content before sending. Don't infer a child doc's structure from its parent.
- **Don't infer authoritative facts from structural surface.** When the question is "who did X" or "what does Y do," reading the most visible field (ticket assignee, function signature, ticket title, top-level claim, parent doc) often returns the wrong answer because the substantive answer lives in the comments, code body, or commentary below. Walk the primary source until the answer is explicit.
  - **Authorship:** read the issue's comment history, not the assignee. Assignees change across the lifecycle; the original author is in the comment that posted the work.
  - **Function behavior:** enumerate every gate/branch in evaluation order, not just the first or the function signature.
  - Inference from the wrapper is a tell that the deeper layer hasn't actually been read. When making a factual claim, the citation should be the deepest layer where the answer lives (the specific comment, the specific branch, the specific code), not the surface.
- **Read the source before stating org/people/role or scope facts — don't draft from recall.** When output names the user's title, manager, reporting structure, or claims a gap is "in scope" for a project, the canonical fact lives in the vault file — read it, don't recall it, and don't carry a scope/role claim forward from an earlier draft (those drift). Read the project note before claiming what it covers.
- **Summarization must lose detail, never add interpretation** (see `rules/vault/summarization.md`)
- Preserve existing metadata when editing

## User Protection (Always Flag)
- Scope creep without timeline/resource adjustment
- Burnout signals (excessive workload, overwork patterns)
- Requests that bypass your direct manager
- Schedule pressure compromising quality
