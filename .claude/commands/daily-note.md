---
description: Generate daily note log from today's vault notes and git commits
---

Generate a synthesized log for today's daily note based on:
- **Calendar/** notes created today (meetings, threads)
- **Contexts/** changes via git diff (PRDs, specs, portfolio items)
- **~/Projects** git commits

**Prerequisite:** `Contexts/` must be a git repo. Initialize with `cd [vault-path]/Contexts && git init && git add . && git commit -m "Initial commit"` if not already set up.

**1. Find today's daily note**
- Path: `Calendar/YYYY-MM-DD.md` (current date)
- If it doesn't exist, create it using the Daily Note template located here:
	- Resources/Templates/Daily Note.md

**2. Find notes touched today**

**Calendar/ folder** (meeting notes, threads):
- Search for files created today (use file creation date)
- Include types: Meeting, Thread
- These are event-based notes; their existence is the log entry
- **Sanity check:** If search returns zero results, verify the query date matches the system date before assuming no notes exist. Zero Calendar notes on a workday warrants a second look.

**Contexts/ folder** (git-tracked):
- Run `git status` and `git diff` to find files with uncommitted changes
- Run `git log --since="midnight"` to find files committed today
- For each changed file, extract the actual diff to summarize what changed (sections added, content removed, key edits)

Skip:
- The daily note itself
- Contexts/ files with no meaningful diff (whitespace, metadata-only)

**3. Scan git commits (GitHub + local)**

Two-pass approach: GitHub API for pushed commits (works across machines), then local scan for unpushed work.

**3a. GitHub commits (primary)**

Query today's pushed commits via `gh`:
```bash
# Get GitHub username
GH_USER=$(gh api user --jq '.login')

# Search commits authored today
gh api "search/commits?q=author:${GH_USER}+committer-date:>=YYYY-MM-DD&sort=committer-date&per_page=100" \
  --header "Accept: application/vnd.github.cloak-preview+json" \
  --jq '.items[] | {sha: .sha[0:7], message: (.commit.message | split("\n") | .[0]), repo: .repository.full_name, url: .html_url}'
```

For each commit, extract:
- Short SHA
- Commit message (first line)
- Repository name (use last path segment as repo name)

**Repo to vault mapping:** Check `.claude/rules/vault/daily-notes.md` -> "Git Repo Mapping" table. Match GitHub repo names to local repo paths in the mapping table (compare the repo name segment, e.g., `user/[repo-name]` matches `~/Projects/[repo-name]`). If a match exists, group under that vault project.

Skip:
- Merge commits
- Repos with no commits today
- Dependabot / automated commits

**3b. Local unpushed commits (supplement)**

After GitHub results are collected, scan local repos for commits that haven't been pushed:
```bash
find ~/Projects -name ".git" -type d -print0 | while IFS= read -r -d '' gitdir; do
  repo=$(dirname "$gitdir")
  # Get today's commits that aren't on the remote tracking branch
  git -C "$repo" log --oneline --since="midnight" --author="$(git -C "$repo" config user.email)" --not --remotes 2>/dev/null
done
```

This catches:
- Work committed locally but not yet pushed
- Repos not hosted on GitHub (local-only projects)

**Deduplication:** If a commit SHA from local scan already appears in GitHub results, skip it. Only surface genuinely unpushed commits.

For unpushed commits, add a `(local)` marker in the log output so the user knows these haven't been pushed yet.

**Fallback:** If `gh` is not authenticated or the API call fails, fall back to the local-only scan (original behavior) and note the fallback in output.

**4. Read and extract key information**

For Calendar/ notes (meetings, threads):
- Title (from filename or `aliases:`)
- `context:` or `about:` to determine grouping
- One-line summary of what happened (from content, `one-liner:`, or summary section)
- **Accuracy:** The 3-8 word summary must come from what the note actually says. If the meeting summary is vague, the daily note stays vague -- do not sharpen. Preserve the specificity level of the source.

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
### Log

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
- **Code work:** Commit ID in backticks + brief description (e.g., `` `a1b2c3d` added Deepgram provider ``)
- **Combined work:** If both vault and code work, combine naturally
- Use full wikilinks on parent items, no aliases
- Use aliases on nested items (strip date prefix, shorten long titles)
- For unmapped repos, use repo name as parent under appropriate context
- Synthesize related commits into a single summary line (use most recent commit ID)
- Drop items that don't fit a project (insignificant at daily/weekly level)

**6. Update the daily note**

Replace the `### Log` section content with the generated log.

Preserve:
- Frontmatter
- Any other sections (if present)

**7. Commit Contexts/ changes**

After generating the log, commit today's Contexts/ changes to establish a clean baseline for tomorrow:
- `cd [vault-path]/Contexts && git add . && git commit -m "Daily snapshot: YYYY-MM-DD"`
- This ensures tomorrow's diff only shows tomorrow's work

**8. Output**

Show the updated log section. Confirm:
- Number of Calendar/ notes processed
- Number of Contexts/ files with changes (and brief diff summary)
- Number of repos scanned, commits found

If any notes couldn't be categorized, list them and ask if grouping is correct.
