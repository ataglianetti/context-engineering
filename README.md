# Context OS — Personal Knowledge System Starter Kit

A personal operating system built on Claude Code and Obsidian. Persistent memory, modular rules, mechanical enforcement, and 17 commands that work for any knowledge worker.

Not a template library. An architecture.

## What This Is

Most AI productivity systems give you templates and commands. This gives you the scaffolding that makes templates and commands reliable:

- **Memory that persists** — Two-file split (work state + decisions) with session protocol. Claude knows what you were doing yesterday.
- **Context that loads** — Path-based rules. Work rules load for work files. Personal rules load for personal files. Neither pollutes the other.
- **Enforcement that blocks** — PostToolUse hooks validate every file write. Missing frontmatter? Blocked. Stale dates? Blocked. Orphan wikilinks? Warned.
- **Identity that adapts** — `/setup` interviews you and generates a thinking partner calibrated to your domain. Not a PM-specific challenger. Not a generic assistant. Yours.
- **Structure that navigates** — Frontmatter is a map, not decoration. Types, parents, contexts tell the AI how to traverse your vault.

## Before You Start

**This is an Obsidian vault** — a markdown-based personal knowledge system. You'll work in Obsidian (notes, links, daily logs), not an IDE. Claude Code is the AI layer that makes it intelligent.

**`/setup` makes it yours.** The repo is scaffolding: rules, templates, hooks. When you run `/setup`, it interviews you and generates a thinking partner calibrated to your domain, context folders for your work, and memory files that persist across sessions. Ten minutes, and the generic scaffold becomes your system.

**What you need installed:**

- [Obsidian](https://obsidian.md/) (free) — where you read and write notes
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) — the AI layer (requires an Anthropic API key)
- A place to run Claude Code: [Cursor](https://cursor.com/), VS Code, or your system terminal

**Platform note:** macOS gets the fullest experience (calendar integration, rich clipboard). Linux and Windows work for everything else; a few commands may need adaptation.

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

### Rules (15 files)

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
| `vault/clipboard.md` | Clipboard copy formatting for external apps |
| `vault/confidence-convention.md` | Confidence flagging for research output |
| `vault/vault-structure.md` | Note types, hierarchy, portfolio patterns |

### Commands (17)

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
| `/new-project` | Bootstrap a coding project with agent orchestration |
| `/refresh` | Re-onboarding to update stale rules |
| `/update` | Pull scaffolding updates without touching content |
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
│       ├── collaborators.md
│       └── portfolio.md    # if context has portfolio items
├── commands/           # 17 slash commands
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

### Obsidian Sync Support

During `/setup`, the `.claude/` directory is migrated to `Resources/Meta/Claude/` with a symlink back:

```
Resources/Meta/Claude/    ← actual files (visible to Obsidian, synced across devices)
.claude -> Resources/Meta/Claude   ← symlink (Claude Code still finds everything)
```

This matters because Obsidian Sync ignores hidden folders. Without the migration, your rules, commands, and hooks are invisible to Obsidian and won't sync to other devices.

**Constraints to know:**
- Hidden folders (`.claude/`) are not synced by Obsidian Sync — the symlink pattern solves this
- Unix file permissions are not preserved across sync — hooks use `bash script.sh` invocation, never rely on execute permission
- Symlinks themselves are not synced — run `ln -s "Resources/Meta/Claude" .claude` once per device

## The Scaffolding/Content Split

This repo contains scaffolding — rules, templates, memory architecture, hooks, commands. It does not contain content — your notes, people, projects, decisions.

That's the design. `/setup` generates content from your answers. The scaffolding is universal. The content is yours.

A PM gets scope management and trade-off analysis in their thinking partner. An engineer gets architecture review and technical debt patterns. A researcher gets methodology challenge and evidence standards. Same scaffolding. Different generated content.

## Updating

The system separates **scaffolding** (rules, commands, hooks) from **content** (your profile, thinking partner, memory, work state). This means you can pull improvements without losing your personalized setup.

```bash
claude
/update
```

`/update` reads `.claude/manifest.json` to classify every file. Scaffolding files get overwritten with upstream versions. Content files are never touched. Hybrid files (like `writing-style.md`, where your voice calibration rows are user content but the anti-AI tell rules are scaffolding) get section-level merges.

The flow: fetch upstream manifest, compare versions, diff scaffolding files, present a summary, apply with your approval. No merge conflicts, no git gymnastics.

If you cloned before `/update` existed (no `manifest.json`), running `/update` detects the legacy install and establishes the baseline.

## Customization

**Add a context:** Ask Claude to help, or create a folder in `Contexts/` and a matching rules folder.

**Modify rules:** Edit `.claude/rules/` files directly. Core rules are always-on. Context rules load per path.

**Add commands:** Create `.md` files in `.claude/commands/`. They become `/command-name` in Claude Code.

**Update your profile:** Run `/refresh` for a guided re-interview, or edit `user-profile.md` directly.

## Research

Two 2026 papers provide empirical support for the modular, human-curated architecture this system uses:

| Paper | Key Finding | Implication |
|-------|-------------|-------------|
| [Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) — Gloaguen et al. (ETH Zurich) | LLM-generated context files *reduce* task success while increasing cost 20%+. Developer-written files help marginally. | Auto-generated monolithic prompts hurt. Human curation and minimal, targeted instructions are what work. |
| [SkillsBench](https://arxiv.org/abs/2602.12670) — Li et al. | Curated skills raise pass rates +16.2pp. 2-3 focused modules outperform comprehensive docs. Smaller model + skills > larger model without. | Modular beats monolithic. Context engineering is a capability multiplier, but only when curated by someone with domain knowledge. |

Both papers independently confirm: self-generated context is flat or harmful, comprehensive documentation degrades performance, and the value comes from human judgment about what to include and what to leave out.

## Credits

Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) by Anthropic.

Context engineering principles from Aakash Gupta's "Context Engineering for PMs" — the framework alignment (Triple-I, 5-P, Two-Wall, N.O.W.) informed the rules architecture.
