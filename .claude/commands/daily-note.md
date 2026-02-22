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
- If it doesn't exist, create it using the Daily Note template at Resources/Templates/Daily Note.md

**2. Find notes touched today**

**Calendar/ folder** (meeting notes, threads):
- Search for files created today (use file creation date)
- Include types: Meeting, Thread
- These are event-based notes; their existence is the log entry
- **Sanity check:** If search returns zero results, verify the query date matches the system date before assuming no notes exist.

**Contexts/ folder** (git-tracked):
- Run `git status` and `git diff` to find files with uncommitted changes
- Run `git log --since="midnight"` to find files committed today
- For each changed file, extract the actual diff to summarize what changed

Skip:
- The daily note itself
- Contexts/ files with no meaningful diff (whitespace, metadata-only)

**3. Scan git commits (GitHub + local)**

Two-pass approach: GitHub API for pushed commits (works across machines), then local scan for unpushed work.

**3a. GitHub commits (primary)**

Query today's pushed commits via `gh`:
```bash
GH_USER=$(gh api user --jq '.login')
gh api "search/commits?q=author:${GH_USER}+committer-date:>=YYYY-MM-DD&sort=committer-date&per_page=100" \
  --header "Accept: application/vnd.github.cloak-preview+json" \
  --jq '.items[] | {sha: .sha[0:7], message: (.commit.message | split("\n") | .[0]), repo: .repository.full_name, url: .html_url}'
```

For each commit, extract short SHA, commit message (first line), repository name.

**Repo to vault mapping:** Check `rules/vault/daily-notes.md` for a "Git Repo Mapping" table if one exists. Match GitHub repo names to vault projects. If a match exists, group under that vault project.

Skip: Merge commits, repos with no commits today, automated commits.

**3b. Local unpushed commits (supplement)**

After GitHub results, scan local repos for unpushed commits:
```bash
find ~/Projects -name ".git" -type d -print0 | while IFS= read -r -d '' gitdir; do
  repo=$(dirname "$gitdir")
  git -C "$repo" log --oneline --since="midnight" --author="$(git -C "$repo" config user.email)" --not --remotes 2>/dev/null
done
```

**Deduplication:** If a commit SHA from local scan already appears in GitHub results, skip it.

For unpushed commits, add a `(local)` marker.

**Fallback:** If `gh` is not authenticated, fall back to local-only scan.

**4. Read and extract key information**

For Calendar/ notes: Title, `context:` or `about:` for grouping, one-line summary (3-8 words).

For Contexts/ notes: Title, `context:` or `parent:` for grouping, summary of what changed based on the diff.

For git commits: If repo has a vault mapping, group under that project. If no mapping, use `Code: repo-name`. Synthesize related commits into coherent work items.

**5. Generate the log**

Group by context (bold headers), then by project (wikilinks), then nested items.

Rules:
- **Summaries:** 3-8 words max, key outcome only
- **Meetings/threads:** Wikilink with alias + short summary
- **Vault work:** Plain text description
- **Code work:** Commit ID in backticks + brief description
- Synthesize related commits into a single summary line
- Drop items that don't fit a project

**6. Update the daily note**

Replace the `### Log` section content with the generated log. Preserve frontmatter and other sections.

**7. Commit Contexts/ changes**

After generating the log, commit today's Contexts/ changes:
`cd [vault-path]/Contexts && git add . && git commit -m "Daily snapshot: YYYY-MM-DD"`

**8. Output**

Show the updated log section. Confirm number of Calendar/ notes processed, Contexts/ files with changes, repos scanned and commits found.
