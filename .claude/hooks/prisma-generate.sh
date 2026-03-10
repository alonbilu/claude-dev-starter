#!/usr/bin/env bash
# PostToolUse hook: Auto-generate Prisma client after schema.prisma changes
# Receives JSON on stdin with tool_input.file_path

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only run for schema.prisma
case "$FILE_PATH" in
  */schema.prisma|schema.prisma)
    echo "Prisma schema changed — regenerating client..." >&2
    pnpm nx run database:generate 2>/dev/null || true
    ;;
esac

exit 0
