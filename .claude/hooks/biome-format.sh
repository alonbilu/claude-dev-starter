#!/usr/bin/env bash
# PostToolUse hook: Auto-format TypeScript/JavaScript files with Biome after Write/Edit
# Receives JSON on stdin with tool_input.file_path

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only format code files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    npx biome check --write --no-errors-on-unmatched --files-ignore-unknown=true "$FILE_PATH" 2>/dev/null || true
    ;;
esac

exit 0
