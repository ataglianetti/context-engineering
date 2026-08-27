---
description: Bootstrap a new coding project with agent orchestration
---

Scaffold a coding project with agent templates, orchestration rules, and project memory. Handles both **greenfield** (new project) and **brownfield** (existing code).

## Interview

Use `AskUserQuestion` to gather project details. 4 questions:

### Question 1: Project Name
```
question: "What's the project name?"
header: "Name"
options:
  - label: "[Use $ARGUMENTS if provided]"
    description: "From command argument"
  - label: "Enter name"
    description: "I'll ask for the name"
```

If `$ARGUMENTS` is provided, use it as the project name and skip this question.

Default path: `~/Projects/{kebab-case-name}`

### Question 2: Project Type
```
question: "What type of project?"
header: "Type"
options:
  - label: "CLI"
    description: "Command-line tool"
  - label: "Web App"
    description: "Frontend or full-stack web application"
  - label: "API"
    description: "Backend API service"
  - label: "Library"
    description: "Reusable package/library"
```

### Question 3: Tech Stack
Pre-fill based on project type, let user override:

| Type | Default Stack |
|------|--------------|
| CLI | TypeScript + Node.js |
| Web App | TypeScript + React + Vite |
| API | TypeScript + Express |
| Library | TypeScript |

```
question: "Tech stack? Default: {pre-filled based on type}"
header: "Stack"
options:
  - label: "{default for type} (Recommended)"
    description: "Standard setup for {type}"
  - label: "Python"
    description: "Python project"
  - label: "Rust"
    description: "Rust project"
```

### Question 4: Vault Context
```
question: "Link to a vault context?"
header: "Context"
options:
  - label: "None"
    description: "Standalone project, no vault link"
```

List context options from your `Contexts/` folder. For example:
  - `[Context 1]` -- "Link as Lab initiative under [Context 1]"
  - `[Context 2]` -- "Link as Lab initiative under [Context 2]"

## Detect Greenfield vs Brownfield

After gathering answers, check the target path:

```bash
ls ~/Projects/{kebab-case-name}/
```

**Brownfield indicators** (any of):
- Directory exists AND contains source files (`.ts`, `.js`, `.py`, `.rs`, `.go`, etc.)
- `package.json`, `Cargo.toml`, `pyproject.toml`, or `go.mod` exists
- `src/`, `lib/`, or `app/` directory exists

**If brownfield detected:**
> This project has existing code at `~/Projects/{name}`. Switching to onboarding mode -- I'll add agent scaffolding without touching your source.

## Greenfield Scaffolding

Create the full project structure:

```
~/Projects/{name}/
├── CLAUDE.md
├── .claude/
│   ├── agents/
│   │   ├── researcher.md
│   │   ├── planner.md
│   │   ├── implementer.md
│   │   ├── verifier.md
│   │   ├── debugger.md
│   │   └── reviewer.md
│   ├── commands/
│   │   └── map-codebase.md
│   └── settings.json
├── .planning/
│   └── STATE.md
├── .gitignore
└── README.md
```

### Steps:

1. Create directories:
   ```bash
   mkdir -p ~/Projects/{name}/.claude/agents ~/Projects/{name}/.claude/commands ~/Projects/{name}/.planning
   ```

2. **Copy agent templates** from vault:
   - Read each file from `.claude/agents/` (researcher, planner, implementer, verifier, debugger, reviewer)
   - Write to `~/Projects/{name}/.claude/agents/`

3. **Copy map-codebase command** from vault:
   - Read `.claude/commands/map-codebase.md`
   - Write to `~/Projects/{name}/.claude/commands/map-codebase.md`

4. **Create .claude/settings.json:**
   ```json
   {}
   ```

5. **Create .planning/STATE.md:**
   ```markdown
   # Project State

   ## Profile
   balanced

   ## Decisions
   | Date | Decision | Rationale |
   |------|----------|-----------|
   | {today} | Project created | {type} with {stack} |

   ## Position
   Project scaffolded. Ready for implementation.

   ## Blockers
   None.
   ```

6. **Create .gitignore** (adapt to stack):
   ```
   node_modules/
   dist/
   .env
   .env.*
   !.env.example
   .DS_Store
   *.log
   .planning/codebase/
   ```

7. **Create README.md:**
   ```markdown
   # {Project Name}

   {One-line description -- ask user or leave as TODO}

   ## Setup

   ```bash
   # TODO: setup instructions
   ```

   ## Development

   ```bash
   # TODO: dev instructions
   ```
   ```

8. **Generate CLAUDE.md** (see CLAUDE.md Generation section below)

9. **Ask to initialize git:**
   > Initialize git repo and create initial commit?

   If yes:
   ```bash
   cd ~/Projects/{name} && git init && git add -A && git commit -m "Initial project scaffold"
   ```

## Brownfield Scaffolding

Only add the agent infrastructure -- don't touch existing source:

1. Create `.claude/` structure:
   ```bash
   mkdir -p ~/Projects/{name}/.claude/agents ~/Projects/{name}/.claude/commands ~/Projects/{name}/.planning
   ```

2. **Copy agent templates** (same as greenfield step 2)

3. **Copy map-codebase command** (same as greenfield step 3)

4. **Create .claude/settings.json** (only if it doesn't exist)

5. **Create .planning/STATE.md** (only if it doesn't exist):
   ```markdown
   # Project State

   ## Profile
   balanced

   ## Decisions
   | Date | Decision | Rationale |
   |------|----------|-----------|
   | {today} | Agent scaffolding added | Onboarding existing project |

   ## Position
   Existing project. Run `/map-codebase` to generate reference docs.

   ## Blockers
   None.
   ```

6. **Generate CLAUDE.md** -- with architecture section marked as placeholder:
   > **Architecture:** Run `/map-codebase` to populate.

   Only create if `CLAUDE.md` doesn't exist. If it exists, ask before overwriting:
   > CLAUDE.md already exists. Append orchestration section, or leave it?

7. **Offer to run map-codebase:**
   > This project has existing code. Map the codebase now? (spawns 4 parallel agents, takes ~2 min)

## CLAUDE.md Generation

The generated CLAUDE.md adapts to project type and stack. Structure:

```markdown
# {Project Name}

## Overview
{Type}: {one-line description}
Stack: {tech stack}

## Architecture
{For greenfield: "To be defined as the project takes shape."}
{For brownfield: "Run `/map-codebase` to populate. Reference docs land in `.planning/codebase/`."}

## Agent Orchestration

### When to Use Agents vs Direct Work

| Task Size | Approach | Example |
|-----------|----------|---------|
| Trivial (<10 lines, one file) | Direct edit | Fix a typo, add a log statement |
| Small (one feature, 1-3 files) | Direct edit or single agent | Add a utility function, simple endpoint |
| Medium (feature, 3-8 files) | Planner -> Implementer | New API endpoint with tests and validation |
| Large (cross-cutting, 8+ files) | Research -> Plan -> Implement (waves) -> Verify -> Review | Auth system, major refactor, new subsystem |

### How to Spawn Agents

1. Read the agent template from `.claude/agents/{agent}.md`
2. Use the Task tool with the template as part of the prompt
3. Include relevant context (codebase docs, prior agent output, specific files)
4. Set model based on current profile (see Model Profiles below)

Example:
```
Task: subagent_type=general-purpose, model={from profile}
Prompt: [agent template content]

Context: [what the agent needs to know]
Task: [specific work to do]
```

### Wave Execution

For multi-task plans from the planner:
1. Execute all tasks in Wave 1 in parallel (separate Task calls in one message)
2. Wait for Wave 1 to complete
3. Review results -- adjust Wave 2 if needed
4. Execute Wave 2 tasks in parallel
5. Repeat until plan is complete
6. Run verifier against the original goal

### Model Profiles

Current profile is set in `.planning/STATE.md`. Default: `balanced`.

| Profile | Researcher | Planner | Implementer | Verifier | Debugger | Reviewer | Mapper |
|---------|-----------|---------|-------------|----------|----------|----------|--------|
| `quality` | opus | opus | opus | sonnet | opus | sonnet | sonnet |
| `balanced` | opus | opus | sonnet | sonnet | opus | sonnet | haiku |
| `budget` | sonnet | sonnet | sonnet | haiku | sonnet | haiku | haiku |

Override per-spawn by passing `model` explicitly to Task.

## Context Budget

### When to Spawn Fresh Agents
- Investigation is getting long (10+ file reads without clear direction)
- Switching from one subsystem to another
- After completing a wave -- fresh context for each wave

### Save State Before Switching
When moving between tasks or subsystems, update `.planning/STATE.md`:
- What was just completed
- What's next
- Any blockers or open questions

## Worktree Patterns

### When to Use Worktrees
- Parallel implementation of independent features
- Exploratory changes that might be thrown away
- When two tasks touch the same files (avoid conflicts)

### Workflow
1. Use `isolation: "worktree"` parameter on Task tool
2. Agent works in isolated copy of the repo
3. If changes are good, merge the worktree branch
4. If changes are bad, discard the worktree

{CONDITIONAL: Type-specific section below}
```

### Type-Specific Sections

**CLI projects -- append:**
```markdown
## CLI Conventions
- Entry point: `src/index.ts` (or `src/main.ts`)
- Argument parsing: use a library (commander, yargs, clap) -- not manual argv parsing
- Exit codes: 0 for success, 1 for user error, 2 for system error
- Output: stdout for results, stderr for diagnostics
- Config: support both CLI flags and config file
```

**Web App projects -- append:**
```markdown
## Web App Conventions
- Component structure: one component per file, co-located styles/tests
- State management: [to be decided]
- Routing: [to be decided]
- API calls: centralized in services/ directory
```

**API projects -- append:**
```markdown
## API Conventions
- Route handlers: thin -- validate, call service, return response
- Business logic: in services/ directory
- Validation: at the boundary (request handlers), not deep in services
- Error responses: consistent format across all endpoints
```

**Library projects -- append:**
```markdown
## Library Conventions
- Public API: exported from `src/index.ts`
- Internal modules: not exported, implementation details
- Types: exported alongside functions that use them
- Documentation: JSDoc on all public exports
```

## Vault Context Linking

If a vault context was selected:

1. Create an Initiative note in the vault:
   ```
   Contexts/{Context}/Lab/{Project Name}.md
   ```

2. Frontmatter:
   ```yaml
   ---
   type: Initiative
   context: "[[{Context}]]"
   status: Active
   created: {today}
   ---
   ```

3. Body:
   ```markdown
   # {Project Name}

   {One-line description}

   ## Links
   - Repository: `~/Projects/{kebab-case-name}`
   ```

## Output

After scaffolding is complete, summarize:

```
Project scaffolded at ~/Projects/{name}:
- Agent templates: 6 agents in .claude/agents/
- Commands: map-codebase in .claude/commands/
- Project memory: .planning/STATE.md
- Orchestration: CLAUDE.md with agent/budget/worktree rules
{- Vault link: Contexts/{Context}/Lab/{Name}.md (if applicable)}
{- Git: initialized with initial commit (if applicable)}
{- Brownfield: run /map-codebase to generate reference docs (if applicable)}
```
