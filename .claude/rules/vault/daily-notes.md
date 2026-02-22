---
paths:
  - Calendar/**
---

# Daily Note Format

## Log Structure

**Context headers:** Bold text (e.g., `**Organization Name**`)

**Whitespace:** Blank line between context groups only (not between projects within a context)

**Project bullets:** Full wikilinks (no aliases) as parent bullets

**Nested items:**
- Meetings/threads: `[[Note|Note Alias]] - key outcome (3-8 words)`
- Vault work: Plain text description
- Code work: Commit ID in backticks + brief description (e.g., `` `a1b2c3d` added provider ``)
- Combined: Natural sentences mixing vault and code

**Summary length:** 3-8 words max per item. Key outcome only, not run-on sentences.

**Do not include:** Open action items from meeting notes. The `/today` command surfaces those on demand — daily notes log what happened, not what's pending.

Example:
```markdown
### Log

**Organization A**
- [[Project A]]
	- [[2026-02-04 Meeting Title|Meeting Alias]] - key outcome here
	- [[Another Note|Short Name]] - summary of discussion
- [[Project B]]
	- Updated requirements document, added success metrics

**Organization B**
- [[Project C]]
	- Drafted ticket for autocomplete feature

**Personal**
- [[Side Project]]
	- `a1b2c3d` added new feature, refactored tests
```

## Git Repo Mapping

> **Configure during /setup.** Map your local repos to vault projects so `/daily-note` can group commits under the right project.

| Repo Path | GitHub Repo Name | Vault Project |
|-----------|-----------------|---------------|
| `~/Projects/example-repo` | `example-repo` | `[[Example Project]]` |

**GitHub matching:** GitHub results use `owner/repo-name` format. Match on the repo-name segment (after `/`) against the GitHub Repo Name column.

**Unpushed commits:** Local-only commits get a `(local)` marker: `` `a1b2c3d` (local) added provider ``

Unmapped repos appear as `Code: repo-name`.
