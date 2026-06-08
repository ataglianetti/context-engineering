---
paths:
  - Calendar/**
---

# Daily Note Format

## Log Structure

**Context headers:** Bold text (`**[Context Name]**`)

**Whitespace:** Blank line between context groups only (not between projects within a context)

**Project bullets:** Full wikilinks (no aliases) as parent bullets

**Nested items:**
- Meetings/threads: `[[Note|Note Alias]] - key outcome (3-8 words)`
- Vault work: Plain text description
- Code work: Commit ID in backticks + brief description (e.g., `` `a1b2c3d` added provider ``)
- Combined: Natural sentences mixing vault and code

**Summary length:** 3-8 words max per item. Key outcome only, not run-on sentences.

**Do not include:**
- Open next steps from meeting notes. The `/today` command surfaces those on demand — daily notes log what happened, not what's pending.
- Cancelled meetings. If a Calendar note has no content (empty `## Notes` section), the meeting was cancelled — skip it in the log and delete the empty note.

Example:
```markdown
### Log

**[Organization A]**
- [[Project Alpha]]
	- [[2026-02-04 Weekly Standup|Standup]] - timeline risks flagged
	- [[2026-02-04 Design Review|Design Review]] - option B selected
- [[Project Beta]]
	- [[...|Thread Title]] - requirements documented

**[Organization B]**
- [[Project Gamma]]
	- Drafted ticket for autocomplete fix

**Personal**
- [[Side Project]]
	- Renamed project, split into free core + expansion
	- `a1b2c3d` template-first workflow
```

## Git Repo Mapping

Map your local repos to vault projects so `/daily-note` can attribute commits correctly.

| Repo Path | GitHub Repo Name | Vault Project |
|---|---|---|
| `~/Projects/[org]/[repo-name]` | `[repo-name]` | `[[Project Name]]` |
| `~/Projects/[repo-name]` | `[repo-name]` | `[[Project Name]]` |

**GitHub matching:** GitHub results use `owner/repo-name` format. Match on the repo-name segment (after `/`) against the GitHub Repo Name column. If the GitHub repo name doesn't appear in this table, fall back to matching against the last path segment of Repo Path.

**Unpushed commits:** Local-only commits get a `(local)` marker: `` `a1b2c3d` (local) added provider ``

Unmapped repos appear as `Code: repo-name`.

**Prototype convention:** If you keep prototypes in a shared directory (e.g. `~/Projects/[org]/prototypes/<feature-name>/`), the `/daily-note` scan can iterate that directory and match each subdirectory's name against the vault Portfolio — avoiding duplicate clones and mapping-table churn when prototypes are created.

## Contexts Snapshot (git attribution for vault work)

`/daily-note` finds same-day vault changes by running `git log --since/--until` over `Contexts/`. That only works if `Contexts/` is committed regularly — otherwise edits pile up uncommitted and can't be attributed to a specific date. Consider an automated job (cron or a scheduled agent) that auto-commits `Contexts/` once or twice daily so same-day `/daily-note` runs capture most work.
