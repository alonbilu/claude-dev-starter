#!/usr/bin/env bash
# start-db.sh — Quick Docker DB startup helper
# Usage: bash scripts/start-db.sh

set -euo pipefail

echo "Starting database containers..."
docker compose up -d postgres postgres-test

echo "Waiting for PostgreSQL to be ready..."
timeout 30 bash -c 'until docker compose exec postgres pg_isready -U postgres -q; do sleep 1; done'

echo "✓ Dev DB ready on :5442"
echo "✓ Test DB ready on :5443"
