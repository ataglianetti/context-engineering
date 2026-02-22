# Context OS — Personal Knowledge System Starter Kit

A personal operating system built on Claude Code and Obsidian. Persistent memory, modular rules, mechanical enforcement, and 14 commands that work for any knowledge worker.

Not a template library. An architecture.

## What This Is

Most AI productivity systems give you templates and commands. This gives you the scaffolding that makes templates and commands reliable:

- **Memory that persists** — Two-file split (work state + decisions) with session protocol. Claude knows what you were doing yesterday.
- **Context that loads** — Path-based rules. Work rules load for work files. Personal rules load for personal files. Neither pollutes the other.
- **Enforcement that blocks** — PostToolUse hooks validate every file write. Missing frontmatter? Blocked. Stale dates? Blocked. Orphan wikilinks? Warned.
- **Identity that adapts** — `/setup` interviews you and generates a thinking partner calibrated to your domain. Not a PM-specific challenger. Not a generic assistant. Yours.
- **Structure that navigates** — Frontmatter is a map, not decoration. Types, parents, contexts tell the AI how to traverse your vault.

## Quick Start

### 1. Clone

```bash
git clone https://github.com/ataglianetti/context-management-starter-kit.git
cd context-management-starter-kit
```

### 2. Open in Obsidian

1. Open Obsidian → "Open folder as vault"
2. Select the cloned folder
3. Click "Trust author and enable plugins"

### 3. Run Setup

```bash
claude
/setup
```

Answer the questions. Claude creates your context folders, people directory, portfolio items, thinking partner rules, and configures commands for your workflow. Takes about 10 minutes.

## What You Get

### Rules (12 files)

| File | Purpose |
|------|---------|
| `core/user-profile.md` | Your expertise, preferences, pacing |
| `core/thinking-partner.md` | Domain-calibrated thinking partner with stress test mode |
| `core/memory.md` | Decisions, open threads, learned patterns |
| `core/work-state.md` | Per-project status tracking |
| `core/session-protocol.md` | Session start/close behavior, memory updates |
| `core/writing-style.md` | Anti-AI tells, voice calibration, formatting |
| `core/hard-walls.md` | Never-violate constraints |
| `core/document-traversal.md` | How to navigate the vault graph |
| `core/intent-interpretation.md` | When to ask vs. proceed |
| `vault/file-management.md` | Note conventions, content patterns |
| `vault/daily-notes.md` | Daily note format, git repo mapping |
| `vault/summarization.md` | Accuracy rules for any summarization |

### Commands (14)

| Command | What it does |
|---------|-------------|
| `/setup` | First-time onboarding (6 phases) |
| `/today` | Morning briefing — meetings, open items, threads |
| `/daily-note` | End-of-day log from vault + git activity |
| `/meeting-notes` | Format rough notes into structured meeting note |
| `/first-light` | Morning journal with dictation cleanup |
| `/last-light` | Evening journal with dictation cleanup |
| `/save-thread` | Save email/Slack/Teams thread |
| `/update-thread` | Add replies to existing thread |
| `/draft-reply` | Draft reply with person context |
| `/weekly-note` | Weekly summary from daily notes |
| `/project-status` | Status update for a context's projects |
| `/save-reference` | Process article/video into Reference note |
| `/research` | Deep research with web search |
| `/refresh` | Re-onboarding to update stale rules |
| `/update-memory` | Manual session close |

### Hooks (3)

| Hook | Behavior | Enforcement |
|------|----------|-------------|
| `validate-frontmatter.sh` | Checks `type:` exists and is valid; checks `context:` on context-linked types | Blocks |
| `validate-dates.sh` | Ensures memory/work-state dates match today | Blocks |
| `validate-wikilinks.sh` | Finds wikilinks pointing to non-existent notes | Warns |

### Templates (20+)

Meeting, Thread, Document, Person, Context, Product, Platform, Initiative, Feature, Daily Note, Weekly Note, MOC, Definition, Reference, Post, Framework, and more.

## Architecture

```
.claude/
├── rules/
│   ├── core/           # Always loaded (~3K tokens)
│   │   ├── hard-walls.md
│   │   ├── user-profile.md
│   │   ├── thinking-partner.md
│   │   ├── memory.md
│   │   ├── work-state.md
│   │   ├── session-protocol.md
│   │   ├── writing-style.md
│   │   ├── document-traversal.md
│   │   └── intent-interpretation.md
│   ├── vault/          # Vault-wide patterns
│   │   ├── file-management.md
│   │   ├── daily-notes.md
│   │   ├── summarization.md
│   │   ├── clipboard.md
│   │   └── vault-structure.md
│   └── [context]/      # Created during /setup, loads per path
│       ├── context.md
│       └── collaborators.md
├── commands/           # 14 slash commands
├── hooks/              # PostToolUse validation
└── settings.json       # Hook configuration
```

**Core** loads every session. Your profile, memory, constraints, session mechanics. About 3K tokens.

**Vault** loads for anything in this workspace. File conventions, note structure, daily note format.

**Context-specific** loads only for matching file paths. Each context folder declares its paths in frontmatter:

```yaml
---
paths:
  - "Contexts/Acme Corp/**"
---
```

The result: focused context that changes with what you're working on, not a monolith that loads everything always.

## The Scaffolding/Content Split

This repo contains scaffolding — rules, templates, memory architecture, hooks, commands. It does not contain content — your notes, people, projects, decisions.

That's the design. `/setup` generates content from your answers. The scaffolding is universal. The content is yours.

A PM gets scope management and trade-off analysis in their thinking partner. An engineer gets architecture review and technical debt patterns. A researcher gets methodology challenge and evidence standards. Same scaffolding. Different generated content.

## Requirements

- [Obsidian](https://obsidian.md/) (free)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (requires Anthropic API access)
- macOS recommended (hooks use bash, icalBuddy for calendar)

## Customization

**Add a context:** Ask Claude to help, or create a folder in `Contexts/` and a matching rules folder.

**Modify rules:** Edit `.claude/rules/` files directly. Core rules are always-on. Context rules load per path.

**Add commands:** Create `.md` files in `.claude/commands/`. They become `/command-name` in Claude Code.

**Update your profile:** Run `/refresh` for a guided re-interview, or edit `user-profile.md` directly.

## Credits

Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) by Anthropic.

Context engineering principles from Aakash Gupta's "Context Engineering for PMs" — the framework alignment (Triple-I, 5-P, Two-Wall, N.O.W.) informed the rules architecture.
