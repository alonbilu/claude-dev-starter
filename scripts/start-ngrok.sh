#!/usr/bin/env bash
# start-ngrok.sh — ngrok tunnels for webhook/OAuth testing
# Usage: bash scripts/start-ngrok.sh

set -euo pipefail

API_PORT=3333  # replaced by /setup-project

if ! command -v ngrok &> /dev/null; then
  echo "ngrok not found. Install from: https://ngrok.com/download"
  exit 1
fi

echo "Starting ngrok tunnel on port $API_PORT..."
echo "Update BETTER_AUTH_URL in .env with the HTTPS URL shown below."
echo ""

ngrok http "$API_PORT"
