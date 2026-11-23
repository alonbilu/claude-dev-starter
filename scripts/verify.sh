#!/usr/bin/env bash
#
# verify.sh — the one definition of "green". Run as: pnpm verify
#
# Used by /start-coding, /quick, /quickbranch, /review, /hotfix, /debug, /fix-issue and CI,
# so a check added here is enforced everywhere at once.
#
#   1. lint        biome ci .                  (whole workspace — Biome is fast and is not an Nx target)
#   2. boundaries  scripts/check-boundaries.js (layer import rules + cycles, from the Nx graph)
#   3. typecheck   nx affected -t typecheck
#   4. test        nx affected -t test --coverage   (coverage minimums: tools/coverage-thresholds.cjs)
#   5. build       nx affected -t build
#
# Usage:
#   pnpm verify            # projects affected since the base branch (plus uncommitted changes)
#   pnpm verify --all      # every project
#
# Base for "affected": $NX_BASE if set (CI sets it via nrwl/nx-set-shas), otherwise origin/main,
# otherwise main. All five steps always run; the exit code is non-zero if any failed.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALL=false
for arg in "$@"; do
  case "$arg" in
    --all) ALL=true ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "verify: unknown argument '$arg' (use --all or no arguments)"; exit 2 ;;
  esac
done

if [ ! -x node_modules/.bin/nx ] || [ ! -x node_modules/.bin/biome ]; then
  echo "verify: nx and/or biome are not installed. Run: pnpm install"
  exit 2
fi

if $ALL; then
  NX_SCOPE=(run-many)
  SCOPE_DESC="all projects"
else
  BASE="${NX_BASE:-}"
  if [ -z "$BASE" ]; then
    if git rev-parse --verify --quiet origin/main >/dev/null; then BASE="origin/main"; else BASE="main"; fi
  fi
  NX_SCOPE=(affected "--base=$BASE")
  [ -n "${NX_HEAD:-}" ] && NX_SCOPE+=("--head=$NX_HEAD")
  SCOPE_DESC="affected since $BASE"
fi

FAILED=()
step() {
  local name="$1"; shift
  echo ""
  echo "━━━ verify: $name ━━━"
  if "$@"; then
    echo "✓ $name"
  else
    echo "✗ $name FAILED"
    FAILED+=("$name")
  fi
}

echo "verify: $SCOPE_DESC"

step "lint (biome)"   node_modules/.bin/biome ci .
step "boundaries"     node scripts/check-boundaries.js
step "typecheck"      node_modules/.bin/nx "${NX_SCOPE[@]}" -t typecheck
step "test + coverage" node_modules/.bin/nx "${NX_SCOPE[@]}" -t test --coverage
step "build"          node_modules/.bin/nx "${NX_SCOPE[@]}" -t build

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "verify: GREEN ($SCOPE_DESC)"
  exit 0
fi
echo "verify: RED — failed: ${FAILED[*]}"
exit 1
