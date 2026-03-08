#!/usr/bin/env bash
# trim-context.sh — Context window audit and mechanical cleanup
# Usage: bash scripts/trim-context.sh

set -euo pipefail

echo "Context Window Audit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

estimate_tokens() {
  local lines="$1"
  echo $(( lines * 4 / 3 ))  # rough estimate: ~1.33 tokens per line
}

total_lines=0

echo "Always-loaded files (counted against every session):"
for file in CLAUDE.md PROJECT.md .claude/brain.md .claude/rules/*.md; do
  if [[ -f "$file" ]]; then
    lines=$(wc -l < "$file")
    tokens=$(estimate_tokens "$lines")
    warning=""
    if [[ "$file" == ".claude/brain.md" && $lines -gt 200 ]]; then
      warning=" ⚠️  OVER 200 LINE LIMIT"
    fi
    printf "  %-42s %4d lines  ~%dk tokens%s\n" "$file" "$lines" $(( tokens / 1000 + 1 )) "$warning"
    total_lines=$((total_lines + lines))
  fi
done

total_tokens=$(estimate_tokens "$total_lines")
echo ""
echo "  TOTAL always-loaded:  ~$((total_tokens / 1000))k tokens"
echo ""

# Scan active features
echo "Feature docs (loaded on /resume-feature):"
if ls docs/features/active/ 2>/dev/null | grep -q "F"; then
  for feature_dir in docs/features/active/F*/; do
    if [[ -d "$feature_dir" ]]; then
      feature_name=$(basename "$feature_dir")
      status_file="$feature_dir/STATUS.md"
      context_file="$feature_dir/CONTEXT.md"

      if [[ -f "$status_file" ]]; then
        status_lines=$(wc -l < "$status_file")
        warning=""
        [[ $status_lines -gt 150 ]] && warning=" ⚠️  LARGE — consider archiving session logs"
        printf "  %-35s STATUS.md: %4d lines%s\n" "$feature_name" "$status_lines" "$warning"
      fi

      # Check if feature looks complete (all steps checked)
      if [[ -f "$status_file" ]]; then
        unchecked=$(grep -c "\- \[ \]" "$status_file" 2>/dev/null || echo "0")
        if [[ "$unchecked" == "0" ]]; then
          echo "    → All steps appear complete — consider archiving with /complete-feature"
        fi
      fi
    fi
  done
else
  echo "  (none)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Mechanical fixes
echo "Automatic fixes available:"
echo ""

any_fix=false

# Check for completed features in active/
for feature_dir in docs/features/active/F*/; do
  if [[ -d "$feature_dir" ]]; then
    status_file="$feature_dir/STATUS.md"
    if [[ -f "$status_file" ]]; then
      unchecked=$(grep -c "\- \[ \]" "$status_file" 2>/dev/null || echo "1")
      if [[ "$unchecked" == "0" ]]; then
        feature_name=$(basename "$feature_dir")
        echo "[A] Archive completed feature: $feature_name"
        echo "    → Move docs/features/active/$feature_name/ to docs/features/completed/"
        read -rp "    Do this? [y/N]: " do_archive
        if [[ "$do_archive" =~ ^[Yy]$ ]]; then
          mv "$feature_dir" "docs/features/completed/"
          echo "    ✓ Archived"
          any_fix=true
        fi
        echo ""
      fi
    fi
  fi
done

# Archive STATUS.md session history
for feature_dir in docs/features/active/F*/; do
  if [[ -d "$feature_dir" ]]; then
    status_file="$feature_dir/STATUS.md"
    if [[ -f "$status_file" ]]; then
      status_lines=$(wc -l < "$status_file")
      if [[ $status_lines -gt 150 ]]; then
        feature_name=$(basename "$feature_dir")
        echo "[B] Trim STATUS.md for $feature_name ($status_lines lines)"
        echo "    → Archive session history to STATUS.archive.md, keep current state"
        read -rp "    Do this? [y/N]: " do_trim
        if [[ "$do_trim" =~ ^[Yy]$ ]]; then
          archive_file="${status_file%.md}.archive.md"
          # Move session log sections to archive
          echo "# STATUS Archive — $(date)" > "$archive_file"
          grep -A 999 "## Session" "$status_file" >> "$archive_file" 2>/dev/null || true
          # Keep only current state (remove session logs)
          head -n 80 "$status_file" > "${status_file}.tmp" && mv "${status_file}.tmp" "$status_file"
          echo "    ✓ Session history moved to STATUS.archive.md"
          any_fix=true
        fi
        echo ""
      fi
    fi
  fi
done

# brain.md size warning
if [[ -f ".claude/brain.md" ]]; then
  brain_lines=$(wc -l < ".claude/brain.md")
  if [[ $brain_lines -gt 200 ]]; then
    echo "[C] brain.md is $brain_lines lines (over 200 line limit)"
    echo "    → Cannot auto-trim — content decisions require judgment"
    echo "    → Run /trim-context in Claude Code for intelligent trimming"
    echo ""
    any_fix=true
  fi
fi

if ! $any_fix; then
  echo "  No automatic fixes needed. Context is clean!"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "For intelligent content trimming (brain.md, rules bloat):"
echo "  Run /trim-context in Claude Code"
