# Clipboard Copy

When copying formatted content to clipboard for external apps.

## Workflow

When user requests clipboard copy:
1. **Ask destination** if not specified
2. Map destination to format
3. Use `copy-rich.sh` script

## Destination Mapping

| Destination | Format | Flag |
|-------------|--------|------|
| Teams | RTF | `--rtf` |
| Outlook | RTF | `--rtf` |
| Slack | RTF | `--rtf` |
| Confluence | RTF | `--rtf` |
| Jira | Markdown | `--md` |
| Plain text editor | Plain | `--plain` |

## Usage

```bash
# Pipe content to script
echo "**bold** text" | .claude/scripts/copy-rich.sh --rtf

# Or redirect from file
.claude/scripts/copy-rich.sh --md < document.md
```

## Encoding Notes

The script normalizes special characters before conversion to avoid Windows encoding issues:
- Em-dashes (`—`) → double hyphens (`--`)
- Curly quotes → straight quotes
- Ellipsis (`…`) → three periods (`...`)

This prevents the `â€"` artifacts that appear when UTF-8 content is misinterpreted as Windows-1252.

## Sandbox Limitation

RTF clipboard via `osascript` fails silently inside the Claude Code sandbox. The `osascript -e "set the clipboard to (read POSIX file ... as «class RTF »)"` call in `copy-rich.sh` returns success but nothing actually lands on the clipboard, so the user pastes empty. When this happens, fall back to `pbcopy` for plain text — that path works reliably. Reserve the `--rtf` flow for environments where the osascript bridge is available (i.e. not the sandbox).

## Behavioral Pattern

When user says "copy this to clipboard" or "I need to paste this in Teams":
1. Confirm destination if ambiguous
2. Run appropriate copy command
3. Confirm success: "Copied as RTF for Teams"
