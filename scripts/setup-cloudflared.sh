#!/usr/bin/env bash
#
# setup-cloudflared.sh — Project-isolated Cloudflare Tunnel setup.
#
# WHAT THIS SOLVES:
#   `cloudflared tunnel login` always writes its cert to ~/.cloudflared/cert.pem.
#   On a multi-project machine (afnu, startd, connected-trips, ...) you can't run
#   `tunnel login` for a second project without OVERWRITING the first project's
#   global cert. The kit's `start-cloudflared.sh` runs an already-set-up tunnel
#   via a token; this script does the ONE-TIME setup keeping each project's
#   cert isolated under its own `./.cloudflared/` directory.
#
# WHAT THIS DOES (idempotent):
#   1. Backs up ~/.cloudflared/cert.pem (if present) to ~/.cloudflared/cert.pem.bak.<ts>
#   2. Removes the global cert so `tunnel login` writes a fresh one
#   3. Runs `cloudflared tunnel login` interactively (opens browser)
#   4. Moves the NEW cert to ./.cloudflared/cert.pem (project-local, gitignored)
#   5. Restores the previous global cert from the backup
#   6. Creates a named tunnel using the project-local cert
#   7. Routes DNS to a chosen hostname
#   8. Writes ./.cloudflared/config.yml (the run-time config)
#   9. Prints the CLOUDFLARE_TUNNEL_TOKEN for you to add to .env
#
# After this runs, `bash scripts/start-cloudflared.sh` boots the tunnel pointing
# at your local dev (API_PORT / CLIENT_PORT from .env).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

[ -f PROJECT.md ] || { echo "✗ Not at project root (no PROJECT.md)"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }
warn() { echo -e "${RED}!${NC} $1"; }

if ! command -v cloudflared &>/dev/null; then
  warn "cloudflared is not installed."
  echo "  Install:"
  echo "    https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/installation/"
  exit 1
fi

PROJECT_NAME="$(basename "$ROOT_DIR")"
GLOBAL_CERT="$HOME/.cloudflared/cert.pem"
PROJECT_CF_DIR="$ROOT_DIR/.cloudflared"
PROJECT_CERT="$PROJECT_CF_DIR/cert.pem"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_CERT="$HOME/.cloudflared/cert.pem.bak.${PROJECT_NAME}.${TS}"

mkdir -p "$PROJECT_CF_DIR"

echo ""
echo "============================================="
echo " Cloudflare Tunnel setup for: $PROJECT_NAME"
echo "============================================="
echo ""

# Idempotency — if the project already has a cert + tunnel, skip cleanly
if [ -f "$PROJECT_CERT" ]; then
  ok "Project cert already exists at $PROJECT_CERT"
  read -rp "Re-run tunnel setup anyway? (overwrites tunnel + DNS routes) [y/N]: " redo
  if [[ ! "$redo" =~ ^[Yy]$ ]]; then
    info "Nothing to do."
    exit 0
  fi
fi

# ─── 1. Back up + clear the global cert ───────────────────────────────────
if [ -f "$GLOBAL_CERT" ]; then
  info "Backing up global cert → $BACKUP_CERT"
  cp "$GLOBAL_CERT" "$BACKUP_CERT"
  rm "$GLOBAL_CERT"
  ok "global cert backed up + removed"
else
  ok "no existing global cert to back up"
fi

# ─── 2. Run cloudflared login (writes fresh cert to ~/.cloudflared/cert.pem) ───
info "Opening browser for cloudflared login..."
echo "  (Select the Cloudflare account + zone you want this project's tunnel to live in.)"
cloudflared tunnel login || { warn "cloudflared login failed"; [ -f "$BACKUP_CERT" ] && cp "$BACKUP_CERT" "$GLOBAL_CERT"; exit 1; }

# ─── 3. Move new cert to project-local + restore the global backup ────────
if [ ! -f "$GLOBAL_CERT" ]; then
  warn "cloudflared login finished but no cert was written. Aborting."
  [ -f "$BACKUP_CERT" ] && cp "$BACKUP_CERT" "$GLOBAL_CERT"
  exit 1
fi

info "Moving new cert → $PROJECT_CERT (project-local)"
mv "$GLOBAL_CERT" "$PROJECT_CERT"
chmod 600 "$PROJECT_CERT"

if [ -f "$BACKUP_CERT" ]; then
  info "Restoring previous global cert from backup"
  cp "$BACKUP_CERT" "$GLOBAL_CERT"
  ok "global cert restored; previous tunnels on this machine still work"
fi

# Make sure .gitignore covers the project-local cert
if [ -f .gitignore ] && ! grep -qE '^\.cloudflared/?' .gitignore; then
  echo ".cloudflared/" >> .gitignore
  ok "added .cloudflared/ to .gitignore"
fi

# ─── 4. Create + route the tunnel using the project-local cert ────────────
export TUNNEL_ORIGIN_CERT="$PROJECT_CERT"

read -rp "Tunnel name [${PROJECT_NAME}-dev]: " TUNNEL_NAME
TUNNEL_NAME="${TUNNEL_NAME:-${PROJECT_NAME}-dev}"

# Check if tunnel already exists under this name
EXISTING=$(cloudflared tunnel list --output json 2>/dev/null | node -e "
  let d = ''; process.stdin.on('data', c => d += c).on('end', () => {
    try {
      const t = JSON.parse(d || '[]').find(x => x.name === '$TUNNEL_NAME');
      if (t) process.stdout.write(t.id);
    } catch {}
  });
" 2>/dev/null || echo "")

if [ -n "$EXISTING" ]; then
  ok "Tunnel '$TUNNEL_NAME' already exists (id: $EXISTING)"
  TUNNEL_ID="$EXISTING"
else
  info "Creating tunnel '$TUNNEL_NAME'..."
  cloudflared tunnel create "$TUNNEL_NAME"
  TUNNEL_ID=$(cloudflared tunnel list --output json | node -e "
    let d = ''; process.stdin.on('data', c => d += c).on('end', () => {
      const t = JSON.parse(d).find(x => x.name === '$TUNNEL_NAME');
      process.stdout.write(t.id);
    });
  ")
  ok "Tunnel created (id: $TUNNEL_ID)"
fi

# Move the tunnel credentials JSON next to the cert
TUNNEL_JSON="$HOME/.cloudflared/${TUNNEL_ID}.json"
if [ -f "$TUNNEL_JSON" ]; then
  info "Moving tunnel credentials → $PROJECT_CF_DIR/${TUNNEL_ID}.json"
  mv "$TUNNEL_JSON" "$PROJECT_CF_DIR/${TUNNEL_ID}.json"
  chmod 600 "$PROJECT_CF_DIR/${TUNNEL_ID}.json"
fi

# ─── 5. DNS route ─────────────────────────────────────────────────────────
read -rp "Public hostname to route (e.g. ${PROJECT_NAME}-dev.example.com): " PUBLIC_HOST
if [ -n "$PUBLIC_HOST" ]; then
  info "Routing DNS: $PUBLIC_HOST → tunnel $TUNNEL_NAME"
  cloudflared tunnel route dns "$TUNNEL_NAME" "$PUBLIC_HOST" || warn "route DNS failed (zone might not be in this account)"
else
  warn "No hostname provided — skipping DNS route. You can run later: cloudflared tunnel route dns $TUNNEL_NAME <host>"
fi

# ─── 6. Write project-local config.yml ────────────────────────────────────
# Reads ports from .env if present, else defaults
API_PORT="${API_PORT:-$(grep -E '^API_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 3333)}"
CLIENT_PORT="${CLIENT_PORT:-$(grep -E '^CLIENT_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 4200)}"

cat > "$PROJECT_CF_DIR/config.yml" <<EOF
# Generated by scripts/setup-cloudflared.sh — project-local Cloudflare Tunnel config.
# Run with: bash scripts/start-cloudflared.sh   (uses TUNNEL_ORIGIN_CERT pointing here)
tunnel: ${TUNNEL_ID}
credentials-file: ${PROJECT_CF_DIR}/${TUNNEL_ID}.json

ingress:
  - hostname: ${PUBLIC_HOST:-${TUNNEL_NAME}.example.com}
    service: http://localhost:${API_PORT}
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
ok "Wrote $PROJECT_CF_DIR/config.yml"

# ─── 7. Print the token for .env ──────────────────────────────────────────
TOKEN=$(cloudflared tunnel token "$TUNNEL_NAME" 2>/dev/null || true)
echo ""
echo "============================================="
echo " ✓ Cloudflare Tunnel setup complete."
echo "============================================="
echo ""
if [ -n "$TOKEN" ]; then
  echo "Add this to your .env:"
  echo "  CLOUDFLARE_TUNNEL_TOKEN=$TOKEN"
  echo ""
fi
echo "Boot the tunnel:"
echo "  bash scripts/start-cloudflared.sh"
echo ""
echo "Project artifacts (chmod 600, gitignored):"
echo "  $PROJECT_CERT"
echo "  $PROJECT_CF_DIR/${TUNNEL_ID}.json"
echo "  $PROJECT_CF_DIR/config.yml"
echo ""
echo "Your previous global cert is preserved at $BACKUP_CERT"
echo "(also restored to ~/.cloudflared/cert.pem so other projects' tunnels still work)"
echo ""
