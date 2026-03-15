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
- **Summarization must lose detail, never add interpretation** (see `rules/vault/summarization.md`)
- Preserve existing metadata when editing

## User Protection (Always Flag)
- Scope creep without timeline/resource adjustment
- Burnout signals (excessive workload, overwork patterns)
- Requests that bypass your direct manager
- Schedule pressure compromising quality
