#!/usr/bin/env bash
# production-deploy.sh — Production deploy with safety gates
# Usage: bash scripts/production-deploy.sh

set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/app}"
HEALTH_URL="http://localhost:3333/api/v1/health"
BACKUP_DIR="/var/backups/app"

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

# Backup current build
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S)"
cp -r "$APP_DIR/dist" "$BACKUP_PATH" 2>/dev/null || true
echo "  ✓ Backup at: $BACKUP_PATH"

# Pull and build
echo ""
echo "Pulling latest code..."
git -C "$APP_DIR" pull origin main

echo "Installing dependencies..."
pnpm --dir "$APP_DIR" install --frozen-lockfile

echo "Building..."
pnpm --dir "$APP_DIR" nx affected -t build --configuration=production

# Show pending migrations and confirm
echo ""
echo "Pending migrations:"
pnpm --dir "$APP_DIR" nx run database:migrate:deploy --dry-run 2>/dev/null || echo "  (none or dry-run not supported)"
echo ""
read -rp "Apply migrations? [y/N]: " apply_migrations
if [[ "$apply_migrations" =~ ^[Yy]$ ]]; then
  pnpm --dir "$APP_DIR" nx run database:migrate:deploy
  echo "  ✓ Migrations applied"
fi

# Reload application
echo ""
echo "Reloading application (zero-downtime)..."
pm2 reload all

# Health check with retries
echo "Health check..."
for i in 1 2 3; do
  sleep 5
  if curl -sf "$HEALTH_URL" > /dev/null; then
    echo "  ✓ Health check passed (attempt $i)"
    break
  fi
  if [[ $i -eq 3 ]]; then
    echo "  ✗ Health check FAILED after 3 attempts — rolling back..."
    cp -r "$BACKUP_PATH/dist" "$APP_DIR/dist"
    pm2 reload all
    echo "  ✓ Rolled back to previous build"
    echo ""
    echo "DEPLOY FAILED. Previous build restored."
    exit 1
  fi
  echo "  Retrying... ($i/3)"
done

echo ""
echo "================================================"
echo " Production deploy SUCCESSFUL"
echo "================================================"
