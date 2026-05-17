#!/usr/bin/env bash
# scripts/start-cloudflared.sh — Run a Cloudflare Tunnel pointing at your local dev env.
#
# Prerequisites:
#   • `cloudflared` installed
#     https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/installation/
#   • You have run:  cloudflared tunnel login
#   • You have created a tunnel:  cloudflared tunnel create <name>
#   • You have routed a hostname:  cloudflared tunnel route dns <name> dev.yourdomain.com
#   • CLOUDFLARE_TUNNEL_TOKEN is set in your environment (from .env)

set -euo pipefail

if ! command -v cloudflared &>/dev/null; then
  echo "❌ cloudflared not found."
  echo "   Install:"
  echo "   https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/installation/"
  exit 1
fi

if [[ -z "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
  echo "❌ CLOUDFLARE_TUNNEL_TOKEN is not set. Add it to .env (see .env.example)."
  exit 1
fi

API_PORT="${API_PORT:-3333}"
CLIENT_PORT="${CLIENT_PORT:-4200}"

echo "▶ Starting Cloudflare Tunnel..."
echo "  API:    http://localhost:${API_PORT}"
echo "  Client: http://localhost:${CLIENT_PORT}"
echo ""
echo "  Routes are configured via the Cloudflare dashboard or"
echo "  'cloudflared tunnel route' commands."
echo ""

exec cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN"
