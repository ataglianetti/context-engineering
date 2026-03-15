#!/bin/bash
# copy-rich.sh - Copy markdown to clipboard with rich formatting
# Usage: echo "**bold** text" | copy-rich.sh --rtf
#        copy-rich.sh --md < file.md
#        copy-rich.sh --plain < file.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_FILE="$SCRIPT_DIR/export-style.css"

# Parse arguments
FORMAT="${1:---rtf}"

# Read stdin
CONTENT=$(cat)

# Normalize special characters to avoid encoding issues
# Em-dash → double hyphen, curly quotes → straight quotes
normalize_chars() {
    sed -e 's/—/--/g' \
        -e 's/–/-/g' \
        -e "s/'/'/g" \
        -e "s/'/'/g" \
        -e 's/"/"/g' \
        -e 's/"/"/g' \
        -e 's/…/.../g'
}

case "$FORMAT" in
    --rtf)
        # Normalize chars, convert to HTML, inject CSS, convert to RTF
        NORMALIZED=$(echo "$CONTENT" | normalize_chars)

        # Create temp files early for injection
        HTML_FILE=$(mktemp /tmp/copy-rich.XXXXXX.html)
        RTF_FILE=$(mktemp /tmp/copy-rich.XXXXXX.rtf)
        trap "rm -f '$HTML_FILE' '$RTF_FILE'" EXIT

        # Convert markdown to HTML with pandoc
        echo "$NORMALIZED" | pandoc -f markdown -t html --standalone > "$HTML_FILE" 2>/dev/null

        # Inject CSS and charset into HTML
        # Use perl for reliable multiline substitution
        if [[ -f "$CSS_FILE" ]]; then
            CSS_CONTENT=$(cat "$CSS_FILE")
            perl -i -pe '
                s|<head>|<head><meta charset="UTF-8">|;
            ' "$HTML_FILE"
            # Insert style block before </head> using perl slurp mode
            perl -i -0777 -pe "s|</head>|<style>\n${CSS_CONTENT}\n</style>\n</head>|s" "$HTML_FILE"
        fi

        # Convert HTML to RTF
        textutil -convert rtf -output "$RTF_FILE" "$HTML_FILE" 2>/dev/null

        # Copy RTF to clipboard using osascript
        osascript -e "set the clipboard to (read POSIX file \"$RTF_FILE\" as «class RTF »)"

        echo "Copied as RTF (rich text for Teams/Outlook/Slack)"
        ;;

    --md|--markdown)
        # Copy markdown as-is
        echo "$CONTENT" | pbcopy
        echo "Copied as Markdown (for Confluence/Jira)"
        ;;

    --plain)
        # Strip markdown formatting and copy plain text
        # Remove bold/italic markers, links, etc.
        echo "$CONTENT" | \
            sed -e 's/\*\*\([^*]*\)\*\*/\1/g' \
                -e 's/\*\([^*]*\)\*/\1/g' \
                -e 's/__\([^_]*\)__/\1/g' \
                -e 's/_\([^_]*\)_/\1/g' \
                -e 's/`\([^`]*\)`/\1/g' \
                -e 's/\[\([^]]*\)\]([^)]*)/\1/g' \
                -e 's/^#\+ //' \
                -e 's/^- /• /' | \
            pbcopy
        echo "Copied as plain text"
        ;;

    --help|-h)
        echo "Usage: copy-rich.sh [--rtf|--md|--plain]"
        echo ""
        echo "Reads markdown from stdin and copies to clipboard."
        echo ""
        echo "Formats:"
        echo "  --rtf     Rich text for Teams/Outlook/Slack (default)"
        echo "  --md      Markdown for Confluence/Jira"
        echo "  --plain   Plain text, formatting stripped"
        echo ""
        echo "Example:"
        echo "  echo '**bold** text' | copy-rich.sh --rtf"
        ;;

    *)
        echo "Unknown format: $FORMAT" >&2
        echo "Use --rtf, --md, or --plain" >&2
        exit 1
        ;;
esac
