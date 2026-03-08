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

# Install Node.js 20
echo ""
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
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

# Setup firewall
echo "Configuring firewall (ufw)..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "  ✓ Firewall: ports 22, 80, 443 open"

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
cat > /etc/nginx/sites-available/app << NGINX
server {
    listen 443 ssl;
    server_name $DOMAIN;

    location /api/ {
        proxy_pass http://localhost:3333;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        proxy_pass http://localhost:4200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

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
