#!/usr/bin/env bash
# test-production-deploy.sh — exercises scripts/production-deploy.sh end-to-end in a temp
# directory, with git / pnpm / npx / pm2 / curl replaced by stubs on PATH.
#
# Usage: bash scripts/tests/test-production-deploy.sh [path/to/production-deploy.sh]
#
# Cases:
#   1. health check fails    → dist is REPLACED by the backup (no leftover files from the
#                              failed build), pm2 reloaded again, exit 1
#   2. health check passes   → new build stays, exit 0
#   3. failure + migrations  → output says migrations were NOT rolled back
#   4. build step            → uses `nx run-many`, never `nx affected`

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${1:-$HERE/../production-deploy.sh}"
FAILS=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILS=$((FAILS + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# setup <health: ok|fail> — builds a sandbox, sets SANDBOX/APP/CALLS
setup() {
  SANDBOX="$(mktemp -d)"
  APP="$SANDBOX/app"
  CALLS="$SANDBOX/calls.log"
  mkdir -p "$APP/dist/apps/api" "$SANDBOX/bin" "$SANDBOX/backups"
  echo "old-build" > "$APP/dist/apps/api/main.js"
  echo "old-only"  > "$APP/dist/apps/api/old-only.js"
  printf 'NODE_ENV=production\nDATABASE_URL=postgresql://db.example.com/app\n' > "$APP/.env.production"

  cat > "$SANDBOX/bin/git" <<'EOF'
#!/usr/bin/env bash
echo "git $*" >> "$CALLS"
case "$*" in
  *"rev-parse --abbrev-ref HEAD"*) echo main ;;
esac
exit 0
EOF
  # The "build" overwrites main.js and adds a file the old build never had. If rollback
  # merges instead of replacing, new-only.js survives and the test fails.
  cat > "$SANDBOX/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
echo "pnpm $*" >> "$CALLS"
case "$*" in
  *" build"*)
    echo "new-build" > "$APP_DIR/dist/apps/api/main.js"
    echo "new-only"  > "$APP_DIR/dist/apps/api/new-only.js"
    rm -f "$APP_DIR/dist/apps/api/old-only.js"
    ;;
esac
exit 0
EOF
  cat > "$SANDBOX/bin/npx" <<'EOF'
#!/usr/bin/env bash
echo "npx $*" >> "$CALLS"
exit 0
EOF
  cat > "$SANDBOX/bin/pm2" <<'EOF'
#!/usr/bin/env bash
echo "pm2 $*" >> "$CALLS"
exit 0
EOF
  if [[ "$1" == ok ]]; then
    printf '#!/usr/bin/env bash\necho "curl $*" >> "$CALLS"\nexit 0\n' > "$SANDBOX/bin/curl"
  else
    printf '#!/usr/bin/env bash\necho "curl $*" >> "$CALLS"\nexit 22\n' > "$SANDBOX/bin/curl"
  fi
  chmod +x "$SANDBOX/bin/"*
}

# run <stdin answers> — runs the deploy script inside the sandbox; sets OUT/RC
run() {
  OUT="$(printf '%b' "$1" | env \
    PATH="$SANDBOX/bin:$PATH" CALLS="$CALLS" \
    APP_DIR="$APP" BACKUP_DIR="$SANDBOX/backups" HEALTH_RETRY_DELAY=0 \
    bash "$SCRIPT" 2>&1)"
  RC=$?
}

teardown() { rm -rf "$SANDBOX"; }

echo "Testing: $SCRIPT"

echo "Case 1: health check fails → rollback replaces dist and reloads"
setup fail
run 'deploy\nn\n'
check "exits non-zero"                          '[[ $RC -ne 0 ]]'
check "main.js is the OLD build"                '[[ "$(cat "$APP/dist/apps/api/main.js" 2>/dev/null)" == old-build ]]'
check "file removed by the new build is back"   '[[ -f "$APP/dist/apps/api/old-only.js" ]]'
check "file added by the failed build is gone (replace, not merge)" '[[ ! -e "$APP/dist/apps/api/new-only.js" ]]'
check "no nested dist/dist or backup dir inside dist" '[[ ! -e "$APP/dist/dist" && -z "$(find "$APP/dist" -maxdepth 1 -name "backup-*")" ]]'
check "no dist.failed left behind"              '[[ ! -e "$APP/dist.failed" ]]'
check "pm2 reloaded twice (deploy + rollback)"  '[[ "$(grep -c "^pm2 reload all" "$CALLS")" -eq 2 ]]'
check "reports previous build restored"         'grep -q "Previous build restored" <<<"$OUT"'
check "no migration warning when none applied"  '! grep -q "NOT rolled back" <<<"$OUT"'
[[ $FAILS -gt 0 ]] && echo "--- output ---" && echo "$OUT" && echo "--------------"
teardown

echo "Case 2: health check passes → new build stays"
setup ok
run 'deploy\nn\n'
check "exits zero"                              '[[ $RC -eq 0 ]]'
check "main.js is the NEW build"                '[[ "$(cat "$APP/dist/apps/api/main.js")" == new-build ]]'
check "pm2 reloaded once"                       '[[ "$(grep -c "^pm2 reload all" "$CALLS")" -eq 1 ]]'
check "backup holds the old build at its top level" '[[ "$(cat "$SANDBOX"/backups/backup-*/apps/api/main.js)" == old-build ]]'
check "builds with run-many"                    'grep -q "nx run-many -t build" "$CALLS"'
check "never builds with nx affected"           '! grep -q "nx affected" "$CALLS"'
check "migrations not applied when answered n"  '! grep -q "migrate deploy" "$CALLS"'
teardown

echo "Case 3: migrations applied, then health check fails → warns they are not rolled back"
setup fail
run 'deploy\ny\n'
check "exits non-zero"                          '[[ $RC -ne 0 ]]'
check "migrate deploy was run"                  'grep -q "^npx prisma migrate deploy" "$CALLS"'
check "build still rolled back"                 '[[ "$(cat "$APP/dist/apps/api/main.js")" == old-build ]]'
check "warns migrations were NOT rolled back"   'grep -q "NOT rolled back" <<<"$OUT"'
teardown

echo "Case 4: wrong confirmation word → aborts before touching anything"
setup ok
run 'yes\n'
check "exits non-zero"                          '[[ $RC -ne 0 ]]'
check "nothing pulled, built or reloaded"       '! grep -qE "^(pnpm|pm2|git pull)" "$CALLS" 2>/dev/null'
teardown

echo ""
if [[ $FAILS -eq 0 ]]; then
  echo "All production-deploy tests passed."
else
  echo "$FAILS check(s) FAILED."
  exit 1
fi
