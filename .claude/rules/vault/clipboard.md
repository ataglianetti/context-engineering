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
| Confluence | Markdown | `--md` |
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
- Em-dashes → double hyphens (`--`)
- Curly quotes → straight quotes
- Ellipsis → three periods (`...`)

This prevents encoding artifacts that appear when UTF-8 content is misinterpreted as Windows-1252.

## Behavioral Pattern

When user says "copy this to clipboard" or "I need to paste this in [app]":
1. Confirm destination if ambiguous
2. Run appropriate copy command
3. Confirm success: "Copied as RTF for Teams"
