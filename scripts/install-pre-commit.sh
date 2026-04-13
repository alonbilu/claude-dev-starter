#!/usr/bin/env bash
#
# install-pre-commit.sh
#
# Installs husky + lint-staged so Biome runs on every git commit.
# Idempotent — safe to run multiple times.
#
# This script realizes the "Biome on pre-commit" promise documented in
# .claude/rules/code-quality.md. Without husky + lint-staged, Biome is
# only a local dev tool — it does NOT prevent style/quality regressions
# from being committed.
#
# Usage:
#   bash scripts/install-pre-commit.sh
#

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

echo "[install-pre-commit] working in: $PROJECT_DIR"

# 1. Verify package.json exists
if [ ! -f "package.json" ]; then
  echo "[install-pre-commit] ERROR: no package.json at $PROJECT_DIR"
  echo "  Run this from the project root, or set CLAUDE_PROJECT_DIR."
  exit 1
fi

# 2. Verify biome is installed (precondition)
if ! npm ls @biomejs/biome >/dev/null 2>&1; then
  echo "[install-pre-commit] WARN: @biomejs/biome is not installed yet."
  echo "  Install it first:  npm install --save-dev @biomejs/biome"
  echo "  Then re-run this script."
  exit 1
fi

# 3. Detect package manager (default to npm)
PM="npm"
if [ -f "pnpm-lock.yaml" ]; then PM="pnpm"; fi
if [ -f "yarn.lock" ]; then PM="yarn"; fi
echo "[install-pre-commit] detected package manager: $PM"

# 4. Install husky + lint-staged if missing
NEEDS_HUSKY=true
NEEDS_LINT_STAGED=true
if npm ls husky >/dev/null 2>&1; then NEEDS_HUSKY=false; fi
if npm ls lint-staged >/dev/null 2>&1; then NEEDS_LINT_STAGED=false; fi

if [ "$NEEDS_HUSKY" = true ] || [ "$NEEDS_LINT_STAGED" = true ]; then
  echo "[install-pre-commit] installing dev deps: husky lint-staged"
  case "$PM" in
    pnpm) pnpm add -D husky lint-staged ;;
    yarn) yarn add -D husky lint-staged ;;
    *)    npm install --save-dev husky lint-staged ;;
  esac
else
  echo "[install-pre-commit] husky + lint-staged already installed; skipping"
fi

# 5. Initialize husky (creates .husky/ dir + git hook)
if [ ! -d ".husky" ]; then
  echo "[install-pre-commit] initializing husky"
  npx husky init
else
  echo "[install-pre-commit] .husky/ already exists; skipping init"
fi

# 6. Write the pre-commit hook (overwrites whatever was there)
echo "[install-pre-commit] writing .husky/pre-commit"
cat > .husky/pre-commit <<'EOF'
npx lint-staged
EOF
chmod +x .husky/pre-commit

# 7. Add lint-staged config to package.json if missing
if ! node -e "const p=require('./package.json'); process.exit(p['lint-staged']?0:1)" >/dev/null 2>&1; then
  echo "[install-pre-commit] adding lint-staged config to package.json"
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    p['lint-staged'] = {
      '*.{ts,tsx,js,jsx}': [
        'biome check --write --no-errors-on-unmatched --files-ignore-unknown=true'
      ]
    };
    if (!p.scripts) p.scripts = {};
    if (!p.scripts.prepare) p.scripts.prepare = 'husky';
    fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
  "
else
  echo "[install-pre-commit] lint-staged config already present in package.json; leaving as-is"
fi

# 8. Sanity check: try a commit-style invocation
echo ""
echo "[install-pre-commit] DONE"
echo ""
echo "Verify by staging a TypeScript file and running:"
echo "  npx lint-staged"
echo ""
echo "Or just: make a git commit. Husky should auto-fire and run Biome on staged files."
echo "If Biome finds an error it can fix → it auto-fixes + re-stages + commit proceeds."
echo "If Biome finds an error it CAN'T fix → commit is blocked. Fix and retry."
echo ""
echo "Emergency bypass (use rarely): git commit --no-verify"
