#!/usr/bin/env bash
# test-check-boundaries.sh — feeds hand-written project graphs to scripts/check-boundaries.js
# (via --graph, so Nx is not needed) and checks which ones it accepts and rejects.
#
# Usage: bash scripts/tests/test-check-boundaries.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/../check-boundaries.js"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILS=0

NODES='"api":{"data":{"root":"apps/api"}},"client":{"data":{"root":"apps/client"}},"api-e2e":{"data":{"root":"apps/api-e2e"}},"core":{"data":{"root":"libs/backend/core"}},"users":{"data":{"root":"libs/domain/users"}},"billing":{"data":{"root":"libs/domain/billing"}},"types":{"data":{"root":"libs/shared/types"}},"scripts":{"data":{"root":"tools/scripts"}}'

# expect <0|1> <description> <dependencies-json> [text the output must contain]
expect() {
  local want="$1" desc="$2" deps="$3" needle="${4:-}"
  echo "{\"graph\":{\"nodes\":{$NODES},\"dependencies\":$deps}}" > "$TMP/graph.json"
  local out rc
  out="$(node "$CHECK" --graph "$TMP/graph.json" 2>&1)"; rc=$?
  if [[ $rc -ne $want ]]; then
    echo "  ✗ $desc (exit $rc, wanted $want)"; echo "$out" | sed 's/^/      /'; FAILS=$((FAILS + 1)); return
  fi
  if [[ -n "$needle" ]] && ! grep -qF -- "$needle" <<<"$out"; then
    echo "  ✗ $desc (output lacks: $needle)"; echo "$out" | sed 's/^/      /'; FAILS=$((FAILS + 1)); return
  fi
  echo "  ✓ $desc"
}

dep() { echo "{\"source\":\"$1\",\"target\":\"$2\",\"type\":\"${3:-static}\"}"; }

echo "Allowed:"
expect 0 "apps → backend → domain → shared" \
  "{\"api\":[$(dep api core),$(dep api users),$(dep api types)],\"core\":[$(dep core users),$(dep core types)],\"users\":[$(dep users types)]}"
expect 0 "same-layer import (domain → domain)" "{\"users\":[$(dep users billing)]}"
expect 0 "implicit edge between apps (e2e project → app) is not an import" "{\"api-e2e\":[$(dep api-e2e api implicit)]}"
expect 0 "npm packages and projects outside apps/libs are ignored" \
  "{\"types\":[$(dep types npm:zod)],\"scripts\":[$(dep scripts api)]}"

echo "Rejected:"
expect 1 "shared → domain" "{\"types\":[$(dep types users)]}" "libs/shared/types (libs/shared) must not import from libs/domain/users (libs/domain)"
expect 1 "shared → backend" "{\"types\":[$(dep types core)]}" "must not import from libs/backend/core"
expect 1 "domain → backend" "{\"users\":[$(dep users core)]}" "libs/domain/users (libs/domain) must not import from libs/backend/core (libs/backend)"
expect 1 "lib → app" "{\"core\":[$(dep core api)]}" "must not import from apps/api"
expect 1 "app → app" "{\"client\":[$(dep client api)]}" "apps/client (apps) must not import from apps/api (apps)"
expect 1 "dynamic import counts" "{\"types\":[$(dep types users dynamic)]}" "must not import"
expect 1 "circular dependency within a layer" "{\"users\":[$(dep users billing)],\"billing\":[$(dep billing users)]}" "circular dependency"

echo ""
if [[ $FAILS -eq 0 ]]; then echo "All check-boundaries tests passed."; else echo "$FAILS test(s) FAILED."; exit 1; fi
