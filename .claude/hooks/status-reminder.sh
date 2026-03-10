#!/usr/bin/env bash
# Stop hook: Remind to run /update-status if there's an active feature
# Outputs JSON with decision:"block" if active feature found and status not updated

set -euo pipefail

# Read JSON from stdin (stop hook context)
INPUT=$(cat)

# Check if stop_hook_active is set (prevent infinite loop)
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Look for any active feature with a STATUS.md
ACTIVE_FEATURES=$(find docs/features/active -name "STATUS.md" -type f 2>/dev/null | head -5)

if [ -z "$ACTIVE_FEATURES" ]; then
  exit 0
fi

# Check if STATUS.md was updated recently (within last 5 minutes)
for STATUS_FILE in $ACTIVE_FEATURES; do
  FEATURE_DIR=$(dirname "$STATUS_FILE")
  FEATURE_NAME=$(basename "$FEATURE_DIR")

  # Check if the file was modified in this session (last 5 min)
  if [ "$(find "$STATUS_FILE" -mmin -5 2>/dev/null)" ]; then
    # Recently updated — no reminder needed
    exit 0
  fi

  # Output blocking reminder
  echo "{\"decision\": \"block\", \"reason\": \"Active feature detected: $FEATURE_NAME. Please run /update-status before ending the session.\"}"
  exit 0
done

exit 0
