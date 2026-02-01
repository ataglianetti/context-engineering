# Context Management System

This is a personal knowledge management vault. Claude instructions are loaded from `.claude/rules/`.

## First Time Setup

If you haven't run setup yet, type `/setup` to personalize this system for your role and work contexts.

## How This Works

**Rules in `.claude/rules/`** define Claude's behavior:
- `core/` files load every session (your profile, writing style, memory)
- `vault/` files define vault-wide patterns
- Context-specific files load when working with files in that context's folder

**Memory persists** in `.claude/rules/core/memory.md`. Claude reads this at session start and updates it when you end a session.

**Templates** in `_templates/` (source) get copied to `Resources/Templates/` during setup. Use with the Templater plugin for smart note creation.

## Key Commands

- `/setup` - Run the onboarding flow to personalize everything
- `/update-memory` - Manually update memory file

## Folder Structure

```
Contexts/           - Organizational contexts (work, personal)
Calendar/           - Daily notes, meetings, threads
Resources/          - Templates and reference materials
.claude/            - Claude Code configuration
  rules/            - Instruction files
  commands/         - Custom commands
_templates/         - Template source files
```

## Getting Help

Check `.claude/rules/` to understand current behavior. Edit files directly or ask Claude to update them.
