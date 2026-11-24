#!/usr/bin/env bash
# production-deploy.sh — Production deploy with safety gates
# Usage: bash scripts/production-deploy.sh
#
# Environment overrides (defaults suit a real server; the test suite overrides them):
#   APP_DIR             app checkout                      (default /var/www/app)
#   BACKUP_DIR          where dist backups are kept       (default /var/backups/app)
#   HEALTH_URL          readiness endpoint                (default http://localhost:3333/api/v1/health)
#   HEALTH_RETRY_DELAY  seconds between health attempts   (default 5)
#   PRISMA_SCHEMA       schema path relative to APP_DIR
#
# Rollback restores the previous BUILD only. It does NOT undo database migrations —
# see .claude/rules/deployment.md → "Rollback".
#
# Tested by: bash scripts/tests/test-production-deploy.sh

set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/app}"
HEALTH_URL="${HEALTH_URL:-http://localhost:3333/api/v1/health}"
HEALTH_RETRY_DELAY="${HEALTH_RETRY_DELAY:-5}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/app}"
PRISMA_SCHEMA="${PRISMA_SCHEMA:-libs/domain/database/prisma/schema.prisma}"

HAVE_BACKUP=false
MIGRATIONS_APPLIED=false

# Replace dist with the backup (never merge into it), then reload.
# Returns non-zero if there is nothing to restore or the restore fails.
rollback() {
  if [[ "$HAVE_BACKUP" != true || ! -d "$BACKUP_PATH" ]]; then
    echo "  ✗ No backup available — cannot roll back the build."
    return 1
  fi
  local failed="$APP_DIR/dist.failed"
  rm -rf "$failed"
  if [[ -e "$APP_DIR/dist" ]]; then
    mv "$APP_DIR/dist" "$failed"
  fi
  if ! cp -a "$BACKUP_PATH" "$APP_DIR/dist"; then
    echo "  ✗ Restoring $BACKUP_PATH failed. The failed build is kept at $failed."
    return 1
  fi
  rm -rf "$failed"
  pm2 reload all
  echo "  ✓ Rolled back to previous build ($BACKUP_PATH)"
}

migration_warning() {
  if [[ "$MIGRATIONS_APPLIED" == true ]]; then
    echo ""
    echo "  ⚠ Migrations were applied during this deploy and were NOT rolled back."
    echo "    The restored build is now running against the NEW schema. If the old"
    echo "    build is not compatible with it, restore the database from your"
    echo "    pre-deploy backup or ship a forward-fix migration."
  fi
}

echo "================================================"
echo " PRODUCTION DEPLOY"
echo "================================================"
echo ""

# Gate 1: Explicit confirmation
read -rp "Type 'deploy' to confirm production deployment: " confirm
[[ "$confirm" == "deploy" ]] || { echo "Aborted."; exit 1; }

# Gate 2: Check branch
BRANCH=$(git -C "$APP_DIR" rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
  echo "ERROR: Not on main branch (current: $BRANCH)"
  exit 1
fi

# Gate 3: Check clean working tree
if ! git -C "$APP_DIR" diff --quiet; then
  echo "ERROR: Uncommitted changes detected. Commit or stash first."
  exit 1
fi

# Gate 4: Check NODE_ENV
if [[ -f "$APP_DIR/.env.production" ]]; then
  if ! grep -q "NODE_ENV=production" "$APP_DIR/.env.production"; then
    echo "ERROR: .env.production does not have NODE_ENV=production"
    exit 1
  fi
  if grep -q "localhost" "$APP_DIR/.env.production"; then
    echo "ERROR: .env.production contains 'localhost' — use production URLs"
    exit 1
  fi
else
  echo "ERROR: .env.production not found"
  exit 1
fi

echo "All pre-flight checks passed."
echo ""

# Backup current build. $BACKUP_PATH IS the copy of dist (not a parent of it).
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S)"
if [[ -d "$APP_DIR/dist" ]]; then
  # A failed backup must stop the deploy — otherwise there is nothing to roll back to.
  cp -a "$APP_DIR/dist" "$BACKUP_PATH"
  HAVE_BACKUP=true
  echo "  ✓ Backup at: $BACKUP_PATH"
else
  echo "  ! No existing dist/ (first deploy?) — nothing to back up; rollback will not be possible."
fi

# Pull and build
echo ""
echo "Pulling latest code..."
git -C "$APP_DIR" pull origin main

echo "Installing dependencies..."
pnpm --dir "$APP_DIR" install --frozen-lockfile

# run-many, NOT affected: right after `git pull` HEAD is main, so `nx affected` (which diffs
# against main) finds nothing and builds nothing. Nx's cache keeps unchanged projects fast.
echo "Building..."
pnpm --dir "$APP_DIR" nx run-many -t build --configuration=production

# Show pending migrations and confirm.
# Raw Prisma from the workspace root (see .claude/rules/database.md — never via Nx).
echo ""
echo "Pending migrations:"
(cd "$APP_DIR" && npx prisma migrate status --schema="$PRISMA_SCHEMA") \
  || echo "  (status exited non-zero — this is expected when migrations are pending; review the output above)"
echo ""
echo "NOTE: if the health check fails, the BUILD is rolled back automatically but"
echo "      migrations are NOT. Take a database backup before applying risky migrations."
read -rp "Apply migrations? [y/N]: " apply_migrations
if [[ "$apply_migrations" =~ ^[Yy]$ ]]; then
  (cd "$APP_DIR" && npx prisma migrate deploy --schema="$PRISMA_SCHEMA")
  MIGRATIONS_APPLIED=true
  echo "  ✓ Migrations applied"
fi

# Reload application
echo ""
echo "Reloading application (zero-downtime)..."
pm2 reload all

# Health check with retries
echo "Health check..."
for i in 1 2 3; do
  sleep "$HEALTH_RETRY_DELAY"
  if curl -sf "$HEALTH_URL" > /dev/null; then
    echo "  ✓ Health check passed (attempt $i)"
    break
  fi
  if [[ $i -eq 3 ]]; then
    echo "  ✗ Health check FAILED after 3 attempts — rolling back..."
    if rollback; then
      migration_warning
      echo ""
      echo "DEPLOY FAILED. Previous build restored."
    else
      migration_warning
      echo ""
      echo "DEPLOY FAILED AND ROLLBACK FAILED. Manual intervention required."
    fi
    exit 1
  fi
  echo "  Retrying... ($i/3)"
done

echo ""
echo "================================================"
echo " Production deploy SUCCESSFUL"
echo "================================================"
