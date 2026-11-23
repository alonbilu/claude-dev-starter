#!/usr/bin/env bash
# staging-deploy.sh — Incremental deploy to staging
# Usage: bash scripts/staging-deploy.sh

set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/app}"  # set via env or override
HEALTH_URL="http://localhost:3333/api/v1/health"

echo "Deploying to staging..."
cd "$APP_DIR"

echo "  Pulling latest code..."
git pull origin main

echo "  Installing dependencies..."
pnpm install --frozen-lockfile

# run-many, NOT affected: right after `git pull` HEAD is main, so `nx affected` (which diffs
# against main) finds nothing and builds nothing. Nx's cache keeps unchanged projects fast.
echo "  Building..."
pnpm nx run-many -t build --configuration=production

# Raw Prisma from the workspace root (see .claude/rules/database.md — never via Nx).
echo "  Running database migrations..."
npx prisma migrate deploy --schema=libs/domain/database/prisma/schema.prisma

echo "  Reloading application..."
pm2 reload all

echo "  Health check..."
sleep 3
if curl -sf "$HEALTH_URL" > /dev/null; then
  echo "  ✓ Health check passed"
else
  echo "  ✗ Health check FAILED"
  exit 1
fi

echo ""
echo "Deploy complete!"
