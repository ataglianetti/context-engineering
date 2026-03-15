# Context Management System

A personal knowledge management vault with persistent memory, modular rules, and mechanical enforcement.

## First Time Setup

If `.claude/rules/core/user-profile.md` still contains placeholder text, run `/setup` to personalize this system. Setup interviews you about your role, organizations, people, projects, and working style, then generates your rules.

## How This Works

**Rules** in `.claude/rules/` define Claude's behavior:
- `core/` files load every session — your profile, writing style, memory, session protocol
- `vault/` files define vault-wide patterns — file management, daily notes, summarization
- Context-specific folders (e.g., `rules/acme-corp/`) load only when working with files in that context's folder

**Memory** persists across sessions via two files:
- `core/work-state.md` — per-project status, updated every session close
- `core/memory.md` — decisions, open threads, patterns, updated when things change

**Hooks** enforce rules mechanically:
- `validate-frontmatter.sh` — blocks writes missing `type:` or `context:` (hard wall)
- `validate-dates.sh` — blocks stale dates in memory/work-state files
- `validate-wikilinks.sh` — warns on orphan wikilinks (soft wall)

**Templates** in `Resources/Templates/` define frontmatter structure for each note type. Use with the Templater plugin.

## Commands

| Command | Purpose |
|---------|---------|
| `/setup` | First-time onboarding — personalize rules, create contexts, configure commands |
| `/today` | Morning briefing — meetings, open items, threads |
| `/daily-note` | End-of-day log from vault activity and git commits |
| `/meeting-notes` | Format rough meeting notes into structured note |
| `/first-light` | Morning journal with dictation cleanup |
| `/last-light` | Evening journal with dictation cleanup |
| `/save-thread` | Save email/Slack/Teams thread as Thread note |
| `/update-thread` | Add replies to existing Thread note |
| `/draft-reply` | Draft reply to a Thread note |
| `/weekly-note` | Weekly summary synthesized from daily notes |
| `/project-status` | Status update for projects in a context |
| `/save-reference` | Process article/video into Reference note |
| `/research` | Deep research with web search, capture to vault |
| `/new-project` | Bootstrap a coding project with agent orchestration |
| `/refresh` | Re-onboarding interview to update rules |
| `/update` | Pull scaffolding updates from upstream without touching content |
| `/update-memory` | Manually trigger session close memory updates |

## Folder Structure

```
Contexts/           - Organizational contexts (work, personal)
Calendar/           - Daily notes, meetings, threads
Resources/
  Templates/        - Note templates (Templater-powered)
  Frameworks/       - Operational tools, decision models
  Reference/        - External articles, resources
  Definitions/      - Standard terms
Resources/Meta/Claude/  - System config (visible to Obsidian, synced across devices)
  rules/                - Modular instruction files
    core/               - Always loaded (profile, memory, writing style)
    vault/              - Vault-wide patterns (file management, daily notes)
  commands/             - Slash commands
  hooks/                - PostToolUse validation scripts
.claude -> Resources/Meta/Claude  (symlink for Claude Code compatibility)
```

## Architecture

The system separates **scaffolding** (rules, memory, hooks, templates) from **content** (your notes, people, projects, decisions). The scaffolding is universal. The content is yours.

Rules load based on file paths — edit a file in `Contexts/Acme Corp/` and Acme-specific rules activate. Core rules load always. This keeps context budgets focused: ~3K tokens always present, plus only what's relevant to current work.

For the deep dive on this architecture, see the [Substack series](https://ataglianetti.substack.com/).
