#!/usr/bin/env bash
# scripts/start-preview.sh — Serve the production-built React client via Vite preview.
#
# Use this when you want to test the optimized production bundle locally instead of the
# dev server (which uses HMR, source maps, etc.). Useful for:
#   • Verifying the production build before deploy
#   • Reproducing a production-only bug locally
#   • Lighthouse / perf testing against a realistic bundle
#
# For the regular dev server (HMR, fast refresh), use scripts/dev.sh start instead.

set -euo pipefail

CLIENT_PORT="${CLIENT_PORT:-4200}"
PROJECT="${1:-client}"

echo "▶ Building ${PROJECT} for production..."
pnpm nx build "${PROJECT}" --configuration=production

echo ""
echo "▶ Starting Vite preview server on port ${CLIENT_PORT}..."
echo "  Visit: http://localhost:${CLIENT_PORT}"
echo "  (Press Ctrl+C to stop.)"
echo ""

# Prefer the Nx 'preview' target if the project has it (set up by @nx/vite); fall back to
# invoking Vite directly inside the app folder otherwise.
if pnpm nx show project "${PROJECT}" --json 2>/dev/null | grep -q '"preview"'; then
  exec pnpm nx run "${PROJECT}:preview" --port "${CLIENT_PORT}"
else
  cd "apps/${PROJECT}"
  exec pnpm vite preview --port "${CLIENT_PORT}"
fi
