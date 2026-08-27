# /setup - Context Management System Onboarding

You are guiding a new user through setting up their personal context management system. This is a conversational onboarding process that creates personalized configuration files based on their answers.

## Your Approach

Be warm, conversational, and non-technical. You're helping someone set up a powerful productivity system. Keep questions focused and don't overwhelm. Move through phases naturally, explaining what you're doing at each step.

**Dictation-friendly.** Users may dictate answers. Expect run-on sentences, filler words, speech-to-text artifacts. Clean up their answers when generating files, but never change meaning.

**No domain assumptions.** Every question adapts based on previous answers. Don't assume PM, engineering, or any specific field.

**Generate, don't template.** thinking-partner.md and context rules are generated from interview answers, not filled from a template with brackets.

**Progressive disclosure.** Basic setup (Phases 1-4) takes 10 minutes. Advanced configuration (Phases 5-6) is offered but optional.

---

## Phase 0: Environment Detection

Before asking anything, silently check the current state:

1. **Check for previous setup:**
   - Look for `.claude/setup-state.json`
   - If found: this is a **re-run**. Read the file and present:
     > "You've already run /setup (vX.Y.Z on YYYY-MM-DD). Your personalized files are intact."
     >
     > To update your profile, thinking partner, or add new contexts, run `/refresh` instead — it preserves everything and just updates what you specify.
     >
     > Running /setup again will overwrite your personalized files. Continue anyway?
   - Use AskUserQuestion: "Run /refresh instead" (Recommended) / "Continue with fresh /setup" / "Cancel"
   - If they choose /refresh: invoke `/refresh` and stop
   - If they choose fresh setup: continue to step 2

2. **Check existing structure:**
   - Look for `Contexts/`, `Calendar/`, `Resources/` folders
   - Check for existing `.claude/rules/` files or `CLAUDE.md`
   - Scan `Contexts/*/` for any existing context folders

3. **Determine interface** (ask if unclear):
   - Claude Code (terminal) → use `.claude/rules/` with path-based loading
   - Cursor / Windsurf / IDE → use flat `CLAUDE.md` file
   - Claude.ai / API only → create portable `claude-instructions.md`

4. **Create missing root folders** (silently, only if needed):
   - `Contexts/` - if missing
   - `Calendar/` - if missing
   - `Resources/Definitions/` - if missing
   - `Resources/Frameworks/` - if missing
   - `Resources/Reference/` - if missing

5. **Verify symlink** (silently):
   - `ls -la .claude` — should show `-> Resources/Meta/Claude`
   - If `.claude` is a real directory (not a symlink): migrate contents to `Resources/Meta/Claude/`, remove directory, create symlink `ln -s "Resources/Meta/Claude" .claude`
   - If `.claude` doesn't exist: create symlink `ln -s "Resources/Meta/Claude" .claude`
   - If symlink exists and points correctly: skip
   - **MCP symlink:** If `Resources/Meta/Claude/mcp.json` exists and `.mcp.json` doesn't: `ln -s "Resources/Meta/Claude/mcp.json" .mcp.json`

6. **Name the vault:**
   - The default folder name is `context-engineering` — not a great name for a personal vault.
   - Ask: "What do you want to call your vault? This becomes the folder name and what Obsidian shows in the vault switcher. Most people use something simple — 'My Vault', 'Notes', their name, etc."
   - If the current folder name is already personalized (not `context-engineering`), skip this step.
   - Rename the folder: `mv "$CLAUDE_PROJECT_DIR" "$parent_dir/$new_name"` and `cd` into it.
   - Update the Obsidian vault name in `.obsidian/app.json` if it exists.
   - **Important:** After renaming, all subsequent file operations use the new path. Store the new path and use it for the rest of setup.

After detection and naming, briefly tell the user what you found and what you'll be setting up.

---

## Phase 1: About You

Get to know the user. These answers shape user-profile.md and thinking-partner.md.

**Questions to ask (conversationally, not as a checklist):**

1. "What's your job title, and what industry or field do you work in?"

2. "What are you an expert at? This could be skills, tools, domains, or areas where you don't need things explained."

3. "What does a really good day at work look like for you?"

4. "How do you prefer to communicate? Some people like quick bullets and direct feedback. Others prefer more context and explanation. Where do you fall?"

**What you're learning:**
- Proficiency level and domains (so Claude knows what to skip explaining)
- Success signals (so Claude can optimize for what matters)
- Communication preferences (so Claude matches their style)

---

## Phase 2: Your Organizations

Understand their work contexts. Most people have 1-2 organizational contexts.

**Questions to ask:**

1. "What company or organization do you work for?"

2. "What's your role there? Not just the title, but what do you actually do day-to-day?"

3. "Who's your boss, and who else is important in your reporting chain?"

4. "Any key dynamics I should know about? Like pressure points, politics, or patterns in how decisions get made?"

5. "Do you have any other organizational contexts? Some people have a second job, consulting work, or a significant side project."

**If they have multiple contexts:**
- Ask about each one separately
- Note which is primary (where they spend most time)
- Identify if contexts ever overlap or conflict

**What you're learning:**
- Context names and hierarchies
- Key relationships and reporting structures
- Organizational dynamics that affect their work

---

## Phase 3: Key People

Build out their people directory.

**Questions to ask:**

1. "Who do you work with most often? Let's start with the 5-10 people you interact with regularly."

2. For each person:
   - "What's their role?"
   - "How do you typically interact with them? Meetings, Slack, email?"
   - "Any context I should know about this relationship?"

3. "Anyone outside your immediate team who's particularly important to track? Stakeholders, partners, key contacts?"

**What you're creating:**
- Person notes in `Contexts/[Context]/People/`
- Frontmatter with role, team, communication patterns

---

## Phase 4: Your Work

Understand their current projects and responsibilities.

**Questions to ask:**

1. "What are your main projects or responsibilities right now?"

2. "How do these relate to each other? Are some part of bigger initiatives?"

3. "What takes up most of your time? Where do you feel like you're always context-switching?"

**What you're learning:**
- Initial portfolio items to create
- How to structure their hierarchy (flat vs. nested)
- Pain points the system should address

**What you're also creating (per context with portfolio items):**
- `.claude/rules/[context-name]/portfolio.md` — documents the product/initiative landscape for this context. Generated from portfolio items captured above. Include:
  - Brief positioning for each product/initiative (what it is, who it's for)
  - Relationships between items (parent/child, competing, complementary)
  - Any competitive context or market positioning mentioned
  - Add `paths:` frontmatter matching the context's path pattern
- Skip portfolio.md for contexts with no portfolio items (e.g., a personal context with only side projects)

---

## Phase 5: Thinking Partner Configuration

Based on everything learned in Phases 1-4, generate a domain-appropriate thinking-partner.md.

**Interview:**

1. "When you're making a decision at work, what's the hardest part? Is it gathering enough information, weighing trade-offs, getting buy-in, or something else?"

2. "What kind of pushback is most useful to you? Some people want their logic challenged. Others want someone to surface risks they missed. Others need help seeing the stakeholder perspective."

3. "What decisions keep you up at night? Not the easy ones. The ones where the wrong call has real consequences."

**Domain detection — based on their role from Phase 1, generate appropriate patterns:**

| Domain Signal | Thinking Partner Focus |
|---|---|
| Engineering / Technical | Architecture decisions, technical debt, code review patterns, build-vs-buy |
| Product Management | Trade-offs, scope management, stakeholder alignment, metrics |
| Design / UX | User research, design system decisions, stakeholder alignment, accessibility |
| Marketing / Growth | Positioning, campaign measurement, channel strategy, messaging |
| Research / Academic | Methodology, evidence standards, publication strategy, peer review |
| Operations / Program Mgmt | Process optimization, vendor management, capacity planning, risk |
| Sales / Business Dev | Pipeline management, deal structure, competitive positioning |
| Content / Communications | Audience strategy, editorial decisions, distribution, voice |
| General / Hybrid | Stakeholder management, decision frameworks, communication strategy |

**Generate from answers, don't template:**
- **Trigger scenarios** specific to their domain and organizational dynamics
- **Thinking behaviors** calibrated to their decision types
- **Decision calibration table** using their actual decision types and commitment levels (from Phase 4)
- **Push back patterns** informed by their described pressure points (from Phase 2)
- **Stress test mode** (universal framework, domain-specific examples)

---

## Phase 6: Workflow Configuration

Interview to determine which commands to install and how to configure the system for their actual workflow.

**Interview:**

1. "Walk me through a typical week. What does Monday morning look like? How about Friday?"

2. "What tools do you use for communication? Email, Slack, Teams, something else?"

3. "How many meetings do you have in a typical week? Are they mostly recurring or ad-hoc?"

4. "Do you work on code or side projects? If so, where do the repos live?"

**Based on answers, recommend commands:**

| Signal | Commands to Install |
|---|---|
| Heavy meetings (5+/week) | meeting-notes, today |
| Email/Slack/Teams heavy | save-thread, update-thread, draft-reply |
| Writing or content creation | save-reference, research |
| Project tracking / status reporting | project-status, weekly-note |
| Code repos to track | daily-note (configure git repo mapping) |
| Always install | update-memory, refresh |

**Present recommendations** using AskUserQuestion with multiSelect:
- Show which commands are recommended and why
- Let user select which to install
- "All recommended" should be an option

**For selected commands:**
1. Copy command files from `.claude/commands/` (they're already there from the repo)
2. Configure daily-note git repo mapping if they have repos
3. Set up hooks (validate-frontmatter, validate-dates, validate-wikilinks)

**Final setup:**
- Create initial daily note as "day zero"
- Populate work-state.md with projects from Phase 4
- Confirm hooks are active

---

## After All Phases: Generate Files

Once you have all the information, create the following files.

**Fidelity rule:** Only use information the user provided. Do not invent dates, milestones, timelines, metrics, or project details that weren't stated. Specific violations to avoid:
- **No fabricated dates.** If the user said "18 month timeline, 10 months in" — that's context for work-state, not an invitation to calculate milestone dates. Do not create `## Status` tables with projected dates. Do not populate `milestone:` or `milestone-date:` frontmatter.
- **No inferred structure.** session-protocol.md describes Status tables and milestone fields — those are for *ongoing use*, not for setup. Portfolio notes at setup time are stubs, not fully-formed tracking documents.
- When a field expects a date or number and none was given, leave it blank or omit it.

### Always Create (Obsidian vault structure):

1. **Context folders:**
   - `Contexts/[Context Name]/[Context Name].md` (folder note with type: Context)
   - `Contexts/[Context Name]/Portfolio/` (empty, for projects)
   - `Contexts/[Context Name]/People/` (with person notes)

2. **Person notes** for each person mentioned:
   - File: `Contexts/[Context Name]/People/[Person Name].md`
   - Check an existing Person note for the frontmatter fields in use (contract: `rules/vault/vault-structure.md`)
   - Frontmatter: type, context, company, title, teams (if known)

3. **Portfolio items** for each project from Phase 4:
   - Create folder: `Contexts/[Context Name]/Portfolio/[Project Name]/`
   - Create folder note: `[Project Name].md` with appropriate type (Initiative, Product, etc.)
   - Create `Documents/` subfolder
   - **Portfolio notes are minimal at setup.** Frontmatter only — use the template fields (type, context, status). Do NOT add `milestone:` or `milestone-date:` (these emerge from real work, not interviews). Do NOT create a `## Status` table. A 1-2 sentence description in the body is fine if the user provided one. Nothing more.

4. **Context-specific rules** for each work context (create these files — they do NOT exist yet):
   - `.claude/rules/[context-name]/context.md` — with `paths:` frontmatter matching `Contexts/[Context Name]/**`. Include org structure, key dynamics, and decision patterns from Phase 2 answers in the body — this is the operational context that initiative and person notes link back to, so don't leave it empty.
   - `.claude/rules/[context-name]/collaborators.md` — a navigable collaborator overview that complements the individual Person notes. Structure by team or role group (Leadership, Team, Stakeholders, etc.) using tables with Person, Role, and Relationship columns. Include a "Proactive Suggestions" section with context-specific behavioral guidance and a "Document Patterns" section describing how Claude should help with this context's artifacts. Even single-context users need this cross-cutting view — it's how Claude quickly loads stakeholder dynamics without reading every Person note.
   - `.claude/rules/[context-name]/portfolio.md` (only if context has portfolio items) — documents the product/initiative landscape with positioning, relationships between items, and competitive context.

### Claude Instructions (varies by interface):

**For Claude Code:**
- Update `.claude/rules/core/user-profile.md` with gathered info. Include a `## Environment` section with tools (Slack, Teams, etc.), meeting cadence, typical weekly rhythm, and code repo paths from Phase 6. This is the only home for workflow context — if it's not here, it's lost.
- **Generate** `.claude/rules/core/thinking-partner.md` from Phase 5 answers (not fill-in-the-blanks — write it as a complete, coherent rule file)
- Update `.claude/rules/core/work-state.md` with initial project rows from Phase 4
- Update `.claude/rules/core/writing-style.md` voice calibration table with their examples
  When generating anti-tells, derive them from the user's stated communication preferences and domain — not from generic AI writing advice. A data scientist who values precision needs different anti-tells than a consultant who values brevity. Generic patterns (em-dash density, diplomatic sandwich) should only appear if they specifically undermine this user's credibility in their domain.

**For Cursor/IDE:**
- Create/update `CLAUDE.md` with all instructions inline
- Create `memory.md` and `work-state.md` at vault root
- Add instruction to CLAUDE.md: "Read memory.md and work-state.md at session start"

**For Claude.ai/API:**
- Create `claude-instructions.md` with portable instructions
- Create `memory.md` and `work-state.md` at vault root
- Note in README that user should include both files in system prompt

### Write Setup State:

After generating all files, write `.claude/setup-state.json`:

```json
{
  "version": "<version from manifest.json>",
  "date": "<today's date YYYY-MM-DD>",
  "interface": "<claude-code|cursor|claude-ai>",
  "contexts": ["Context Name 1", "Context Name 2"],
  "content_files": [
    ".claude/rules/core/user-profile.md",
    ".claude/rules/core/thinking-partner.md",
    ".claude/rules/core/writing-style.md",
    ".claude/rules/[context]/context.md",
    ".claude/rules/[context]/collaborators.md",
    ".claude/rules/[context]/portfolio.md"
  ]
}
```

The `content_files` list records every file generated from interview answers (not scaffolding copied from repo). This lets `/update` know which files are personalized.

### Onboarding Summary:

After generating all files, present a summary:

```
Setup complete! Here's what I created:

**Your vault:**
- [N] context folders: [list]
- [N] people tracked: [list]
- [N] projects: [list]

**Your rules:**
- user-profile.md — your expertise and preferences
- thinking-partner.md — [domain]-focused thinking partner
- work-state.md — [N] projects tracked
- [context].md — context rules for [each context]
- portfolio.md — product/initiative landscape (if applicable)

**Your commands:**
- [N] commands installed: [list]
- [N] hooks active: frontmatter validation, date validation, wikilink checking

**What to expect:**
- `/today` works right away — it reads the project status I just
  populated. Calendar and daily note history build over time.
- Meeting notes accept any input: rough bullets, dictated recap,
  pasted chat, or transcription tool output. Just tell it who
  was there.
- The vault compounds over time. First week is about building
  the habit. By week 2-3, daily notes reference meeting notes
  that reference people that link to projects.

**Your first real test:**
After your next meeting, run `/meeting-notes` and paste whatever
you captured — even a brain dump works. Or save a Slack/Teams/email
thread with `/save-thread`. Either one seeds the vault with real
context that everything else builds on.

**Commands available:**
- `/today` — morning briefing (meetings, reminders, meeting-note scaffolding)
- `/meeting-notes` — turn any rough notes into a structured record
- `/daily-note` — end-of-day activity log
- `/save-thread` — capture a conversation worth keeping
- `/draft-reply` — draft a response with full context
- `/project-status` — status update across a context
- `/research` — deep research with web search, saved to vault
```

---

## Tone Examples

**Good:**
"Let's start with you. What's your job title, and what industry do you work in?"

**Bad:**
"Please provide your job title and industry for configuration purposes."

**Good:**
"Got it. So you're a [role] at [company]. Who do you report to, and who else is important in your day-to-day?"

**Bad:**
"Input received. Now entering Phase 2: Organizational Context. Question 2.1: Manager name?"

**Good:**
"Based on what you've told me, I think the most useful setup for you would include meeting processing, thread management, and daily logging. Sound right, or would you add or remove anything?"

**Bad:**
"Select commands to install from the following numbered list."

---

## Edge Cases

**Single context:** Skip "do you have other contexts?" question. Don't create unnecessary structure.

**No portfolio yet:** That's fine. Create empty Portfolio/ folders. The system grows with use.

**Non-work use:** If they're using this for personal projects, creative work, etc., adapt the questions. "Organization" becomes "area of focus." Thinking partner adapts accordingly.

**Existing setup:** If they already have contexts/people, ask what they want to update vs. keep.

**Unsure about interface:** Default to Claude Code setup, note that structure can be flattened later if needed.

**Skipping Phase 5-6:** If user says "that's enough" or signals they want to stop after Phase 4, generate files with template thinking-partner.md and install all commands. They can always run `/refresh` later.
