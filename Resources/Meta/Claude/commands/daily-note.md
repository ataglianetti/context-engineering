---
description: Generate daily note log from vault notes and git commits for a target date (default: today)
---

Generate a synthesized log for a daily note based on:
- **Calendar/** notes created that day (meetings, threads)
- **Contexts/** changes via git diff (PRDs, specs, portfolio items)
- **~/Projects** git commits

**Arguments:**
- No argument: today (current date)
- Date specifier: `"2026-02-19"`, `"yesterday"`, or any parseable date string

The target date flows through all steps below. When invoked by `/today` catch-up, a specific past date is passed.

**Prerequisite:** `Contexts/` must be a git repo. Initialize with `cd [vault-path]/Contexts && git init && git add . && git commit -m "Initial commit"` if not already set up.

**1. Find the daily note**
- Parse target date from argument (default: today via `currentDate`)
- Path: `Calendar/YYYY-MM-DD.md` (target date)
- If it doesn't exist, create it using the Daily Note template located here:
	- your Daily Note template, if you keep one

**2. Find notes touched on target date**

**Calendar/ folder** (meeting notes, threads):
- Search for files matching `Calendar/YYYY-MM-DD*.md` (target date prefix)
- Include types: Meeting, Thread
- These are event-based notes; their existence is the log entry
- **Sanity check:** If search returns zero results and target date is today, verify the query date matches the system date before assuming no notes exist. Zero Calendar notes on a workday warrants a second look.

**Contexts/ folder** (git-tracked):
- If target date is today: run `git status` and `git diff` for uncommitted changes, plus `git log --after="YYYY-MM-DD 00:00"` for today's commits
- If target date is in the past: run `git log --after="YYYY-MM-DD 00:00" --before="YYYY-MM-DD+1day 00:00"` to find commits from that date. No `git status`/`git diff` (uncommitted changes can't be attributed to past dates).
- **Always use `--after`/`--before` with explicit `HH:MM` times.** Git's `--since`/`--until` use `approxidate` (fuzzy parsing), which leaks commits across day boundaries. Bare dates like `--since="2026-04-14"` will include commits from the next morning. Explicit `HH:MM` bounds force clean day windows.
- For each changed file, extract the actual diff to summarize what changed (sections added, content removed, key edits)

Skip:
- The daily note itself
- Contexts/ files with no meaningful diff (whitespace, metadata-only)

**3. Scan git commits (GitHub + local)**

Two-pass approach: GitHub API for pushed commits (works across machines), then local scan for unpushed work.

**3a. GitHub commits (primary)**

Query pushed commits for the target date via `gh`:
```bash
# Get GitHub username
GH_USER=$(gh api user --jq '.login')

# Search commits for the target date (exact date match for backfill; >= for today)
# Backfill (past date): committer-date:YYYY-MM-DD (exact day)
# Today: committer-date:>=YYYY-MM-DD (same as before — catches ongoing work)
gh api "search/commits?q=author:${GH_USER}+committer-date:YYYY-MM-DD&sort=committer-date&per_page=100" \
  --header "Accept: application/vnd.github.cloak-preview+json" \
  --jq '.items[] | {sha: .sha[0:7], message: (.commit.message | split("\n") | .[0]), repo: .repository.full_name, url: .html_url}'
```

For each commit, extract:
- Short SHA
- Commit message (first line)
- Repository name (use last path segment as repo name)

**Repo to vault mapping:** Check `.claude/rules/vault/daily-notes.md` → "Git Repo Mapping" table. Match GitHub repo names to local repo paths in the mapping table (compare the repo name segment, e.g., `[github-org/repo]` matches `~/Projects/[repo-name]`). If a match exists, group under that vault project.

Skip:
- Merge commits
- Repos with no commits today
- Dependabot / automated commits

**3b. Local commit scan (supplement)**

After GitHub results are collected, scan ALL local commits for the target date window — not just unpushed. GitHub's `search/commits` API does not index private org repos, so pushed commits there are invisible to pass 3a and must be caught here. Do NOT use `--not --remotes` — it hides exactly those commits.

**Scan the mapped repos directly, not via `find`.** The mapping table in `daily-notes.md` is the source of truth for which repos belong in the daily note. `find ~/Projects -name .git` is unreliable: duplicate clones at different paths return both, causing attribution ambiguity. It also picks up unmapped personal experiments that clutter the log.

```bash
# Read mapped repo paths from daily-notes.md, then iterate
# (pseudocode — implementation reads the table in rules/vault/daily-notes.md)
#
# IMPORTANT: do NOT name loop variables `path`, `cdpath`, `fpath`, or `manpath`.
# In zsh these are tied to PATH/CDPATH/FPATH/MANPATH — iterating clobbers them
# and `git`, `head`, etc. disappear from the loop body. Commands fail silently
# when stderr is redirected to /dev/null. Use `repo` / `repo_path`.
for repo_pattern in "${MAPPED_REPOS[@]}"; do
  # Handle glob entries like ~/Projects/[org]/prototypes/*
  for repo_path in $repo_pattern; do
    [ -d "$repo_path/.git" ] || continue
    git -C "$repo_path" log --oneline \
      --after="YYYY-MM-DD 00:00" \
      --before="YYYY-MM-DD+1day 00:00" \
      --author="$(git -C "$repo_path" config user.email)" 2>/dev/null
  done
done
```

**Prototype mapping:** For repos matched via glob (`[org]/prototypes/*`), resolve vault project by matching the subdirectory name against Portfolio notes. Fall back to `Code: <subdirectory-name>` if no match.

**Unmapped repos:** If a commit comes back from pass 3a (GitHub) for a repo not in the mapping table, include it under `Code: repo-name`. This preserves the fallback for ad-hoc repos without needing find-based discovery.

This catches:
- Work committed locally but not yet pushed
- Repos not hosted on GitHub (local-only projects)
- Commits pushed to private org repos invisible to GitHub commit search

**Deduplication:** Build the union of pass 3a (GitHub) and pass 3b (local) keyed by short SHA. If the same commit appears in both, keep a single entry (not marked local).

**Local marker:** Only add a `(local)` marker for commits that are genuinely unpushed. Determine this per-commit with `git branch -r --contains <sha>` — if it returns no remote branches, the commit is local-only.

**Fallback:** If `gh` is not authenticated or the API call fails, fall back to the local-only scan (original behavior) and note the fallback in output.

**4. Read and extract key information**

For Calendar/ notes (meetings, threads):
- Title (from filename or `aliases:`)
- `context:` or `about:` to determine grouping
- One-line summary of what happened (from content, `one-liner:`, or summary section)
- **Accuracy:** The 3-8 word summary must come from what the note actually says. If the meeting summary is vague, the daily note stays vague — do not sharpen. Preserve the specificity level of the source.

For Contexts/ notes (git-tracked):
- Title (from filename or `aliases:`)
- `context:` or `parent:` to determine grouping
- One-line summary of what actually changed based on the diff (e.g., "Added success metrics section, removed MVP scope item")

For git commits:
- If repo has a vault mapping, group under that project (commits appear alongside related vault notes)
- If no mapping, use `Code: repo-name` as grouping
- Summarize related commits into coherent work items (don't list every commit separately if they're part of the same feature/fix)

**5. Generate the log**

Format:
```markdown
## Log

**[Context Name]**
- [[Project A]]
	- [[YYYY-MM-DD Note Title|Short Name]] - key outcome (3-8 words)
	- [[Another Note|Name]] - summary
- [[Project B]]
	- Vault work described in plain text
	- `a1b2c3d` brief description of code work

**[Context Name]**
- [[Project C]]
	- [[Note|Name]] - summary

**Personal**
- [[Project D]]
	- Summary of vault work, `a1b2c3d` combined description
```

Rules:
- **Context headers:** Bold text (`**[Context Name]**`)
- **Whitespace:** Blank line between context groups only (not between projects)
- **Summaries:** 3-8 words max, key outcome only (not run-on sentences)
- **Meetings/threads:** Wikilink with alias + short summary
- **Vault work:** Plain text description (no prefix)
- **Code work:** Commit ID in backticks + brief description (e.g., `` `a1b2c3d` added provider ``)
- **Combined work:** If both vault and code work, combine naturally
- Use full wikilinks on parent items, no aliases
- Use aliases on nested items (strip date prefix, shorten long titles)
- For unmapped repos, use repo name as parent under appropriate context
- Synthesize related commits into a single summary line (use most recent commit ID)
- Drop items that don't fit a project (insignificant at daily/weekly level)

**6. Update the daily note**

Replace the `## Log` section content with the generated log.

**Remove the `## Today Briefing` section** (and its subsections: Meetings, Upcoming Milestones, Reminders). That section is populated by `/today` in the morning for the day ahead — it's stale ephemeral context by the time `/daily-note` runs at end of day. The Log is the historical record; the Today Briefing was scaffolding for the day.

Preserve:
- Frontmatter
- Any other user-authored sections (e.g., manual notes, Highlights)

**7. Commit Contexts/ changes (today only)**

After generating the log, commit Contexts/ changes to establish a clean baseline for tomorrow:
- `cd [vault-path]/Contexts && git add . && git commit -m "Daily snapshot: YYYY-MM-DD"`
- This ensures tomorrow's diff only shows tomorrow's work

**Skip this step when target date is in the past.** Backfill runs should not create snapshot commits — the current working tree state belongs to today, not the backfilled date.

**8. Output**

Show the updated log section. Confirm:
- Number of Calendar/ notes processed
- Number of Contexts/ files with changes (and brief diff summary)
- Number of repos scanned, commits found

If any notes couldn't be categorized, list them and ask if grouping is correct.
