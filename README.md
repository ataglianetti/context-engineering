# Context Management Starter Kit

A personal knowledge management system powered by Claude. Organize your work across multiple contexts (jobs, projects, areas of focus) with AI that understands your role, relationships, and priorities.

## What This Is

This starter kit creates a structured Obsidian vault with:

- **Context folders** for each organization or area you work in
- **People tracking** for colleagues and contacts you interact with
- **Calendar integration** for meetings, daily notes, and email/Slack threads
- **Claude instructions** personalized to your role and working style
- **Persistent memory** so Claude remembers your priorities across sessions

## Quick Start

### 1. Get the Files

**Option A: Download ZIP**
- Click the green "Code" button above
- Select "Download ZIP"
- Unzip to a location of your choice

**Option B: Clone with Git**
```bash
git clone https://github.com/ataglianetti/context-management-starter-kit.git
```

### 2. Open in Obsidian

1. Open Obsidian
2. Click "Open folder as vault"
3. Select the `context-management-starter-kit` folder
4. Trust the folder when prompted

### 3. Run Setup

1. Open your terminal
2. Navigate to the vault folder:
   ```bash
   cd path/to/context-management-starter-kit
   ```
3. Start Claude Code:
   ```bash
   claude
   ```
4. Run the setup command:
   ```
   /setup
   ```
5. Answer the questions to personalize your system

That's it. Claude will create your context folders, set up people tracking, and configure itself to work the way you work.

## What /setup Does

The setup command guides you through a conversation to understand:

- **Your role** - What you do, what you're expert at, how you prefer to communicate
- **Your organizations** - Where you work, who you report to, key dynamics
- **Key people** - Who you work with regularly
- **Your work** - Current projects and priorities

Based on your answers, it creates:

- Context folders with people directories
- Personalized Claude instructions (so it knows your domain and style)
- Initial memory state (so future sessions have continuity)

## After Setup

### Templater Plugin (Recommended)

The templates in `Resources/Templates/` use [Templater](https://github.com/SilentVoid13/Templater). To use them:

1. Install Templater from Community Plugins
2. Set Template folder to `Resources/Templates`
3. Enable "Trigger Templater on new file creation"

This enables smart templates for meetings, documents, and people notes.

### Daily Workflow

- Create daily notes in `Calendar/` for logging work
- Use meeting templates to capture notes with automatic context/attendee linking
- Thread notes capture email and Slack conversations
- Claude references your vault to maintain context

### Claude Commands

After setup, you can ask Claude:

- "What am I working on?" (reads your memory and recent daily notes)
- "Summarize my meetings this week" (traverses Calendar/)
- "Who do I work with on [project]?" (checks people and context relationships)

## Folder Structure

```
Contexts/
├── [Your Org]/
│   ├── [Your Org].md       (folder note)
│   ├── Portfolio/          (projects, products, initiatives)
│   ├── People/             (colleagues, contacts)
│   └── Documents/          (context-level docs)
└── Personal/               (optional)

Calendar/                   (daily notes, meetings, threads)
Resources/Templates/        (note templates)

.claude/
├── rules/                  (Claude instructions)
│   ├── core/               (always loaded)
│   └── vault/              (vault-wide patterns)
└── commands/               (custom commands like /setup)
```

## Customization

### Adding Contexts

Run the Context template or ask Claude: "Help me add a new context for [organization]"

### Modifying Rules

Claude's behavior is defined in `.claude/rules/`. Key files:

- `core/user-profile.md` - Your expertise and communication style
- `core/thinking-partner.md` - When/how Claude should push back or support decisions
- `core/memory.md` - Persistent state across sessions

Edit these directly or ask Claude to update them based on what you learn works well.

### Adding Commands

Create new `.md` files in `.claude/commands/` to define custom commands.

## Requirements

- [Obsidian](https://obsidian.md/) (free)
- [Claude Code](https://claude.ai/claude-code) (requires API access)
- Optional: [Templater](https://github.com/SilentVoid13/Templater) plugin for smart templates

## Credits

Built with [Claude Code](https://claude.ai/claude-code) by Anthropic.

Inspired by the idea that AI assistants work better when they understand your context, not just your immediate request.
