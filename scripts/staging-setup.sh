#!/usr/bin/env bash
# staging-setup.sh — One-time server bootstrap for a fresh Ubuntu 22+ server
# Usage: bash scripts/staging-setup.sh
# Run on the server as root (or with sudo)

set -euo pipefail

echo "================================================"
echo " Staging Server Bootstrap"
echo "================================================"
echo ""

# Collect configuration
read -rp "Domain name (e.g. app.example.com): " DOMAIN
read -rp "App directory (e.g. /var/www/my-app): " APP_DIR
read -rp "GitHub repo URL (e.g. https://github.com/user/repo): " REPO_URL

echo ""
echo "Configuration:"
echo "  Domain:    $DOMAIN"
echo "  App dir:   $APP_DIR"
echo "  Repo:      $REPO_URL"
echo ""
read -rp "Proceed with setup? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# Optional baseline hardening (recommended on a fresh server)
echo ""
read -rp "Run baseline server hardening first (SSH port + ufw + fail2ban + auto-updates)? [Y/n]: " harden
if [[ ! "$harden" =~ ^[Nn]$ ]]; then
  # Run before installing apps so the firewall is in place when ports start binding.
  bash "$(dirname "$0")/harden-server.sh"
  echo ""
  read -rp "Hardening complete. Continue with app setup on this connection? [y/N]: " cont
  [[ "$cont" =~ ^[Yy]$ ]] || { echo "Stopping. Reconnect on the new SSH port and re-run this script — it's idempotent."; exit 0; }
fi

# Install Node.js 22
echo ""
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Install pnpm
echo "Installing pnpm..."
npm install -g pnpm

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install PM2
echo "Installing PM2..."
npm install -g pm2

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Install Certbot
echo "Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# Firewall is already configured by harden-server.sh (if it was run). If hardening was
# skipped, fall back to a minimal default — but you really should run harden-server.sh
# before exposing anything to the internet.
if ! command -v ufw >/dev/null; then
  echo "Configuring fallback firewall (ufw)..."
  apt-get install -y ufw
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  echo "  ✓ Firewall: ports 22, 80, 443 open (run scripts/harden-server.sh for proper hardening)"
fi

# Clone repository
echo ""
echo "Cloning repository..."
mkdir -p "$APP_DIR"
git clone "$REPO_URL" "$APP_DIR"

# Configure environment
echo ""
echo "Setting up environment variables..."
cd "$APP_DIR"
bash scripts/setup-env.sh --env staging

# Install dependencies
echo ""
echo "Installing dependencies..."
pnpm install --frozen-lockfile

# SSL certificate
echo ""
echo "Setting up SSL certificate..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

# Setup Nginx
echo "Configuring Nginx..."

# Rate-limit + connection-cap zones live in the http {} context, so a separate file in conf.d/.
cat > /etc/nginx/conf.d/rate-limits.conf << 'LIMITS'
# Per-IP rate-limit zones — referenced by site configs in sites-enabled/.
#   api_limit    — general API (10 req/s sustained, burst absorbed by `burst=` in site)
#   login_limit  — auth endpoints, much tighter (5 req/min)
limit_req_zone   $binary_remote_addr zone=api_limit:10m   rate=10r/s;
limit_req_zone   $binary_remote_addr zone=login_limit:10m rate=5r/m;
# Per-IP concurrent connection cap (HTTP-level — total open keep-alive conns).
limit_conn_zone  $binary_remote_addr zone=conn_limit:10m;

# When clients are behind Cloudflare / a load balancer, trust X-Forwarded-For from those IPs
# only. Uncomment + adjust to your setup. (Defaults to off — set_real_ip_from disabled.)
# set_real_ip_from 173.245.48.0/20;
# real_ip_header   X-Forwarded-For;
LIMITS

cat > /etc/nginx/sites-available/app << NGINX
server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;

    # Body-size cap. Override per-location for uploads if needed.
    client_max_body_size 10M;
    client_body_timeout  30s;
    send_timeout         30s;
    keepalive_timeout    65s;

    # Per-IP concurrent connection cap.
    limit_conn conn_limit 20;

    # Security headers (belt-and-braces — \`helmet\` on the API also sets several of these).
    add_header X-Frame-Options           "SAMEORIGIN" always;
    add_header X-Content-Type-Options    "nosniff"    always;
    add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Compression for text-ish responses.
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;

    # Auth endpoints — extra-tight rate limit (must come BEFORE the broader /api/ block).
    location ~ ^/api/v1/(auth|login|signup|register|reset-password) {
        limit_req zone=login_limit burst=5 nodelay;
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # General API.
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    # Health probes — no rate limit (orchestrators poll these constantly).
    location ~ ^/api/v1/health(/live|/ready)?$ {
        access_log off;
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }

    # Static client.
    location / {
        proxy_pass http://localhost:4200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host       \$host;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
echo "  ✓ Nginx: rate limiting (api 10r/s, auth 5r/min), HTTP/2, gzip, security headers"

# PM2 startup
echo "Configuring PM2 auto-start..."
pm2 startup
pm2 save

echo ""
echo "================================================"
echo " Bootstrap complete!"
echo ""
echo " Next: run bash scripts/staging-deploy.sh"
echo "================================================"
