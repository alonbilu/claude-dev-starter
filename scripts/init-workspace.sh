#!/usr/bin/env bash
#
# init-workspace.sh — Scaffold the Nx workspace inside a configured kit clone.
#
# RUN THIS AFTER /setup-project HAS WRITTEN PROJECT.md.
#
# What it does (idempotent — safe to re-run):
#   1. Validates cwd is the project root + PROJECT.md exists
#   2. Pre-writes .npmrc + package.json with pnpm.onlyBuiltDependencies so pnpm 11
#      doesn't block postinstall scripts on `nx init` / `unrs-resolver`
#   3. Runs `nx init` into the existing directory (NOT create-nx-workspace, which
#      would create a sub-dir and clobber the kit's files)
#   4. Generates apps (React+Vite client, NestJS api) + the kit's lib layout
#   5. Installs all kit-mandatory deps + integration-specific deps based on
#      PROJECT.md
#   6. Removes the `build` target from domain/shared libs (per architecture.md)
#   7. Initializes a Prisma 7.8 schema skeleton
#   8. Boots docker compose + waits for postgres healthy
#   9. Runs `pnpm rebuild`, `pnpm nx reset`, and asserts every expected project
#      shows up in `pnpm nx show projects`
#
# Every step here is the distilled output of a real downstream user's run with
# 17 reported gotchas. See `.claude/knowledge/stack-gotchas.md` →
# "Scaffolding & Tooling" for the full list of failure modes this protects
# against.
#
# Usage:
#   bash scripts/init-workspace.sh
#
# Optional environment overrides:
#   PROJECT_NAME      — defaults to PROJECT.md's project_name or the git remote
#   PROJECT_TYPE      — defaults to PROJECT.md's type
#   AUTH_PROVIDER     — defaults to PROJECT.md's auth_provider
#   SKIP_DOCKER=1     — skip the docker compose boot + healthy-wait

set -euo pipefail

# ───────────────────────────────────────────────────────────────
# [1] cwd guard — anchor to the project root
# ───────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f PROJECT.md ]; then
  echo "✗ Not at project root (no PROJECT.md found in $ROOT_DIR)"
  echo "  This script must run from a kit clone that has been configured by /setup-project."
  exit 1
fi

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }
warn() { echo -e "${RED}!${NC} $1"; }
hdr()  { echo ""; echo -e "${BLUE}━━━ $1 ━━━${NC}"; }

# ───────────────────────────────────────────────────────────────
# [2] Read project config from PROJECT.md
# ───────────────────────────────────────────────────────────────
hdr "Reading PROJECT.md configuration"
PROJECT_TYPE="${PROJECT_TYPE:-$(grep -E '^type:' PROJECT.md | head -1 | awk '{print $2}')}"
AUTH_PROVIDER="${AUTH_PROVIDER:-$(grep -E '^auth_provider:' PROJECT.md | head -1 | awk '{print $2}')}"
PROJECT_NAME="${PROJECT_NAME:-$(basename "$ROOT_DIR")}"

# Detect enabled integrations from PROJECT.md (checkbox `[x]` lines)
integration_enabled() {
  grep -qE "^\- \[x\] $1\s" PROJECT.md
}

HAS_FRONTEND=true
HAS_BACKEND=true
HAS_DATABASE=true
case "$PROJECT_TYPE" in
  api-only)      HAS_FRONTEND=false ;;
  static-site)   HAS_BACKEND=false; HAS_DATABASE=false ;;
  cli|library)   HAS_FRONTEND=false; HAS_BACKEND=false; HAS_DATABASE=false ;;
  worker)        HAS_FRONTEND=false ;;
esac

echo "  Project name:    $PROJECT_NAME"
echo "  Project type:    ${PROJECT_TYPE:-unknown}"
echo "  Auth provider:   ${AUTH_PROVIDER:-none}"
echo "  Frontend:        $HAS_FRONTEND"
echo "  Backend:         $HAS_BACKEND"
echo "  Database:        $HAS_DATABASE"

# ───────────────────────────────────────────────────────────────
# [3] Pre-flight — package.json + .npmrc preamble
# ───────────────────────────────────────────────────────────────
hdr "Pre-flight: package.json + .npmrc (pnpm 11 build-script preamble)"

if [ ! -f package.json ]; then
  info "writing initial package.json"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('package.json', JSON.stringify({
      name: '$PROJECT_NAME',
      version: '0.1.0',
      private: true,
      packageManager: 'pnpm@11.5.0',
      pnpm: {
        // Pre-approved build scripts so pnpm 11 doesn't block postinstall on \`nx init\`,
        // \`unrs-resolver\`, Prisma, esbuild, etc. (see stack-gotchas → Scaffolding).
        onlyBuiltDependencies: [
          '@prisma/engines', 'prisma', 'esbuild', 'unrs-resolver', '@swc/core',
          '@nestjs/core', 'sharp'
        ]
      }
    }, null, 2) + '\n');
  "
  ok "package.json written"
else
  ok "package.json already exists; preserving"
  # But make sure onlyBuiltDependencies is set, even on an existing file:
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('package.json','utf8'));
    p.pnpm = p.pnpm || {};
    const need = ['@prisma/engines','prisma','esbuild','unrs-resolver','@swc/core','@nestjs/core','sharp'];
    p.pnpm.onlyBuiltDependencies = Array.from(new Set([...(p.pnpm.onlyBuiltDependencies || []), ...need]));
    fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
  "
fi

# .npmrc — belt-and-braces for the onlyBuiltDependencies setting
[ -f .npmrc ] || cat > .npmrc <<'EOF'
# pnpm 11 build-script policy. The onlyBuiltDependencies list in package.json is the source
# of truth; this just keeps pnpm verbose so blocked builds are visible at install time.
auto-install-peers=true
strict-peer-dependencies=false
EOF
ok ".npmrc in place"

# ───────────────────────────────────────────────────────────────
# [4] nx init (idempotent)
# ───────────────────────────────────────────────────────────────
hdr "Initializing Nx into the existing directory"
if [ -f nx.json ]; then
  ok "nx.json already present; skipping nx init"
else
  info "running pnpm dlx nx@latest init --interactive=false --useNxCloud=skip"
  # Tolerate nx init's non-zero exit when pnpm 11 emits a build-script warning —
  # the install itself succeeded if nx.json got created.
  pnpm dlx nx@latest init --interactive=false --useNxCloud=skip || true
  [ -f nx.json ] || { warn "nx init did not produce nx.json — bailing"; exit 1; }
  ok "Nx initialized"
fi

# ───────────────────────────────────────────────────────────────
# [5] Install Nx generators (idempotent)
# ───────────────────────────────────────────────────────────────
hdr "Installing Nx generator plugins"
NX_PKGS=("@nx/js")
$HAS_FRONTEND && NX_PKGS+=("@nx/react" "@nx/vite")
$HAS_BACKEND && NX_PKGS+=("@nx/nest" "@nx/esbuild")
info "pnpm add -D ${NX_PKGS[*]}"
pnpm add -D "${NX_PKGS[@]}"
ok "generator plugins installed"

# ───────────────────────────────────────────────────────────────
# [6] Generate apps + libs (always use --name=, never positional)
# ───────────────────────────────────────────────────────────────
hdr "Generating apps + libs"

# Frontend app
if $HAS_FRONTEND; then
  if [ -d apps/client ]; then
    ok "apps/client already exists; skipping"
  else
    info "generating apps/client (React + Vite + Vitest + Playwright)"
    pnpm nx g @nx/react:application \
      --name=client \
      --directory=apps/client \
      --bundler=vite \
      --unitTestRunner=vitest \
      --e2eTestRunner=playwright \
      --linter=none \
      --style=css \
      --routing=true \
      --no-interactive
    ok "apps/client generated"
  fi
fi

# Backend app
if $HAS_BACKEND; then
  if [ -d apps/api ]; then
    ok "apps/api already exists; skipping"
  else
    info "generating apps/api (NestJS + Jest)"
    pnpm nx g @nx/nest:application \
      --name=api \
      --directory=apps/api \
      --unitTestRunner=jest \
      --linter=none \
      --no-interactive
    ok "apps/api generated"
  fi
fi

# Shared libs — always
for libdef in \
  "types:libs/shared/types:jest" \
  "utils:libs/shared/utils:jest" \
  "config:libs/shared/config:jest"; do
  IFS=':' read -r name dir runner <<< "$libdef"
  if [ -d "$dir" ]; then
    ok "$dir already exists; skipping"
  else
    info "generating $dir ($runner)"
    pnpm nx g @nx/js:library --name="$name" --directory="$dir" --linter=none --unitTestRunner="$runner" --no-interactive
  fi
done

# Frontend-only shared lib
if $HAS_FRONTEND; then
  if [ -d libs/shared/ui ]; then
    ok "libs/shared/ui already exists; skipping"
  else
    info "generating libs/shared/ui (vitest)"
    pnpm nx g @nx/js:library --name=ui --directory=libs/shared/ui --linter=none --unitTestRunner=vitest --bundler=vite --no-interactive
  fi
fi

# Database lib
if $HAS_DATABASE; then
  if [ -d libs/domain/database ]; then
    ok "libs/domain/database already exists; skipping"
  else
    info "generating libs/domain/database (jest)"
    pnpm nx g @nx/js:library --name=database --directory=libs/domain/database --linter=none --unitTestRunner=jest --no-interactive
  fi
fi

# Backend core lib
if $HAS_BACKEND; then
  if [ -d libs/backend/core ]; then
    ok "libs/backend/core already exists; skipping"
  else
    info "generating libs/backend/core (NestJS lib)"
    pnpm nx g @nx/nest:library --name=core --directory=libs/backend/core --linter=none --no-interactive
  fi
fi

# ───────────────────────────────────────────────────────────────
# [7] Post-generation cleanup: remove `build` target from domain/shared libs
#     (Documented in architecture.md but unscripted before now.)
# ───────────────────────────────────────────────────────────────
hdr "Removing 'build' target from domain/shared libs"
for libpath in \
  libs/shared/types \
  libs/shared/utils \
  libs/shared/config \
  libs/shared/ui \
  libs/domain/database \
  libs/backend/core; do
  pj="$libpath/project.json"
  if [ -f "$pj" ]; then
    node -e "
      const fs = require('fs');
      const f = '$pj';
      const j = JSON.parse(fs.readFileSync(f, 'utf8'));
      if (j.targets && j.targets.build) {
        delete j.targets.build;
        fs.writeFileSync(f, JSON.stringify(j, null, 2) + '\n');
        console.log('  - removed build target from $libpath');
      }
    "
  fi
done
ok "domain/shared libs cleaned"

# ───────────────────────────────────────────────────────────────
# [8] Install kit-mandatory runtime + dev deps
# ───────────────────────────────────────────────────────────────
hdr "Installing kit-mandatory deps"

# Core runtime — every project type gets these
pnpm add reflect-metadata zod

# Frontend stack
if $HAS_FRONTEND; then
  pnpm add react-hook-form @hookform/resolvers \
           @tanstack/react-router @tanstack/react-query
  pnpm add -D @testing-library/react @testing-library/jest-dom jsdom @vitejs/plugin-react
fi

# Backend stack — security middleware + OpenAPI are mandatory (api.md)
if $HAS_BACKEND; then
  pnpm add helmet @nestjs/throttler @nestjs/swagger
fi

# Database stack
if $HAS_DATABASE; then
  pnpm add @prisma/client @prisma/adapter-pg pg
  pnpm add -D prisma
fi

# Linting / formatting (always)
pnpm add -D @biomejs/biome

# ───────────────────────────────────────────────────────────────
# [9] Install integration-specific deps based on PROJECT.md
# ───────────────────────────────────────────────────────────────
hdr "Installing integration deps (from PROJECT.md)"

# Auth provider — Zitadel needs its own SDK; Better Auth otherwise
case "$AUTH_PROVIDER" in
  zitadel)
    info "Zitadel auth"
    # @zitadel/client + @zitadel/proto are the current canonical packages (verify with `pnpm view`)
    pnpm add @zitadel/client @zitadel/proto || warn "Zitadel package install failed — verify package names with: pnpm view @zitadel/client"
    ;;
  better-auth|"")
    info "Better Auth (default)"
    pnpm add better-auth @thallesp/nestjs-better-auth || warn "Better Auth install failed — check package names"
    ;;
esac

# Hydra (M2M auth) — opt-in
if integration_enabled hydra; then
  info "Hydra (M2M tokens) — no client SDK; the kit uses fetch against the Hydra admin/public APIs directly"
fi

# Logging provider — pick one based on logging_provider in PROJECT.md (or skip)
LOGGING_PROVIDER=$(grep -E '^logging_provider:' PROJECT.md 2>/dev/null | head -1 | awk '{print $2}')
if integration_enabled logging; then
  case "$LOGGING_PROVIDER" in
    axiom|"") info "Axiom logging"; pnpm add @axiomhq/js ;;
    grafana-cloud) info "Grafana Cloud logging (Loki Pino transport)"; pnpm add pino pino-loki ;;
    better-stack) info "Better Stack logging"; pnpm add @logtail/pino ;;
  esac
fi

# Tracing — OpenTelemetry
if integration_enabled tracing; then
  info "OpenTelemetry tracing"
  pnpm add @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
  $HAS_FRONTEND && pnpm add @opentelemetry/sdk-trace-web
fi

# Feature flags
FF_PROVIDER=$(grep -E '^feature_flags_provider:' PROJECT.md 2>/dev/null | head -1 | awk '{print $2}')
if integration_enabled feature-flags; then
  case "$FF_PROVIDER" in
    growthbook|"") info "GrowthBook"; pnpm add @growthbook/growthbook-react ;;
    unleash) info "Unleash"; pnpm add unleash-client ;;
    launchdarkly) info "LaunchDarkly"; pnpm add launchdarkly-node-server-sdk ;;
  esac
fi

# Email
if integration_enabled email; then
  info "Resend email"
  pnpm add resend
fi

# Payments
if integration_enabled payments; then
  info "Stripe"
  pnpm add stripe
fi

# Queue (BullMQ + Redis/Valkey)
if integration_enabled queue; then
  info "BullMQ"
  pnpm add @nestjs/bullmq bullmq ioredis
fi

# Storage (S3)
if integration_enabled storage; then
  info "S3 (AWS SDK v3)"
  pnpm add @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
fi

# E2E (Playwright already installed when @nx/react app was generated; verify only)
if integration_enabled e2e && [ ! -d apps/client-e2e ]; then
  info "Playwright already included by @nx/react:application; apps/client-e2e exists or will after first nx e2e run"
fi

# i18n
if integration_enabled i18n; then
  info "react-i18next"
  $HAS_FRONTEND && pnpm add i18next react-i18next i18next-browser-languagedetector
fi

ok "integration deps installed"

# ───────────────────────────────────────────────────────────────
# [10] Prisma schema skeleton
# ───────────────────────────────────────────────────────────────
if $HAS_DATABASE && [ ! -f libs/domain/database/prisma/schema.prisma ]; then
  hdr "Writing Prisma 7.8 schema skeleton"
  mkdir -p libs/domain/database/prisma
  cat > libs/domain/database/prisma/schema.prisma <<'EOF'
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}

// Prisma 7.8: NO `url = env(...)` here. The migrate CLI needs --url= explicitly
// (or a prisma.config.ts at the workspace root). See:
//   .claude/knowledge/stack-gotchas.md → "Prisma 7.8 migrations".
datasource db {
  provider = "postgresql"
}

// Define your models here. Then create the first migration:
//   source .env
//   npx prisma migrate dev --name init \
//     --schema=libs/domain/database/prisma/schema.prisma \
//     --url="$DATABASE_URL"
EOF
  ok "schema.prisma skeleton at libs/domain/database/prisma/"
fi

# ───────────────────────────────────────────────────────────────
# [11] Husky + lint-staged (the kit's pre-commit hook)
# ───────────────────────────────────────────────────────────────
hdr "Installing husky + lint-staged"
# install-pre-commit.sh handles the ordering correctly — adds the prepare script
# only AFTER husky lands in node_modules.
bash scripts/install-pre-commit.sh

# ───────────────────────────────────────────────────────────────
# [12] Docker compose boot + healthy-wait
# ───────────────────────────────────────────────────────────────
if [ -z "${SKIP_DOCKER:-}" ] && $HAS_DATABASE; then
  hdr "Booting docker compose + waiting for postgres healthy"
  docker compose up -d
  info "waiting for postgres healthy (timeout 90s)..."
  if timeout 90 bash -c '
    until docker compose ps --format json 2>/dev/null \
      | jq -e ". | (if type==\"array\" then .[] else . end) | select(.Service==\"postgres\") | .Health == \"healthy\"" >/dev/null 2>&1; do
      sleep 2
    done
  '; then
    ok "postgres healthy"
  else
    warn "postgres did not reach healthy state within 90s — inspect with: docker compose logs postgres"
  fi
fi

# ───────────────────────────────────────────────────────────────
# [13] Final passes — rebuild, nx reset, project discovery assertion
# ───────────────────────────────────────────────────────────────
hdr "Final passes"
info "pnpm rebuild (force any blocked postinstalls to actually run)"
pnpm rebuild
info "pnpm nx reset (clear stale plugin cache)"
pnpm nx reset >/dev/null 2>&1 || true

info "verifying all expected projects show up..."
EXPECTED=()
$HAS_FRONTEND && EXPECTED+=("client" "ui")
$HAS_BACKEND && EXPECTED+=("api" "core")
$HAS_DATABASE && EXPECTED+=("database")
EXPECTED+=("types" "utils" "config")

ACTUAL=$(pnpm nx show projects 2>/dev/null | sort -u | tr '\n' ' ')
MISSING=0
for name in "${EXPECTED[@]}"; do
  if echo "$ACTUAL" | grep -qw "$name"; then
    echo "  ✓ $name"
  else
    echo "  ✗ MISSING: $name"
    MISSING=$((MISSING + 1))
  fi
done
[ $MISSING -eq 0 ] || { warn "$MISSING project(s) missing — investigate before proceeding"; exit 1; }

# ───────────────────────────────────────────────────────────────
# [14] Build smoke test
# ───────────────────────────────────────────────────────────────
hdr "Build smoke test"
$HAS_FRONTEND && { info "pnpm nx build client"; pnpm nx build client; ok "client build OK"; }
$HAS_BACKEND  && { info "pnpm nx build api";    pnpm nx build api;    ok "api build OK"; }

# ───────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✓ Workspace scaffolding complete."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
if $HAS_DATABASE; then
  echo "  • First DB migration:"
  echo "      source .env && npx prisma migrate dev --name init \\"
  echo "        --schema=libs/domain/database/prisma/schema.prisma \\"
  echo "        --url=\"\$DATABASE_URL\""
fi
$HAS_BACKEND  && echo "  • Run the API:    pnpm nx serve api"
$HAS_FRONTEND && echo "  • Run the client: pnpm nx serve client"
echo "  • Start a feature: /new-feature [name]"
echo ""
