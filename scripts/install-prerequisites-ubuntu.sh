#!/usr/bin/env bash
# install-prerequisites-ubuntu.sh — Install all dev prerequisites on Ubuntu 22.04+
# Usage: bash scripts/install-prerequisites-ubuntu.sh
#
# Installs: Node.js 20, pnpm 10, Docker Engine, Claude Code CLI, gh CLI
# Note: VS Code is desktop-only — install manually from https://code.visualstudio.com if needed

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

echo ""
echo "Claude Dev Starter — Ubuntu Prerequisites Installer"
echo "===================================================="
echo "Target: Ubuntu 22.04+"
echo ""

# ── Node.js 20 (via NodeSource) ─────────────────────────────────────────────
if node --version 2>/dev/null | grep -q "^v2[0-9]"; then
  ok "Node.js $(node --version) already installed"
else
  info "Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ok "Node.js $(node --version) installed"
fi

# ── pnpm 10 ─────────────────────────────────────────────────────────────────
if pnpm --version 2>/dev/null | grep -q "^10"; then
  ok "pnpm $(pnpm --version) already installed"
else
  info "Installing pnpm 10..."
  npm install -g pnpm@latest
  ok "pnpm $(pnpm --version) installed"
fi

# ── Docker Engine (not Docker Desktop — no GUI needed on Ubuntu) ─────────────
if docker --version &>/dev/null; then
  ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') already installed"
else
  info "Installing Docker Engine..."
  sudo apt-get update -qq
  sudo apt-get install -y ca-certificates curl gnupg lsb-release

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Allow running docker without sudo
  sudo usermod -aG docker "$USER"
  ok "Docker installed. NOTE: Log out and back in for group change to take effect."
  echo "   (Or run: newgrp docker)"
fi

# ── Claude Code CLI ──────────────────────────────────────────────────────────
if claude --version &>/dev/null; then
  ok "Claude Code CLI already installed"
else
  info "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code CLI $(claude --version) installed"
fi

# ── gh CLI ───────────────────────────────────────────────────────────────────
if gh --version &>/dev/null; then
  ok "gh CLI $(gh --version | head -1 | cut -d' ' -f3) already installed"
else
  info "Installing gh CLI..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gh
  ok "gh CLI $(gh --version | head -1 | cut -d' ' -f3) installed"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "===================================================="
echo "All prerequisites installed."
echo ""
echo "Next steps:"
echo "  1. If Docker was just installed: log out and back in (or run: newgrp docker)"
echo "  2. Authenticate GitHub CLI:  gh auth login"
echo "  3. Authenticate Claude Code: claude"
echo ""
echo "Then return to SETUP.md and continue from Step 2: /setup-project"
