#!/usr/bin/env bash
# validate-setup.sh — Verify project setup is complete and working
# Usage: bash scripts/validate-setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((PASSED++))
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
  ((FAILED++))
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((WARNINGS++))
}

echo "================================================"
echo " Project Setup Validation"
echo "================================================"
echo ""

# 1. Check prerequisites
echo "Checking prerequisites..."
echo ""

if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
  if [[ $MAJOR_VERSION -ge 20 ]]; then
    check_pass "Node.js $NODE_VERSION (required: 20+)"
  else
    check_fail "Node.js $NODE_VERSION (required: 20+)"
  fi
else
  check_fail "Node.js not installed"
fi

if command -v pnpm &> /dev/null; then
  PNPM_VERSION=$(pnpm -v)
  check_pass "pnpm $PNPM_VERSION"
else
  check_fail "pnpm not installed"
fi

if command -v docker &> /dev/null; then
  check_pass "Docker installed"
  if docker ps &> /dev/null; then
    check_pass "Docker daemon running"
  else
    check_warn "Docker installed but daemon not running"
  fi
else
  check_fail "Docker not installed"
fi

if command -v git &> /dev/null; then
  check_pass "Git installed"
else
  check_fail "Git not installed"
fi

echo ""

# 2. Check project configuration
echo "Checking project configuration..."
echo ""

if [[ -f "PROJECT.md" ]]; then
  if grep -q "configured: true" PROJECT.md; then
    check_pass "PROJECT.md exists and configured"
  else
    check_warn "PROJECT.md exists but configured: false"
  fi
else
  check_fail "PROJECT.md not found"
fi

if [[ -f "CLAUDE.md" ]]; then
  check_pass "CLAUDE.md exists"
else
  check_fail "CLAUDE.md not found"
fi

if [[ -f ".env" ]]; then
  check_pass ".env file exists"
else
  check_warn ".env file not found (create with: bash scripts/setup-env.sh --env dev)"
fi

echo ""

# 3. Check dependencies
echo "Checking dependencies..."
echo ""

if [[ -d "node_modules" ]]; then
  check_pass "node_modules exists"
else
  check_warn "node_modules not found (run: pnpm install)"
fi

echo ""

# 4. Check Docker infrastructure
echo "Checking Docker infrastructure..."
echo ""

if command -v docker &> /dev/null && docker ps &> /dev/null; then
  if docker ps --format '{{.Names}}' | grep -q postgres; then
    check_pass "PostgreSQL container running"
  else
    check_warn "PostgreSQL container not running (start with: docker compose up -d)"
  fi

  if docker ps --format '{{.Names}}' | grep -q redis; then
    check_pass "Redis container running"
  else
    check_warn "Redis container not running (optional)"
  fi
else
  check_warn "Cannot check Docker containers (Docker not running)"
fi

echo ""

# 5. Check build
echo "Checking build..."
echo ""

if command -v pnpm &> /dev/null && [[ -d "node_modules" ]]; then
  echo -n "Building API... "
  if pnpm nx build api &> /tmp/build.log; then
    check_pass "API builds successfully"
  else
    check_fail "API build failed (see /tmp/build.log)"
  fi

  echo -n "Building Client... "
  if pnpm nx build client &> /tmp/build.log; then
    check_pass "Client builds successfully"
  else
    check_fail "Client build failed (see /tmp/build.log)"
  fi
else
  check_warn "Skipping build check (dependencies not installed)"
fi

echo ""

# 6. Check linting
echo "Checking code quality..."
echo ""

if command -v pnpm &> /dev/null && [[ -f ".biome.jsonc" || -f "biome.json" ]]; then
  echo -n "Running Biome linter... "
  if pnpm check &> /tmp/lint.log; then
    check_pass "Linting passes"
  else
    check_fail "Linting failed (see /tmp/lint.log)"
  fi
else
  check_warn "Skipping lint check"
fi

echo ""

# 7. Check git setup
echo "Checking Git setup..."
echo ""

if [[ -d ".git" ]]; then
  check_pass "Git repository initialized"

  REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
  if [[ "$REMOTE" != "none" && "$REMOTE" != "https://github.com/alonbilu/claude-dev-starter.git" ]]; then
    check_pass "Git remote configured: $REMOTE"
  else
    check_warn "Git remote is template repo (update with: git remote set-url origin <your-repo>)"
  fi
else
  check_fail "Git repository not initialized"
fi

echo ""

# 8. Check pre-commit hooks
echo "Checking Git hooks..."
echo ""

if [[ -f ".husky/pre-commit" ]]; then
  check_pass "Pre-commit hook configured"
else
  check_warn "Pre-commit hook not found (run: pnpm install to set up)"
fi

echo ""

# 9. Summary
echo "================================================"
echo " Validation Summary"
echo "================================================"
echo ""
echo -e "Passed:  ${GREEN}$PASSED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Setup is valid!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Start Docker: docker compose up -d"
  echo "  2. Run migrations: pnpm nx run database:migrate:dev --name init"
  echo "  3. Start dev servers:"
  echo "     - Terminal 1: pnpm nx serve api"
  echo "     - Terminal 2: pnpm nx serve client"
  echo "  4. Start your first feature: /new-feature [name]"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Setup has issues. Fix them above before continuing.${NC}"
  echo ""
  exit 1
fi
