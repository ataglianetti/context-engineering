# /update - Pull Scaffolding Updates

Update scaffolding files (rules, commands, hooks) from the upstream starter kit without touching your personalized content files.

## How It Works

This system separates **scaffolding** (rules, commands, hooks, templates) from **content** (your profile, thinking partner, memory, work state). `/update` pulls improvements to scaffolding while leaving your content untouched.

File classifications live in `.claude/manifest.json`:
- **Scaffolding:** Overwritten with upstream version
- **Content:** Never touched
- **Hybrid:** Section-level merge (scaffolding sections updated, user sections preserved)

---

## Step 1: Read Local State

1. Read `.claude/manifest.json` for current version and file classifications
2. If manifest doesn't exist -> this is a **legacy install** (see Legacy Upgrade below)

## Step 2: Fetch Upstream Manifest

Determine fetch method:

**Git-based install** (`.git/` directory exists with `origin` remote):
```bash
git fetch origin main
git show origin/main:Resources/Meta/Claude/manifest.json
```

**Zip/manual install** (no `.git/`):
```bash
# Fetch from GitHub raw content
curl -s https://raw.githubusercontent.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')/main/Resources/Meta/Claude/manifest.json
```

Read the upstream manifest. Compare `version` fields.

- If versions match: "You're on the latest version (vX.Y.Z). Nothing to update." -> Stop.
- If upstream is newer: continue to Step 3.

## Step 3: Diff Scaffolding Files

For each file in the upstream manifest's `scaffolding` list:

1. **Fetch upstream content:**
   - Git: `git show origin/main:<path>`
   - Zip: Fetch from the `source` URL in local manifest.json (falls back to origin remote URL)

2. **Read local content** (if file exists)

3. **Classify change:**
   - `UNCHANGED` — local matches upstream
   - `UPDATED` — local exists but differs from upstream
   - `NEW` — upstream has it, local doesn't
   - `REMOVED` — local has it, upstream doesn't (file removed from manifest)

## Step 4: Handle Hybrid Files

For each hybrid file in the manifest:

1. Read both local and upstream versions
2. Identify user sections (listed in manifest's `user_sections` array)
3. Extract user section content from local file
4. Take upstream file as base
5. Splice local user section content back in at the correct location
6. If the upstream version added/moved the user section heading, flag for manual review

## Step 5: Present Summary

Show a summary table:

```
Upstream version: vX.Y.Z (you have vA.B.C)

| File | Status |
|------|--------|
| rules/core/hard-walls.md | UPDATED |
| commands/meeting-notes.md | UPDATED |
| commands/update.md | NEW |
| ... | UNCHANGED |

X files updated, Y new files, Z unchanged.
```

Then ask via AskUserQuestion:
- **"Apply all updates" (Recommended)** — Write all updated + new files
- **"Review changes first"** — Show diff for each updated file before applying
- **"Cancel"** — Don't update

## Step 6: Apply Updates

For approved files:

1. Write each scaffolding file with upstream content
2. Write each hybrid file with merged content
3. Make hook scripts executable: `chmod +x .claude/hooks/*.sh`
4. Update local manifest version to match upstream
5. Report: "Updated to vX.Y.Z. N files updated, M new files added."

**Do NOT touch:**
- Any file in the `content` list
- Context-specific rule folders (e.g., `.claude/rules/my-company/`)
- `setup-state.json`
- Vault content (Calendar/, Contexts/, Resources/)

---

## Legacy Upgrade

When `.claude/manifest.json` doesn't exist, the user has a pre-manifest install.

**Detection:** Check for placeholder sentinels in content files:
- `user-profile.md` contains `> **Not configured yet.**` or template placeholder text
- `thinking-partner.md` contains generic placeholder examples

**Flow:**
1. Fetch upstream manifest
2. Diff ALL scaffolding files against local versions
3. Present as "Initial update — establishing baseline"
4. Write approved files + write manifest.json
5. Note: "Manifest created. Future updates will be faster."

---

## Post-Update

After a successful update, suggest:
- "Run `/refresh` if you want to update your personalized rules with any new configuration options."
- If new commands were added: briefly describe what each new command does
