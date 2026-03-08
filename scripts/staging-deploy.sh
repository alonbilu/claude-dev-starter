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

echo "  Building affected projects..."
pnpm nx affected -t build --configuration=production

echo "  Running database migrations..."
pnpm nx run database:migrate:deploy

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
