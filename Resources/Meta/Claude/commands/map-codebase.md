---
description: Map an existing codebase for agent consumption
---

Analyze this project's codebase and produce structured reference documents in `.planning/codebase/`. These docs are consumed by planner, implementer, and reviewer agents.

## How It Works

This command is an **orchestrator**. It spawns 4 mapper agents in parallel, each writing directly to output files. The coordinator stays lean — agents do the heavy lifting.

## Pre-Flight

1. Confirm we're in a project directory (look for `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, or `src/`/`lib/`/`app/` directories)
2. Create `.planning/codebase/` if it doesn't exist:
   ```bash
   mkdir -p .planning/codebase
   ```
3. Read `CLAUDE.md` for project context (if it exists)

## Spawn 4 Mapper Agents

Read the mapper agent template from `.claude/agents/mapper.md`. Then spawn all 4 agents **in parallel** using the Task tool:

### Agent 1: Tech Stack
```
Task: subagent_type=general-purpose
Prompt: [paste mapper.md content]

Focus area: tech
Project root: [current directory]
Output: Write directly to .planning/codebase/STACK.md

[Include CLAUDE.md project description if available]
```

### Agent 2: Architecture
```
Task: subagent_type=general-purpose
Prompt: [paste mapper.md content]

Focus area: arch
Project root: [current directory]
Output: Write ARCHITECTURE.md and STRUCTURE.md to .planning/codebase/

[Include CLAUDE.md project description if available]
```

### Agent 3: Conventions
```
Task: subagent_type=general-purpose
Prompt: [paste mapper.md content]

Focus area: conventions
Project root: [current directory]
Output: Write CONVENTIONS.md and TESTING.md to .planning/codebase/

[Include CLAUDE.md project description if available]
```

### Agent 4: Concerns
```
Task: subagent_type=general-purpose
Prompt: [paste mapper.md content]

Focus area: concerns
Project root: [current directory]
Output: Write directly to .planning/codebase/CONCERNS.md

[Include CLAUDE.md project description if available]
```

**All 4 Task calls in a single message.** Do not wait for one to finish before spawning the next.

## Post-Processing

After all 4 agents complete:

1. **Verify output.** Check that all 6 files exist in `.planning/codebase/`:
   - `STACK.md`
   - `ARCHITECTURE.md`
   - `STRUCTURE.md`
   - `CONVENTIONS.md`
   - `TESTING.md`
   - `CONCERNS.md`

2. **Report results:**
   ```
   Codebase mapped. 6 files in .planning/codebase/:
   - STACK.md (X lines) — languages, frameworks, dependencies
   - ARCHITECTURE.md (X lines) — layers, data flow, abstractions
   - STRUCTURE.md (X lines) — directory layout, naming
   - CONVENTIONS.md (X lines) — code style, patterns
   - TESTING.md (X lines) — test framework, patterns, mocking
   - CONCERNS.md (X lines) — tech debt, security, fragile areas
   ```

3. If any agent failed or produced empty output, report which and offer to re-run that focus area.

## When to Run

- **First time onboarding** an existing project (after `/new-project` scaffolds `.claude/`)
- **After major architectural changes** — re-map to keep docs current
- **Before a large refactor** — understand what exists before changing it

## Downstream Agent Usage

| Agent | Loads |
|-------|-------|
| Planner (UI work) | CONVENTIONS.md, STRUCTURE.md |
| Planner (API work) | ARCHITECTURE.md, CONVENTIONS.md |
| Planner (testing) | TESTING.md, CONVENTIONS.md |
| Planner (refactor) | CONCERNS.md, ARCHITECTURE.md |
| Implementer (any) | CONVENTIONS.md + relevant architecture docs |
| Reviewer | CONVENTIONS.md, CONCERNS.md |
