# Claude Dev Starter Kit

A generic, project-type-agnostic development starter kit built around Claude Code.
Works for SaaS apps, APIs, CLIs, libraries, and more.

---

## Quick Start (New Project Checklist)

You just cloned this template. Here's the exact sequence from zero to first feature:

```
1. Install prerequisites
   Node 20+, pnpm 9, Docker, VS Code, Claude Code CLI, gh CLI
   On Ubuntu: bash scripts/install-prerequisites-ubuntu.sh

2. Clone the template and connect it to your own GitHub repo
   git clone https://github.com/alon-codes/claude-dev-starter my-project
   cd my-project

   # Disconnect from the template remote
   git remote remove origin

   # Create a new repo on GitHub and push (requires gh CLI)
   gh repo create YOUR_ORG/my-project --private --source=. --remote=origin --push

   # Alternative (without gh CLI):
   # git remote add origin https://github.com/YOUR_ORG/my-project.git
   # git push -u origin main

3. Configure your project (interactive wizard)
   Open Claude Code in this directory, then run:
     /setup-project
   Asks about your project type, infrastructure, and ports,
   then configures all files automatically.

4. Set up your dev environment secrets
   bash scripts/setup-env.sh --env dev
   (Generates .env with auto-generated secrets + validates connectivity)

5. Start Docker infrastructure
   docker compose up -d

6. Install dependencies and initialize database (if applicable)
   pnpm install
   pnpm nx run database:migrate:dev --name init

7. Start developing
   pnpm nx serve api      # Terminal 1 → http://localhost:3333
   pnpm nx serve client   # Terminal 2 → http://localhost:4200

8. Start your first feature
   /new-feature [your-feature-name]
```

Everything below explains WHY and HOW when you want to understand the system or when things go wrong.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [What's in This Template](#whats-in-this-template)
3. [Project Type System](#project-type-system)
4. [Stack Overview](#stack-overview)
5. [Claude Code Setup](#claude-code-setup)
6. [The Development Workflow](#the-development-workflow)
7. [Context Window Management](#context-window-management)
8. [Environment Variables](#environment-variables)
9. [Docker Infrastructure](#docker-infrastructure)
10. [Database Setup](#database-setup)
11. [Biome Linting](#biome-linting)
12. [Staging Deployment](#staging-deployment)
13. [Production Deployment](#production-deployment)
14. [Common Commands Reference](#common-commands-reference)
15. [Gotchas Quick Reference](#gotchas-quick-reference)

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 20+ | https://nodejs.org |
| pnpm | 9+ | `npm install -g pnpm` |
| Docker Desktop | Latest | https://docker.com |
| VS Code | Latest | https://code.visualstudio.com |
| Claude Code CLI | Latest | https://claude.ai/claude-code |
| gh CLI | Latest | https://cli.github.com |
| ngrok (optional) | Latest | https://ngrok.com (OAuth/webhooks only) |

**On Ubuntu 22.04+?** Run the included install script — it handles everything automatically:

```bash
bash scripts/install-prerequisites-ubuntu.sh
```

Installs: Node.js 20 (via NodeSource), pnpm, Docker Engine, Claude Code CLI, gh CLI.
After it finishes, log out and back in (needed for Docker group), then `gh auth login` and `claude`.

---

## What's in This Template

```
claude-dev-starter/
├── SETUP.md                     ← This file
├── PROJECT.md                   ← Project config (fill in via /setup-project)
├── CLAUDE.md                    ← Claude Code instructions (read every session)
├── .claude/
│   ├── brain.md                 ← Institutional memory (≤200 lines)
│   ├── settings.json            ← Auto-approve safe ops, gate destructive ones
│   ├── commands/
│   │   ├── setup-project.md     ← /setup-project interactive wizard
│   │   └── trim-context.md      ← /trim-context intelligent content trimmer
│   ├── knowledge/               ← On-demand reference (not loaded every session)
│   │   ├── stack-gotchas.md     ← Critical gotchas (DI, Prisma, testing, Biome)
│   │   ├── patterns.md          ← Reusable backend + frontend patterns
│   │   └── decisions.md         ← Architecture decisions log template
│   └── rules/                   ← Loaded every session via CLAUDE.md
│       ├── architecture.md      ← Layering, import rules, reuse commandments
│       ├── api.md               ← NestJS, Better Auth, validation
│       ├── database.md          ← Prisma, migrations, gotchas
│       ├── frontend.md          ← React, TanStack Query, forms
│       ├── testing.md           ← Jest, coverage, patterns
│       ├── code-quality.md      ← Biome, lint-staged, conventions
│       ├── deployment.md        ← Docker, environments, deploy scripts
│       └── ai-workflow.md       ← Feature workflow, brain.md protocol
├── docs/
│   ├── WORKFLOW-GUIDE.md        ← Practical feature workflow walkthrough
│   ├── FEATURE-STATUS.md        ← Central feature tracking dashboard
│   ├── ENTITY-CLASSIFICATION.md ← When to create modules/services/processors
│   └── features/
│       ├── active/              ← In-progress features
│       ├── completed/           ← Archived features
│       └── backlog/             ← Future ideas
├── docker-compose.yml           ← PostgreSQL dev + test + Redis
├── biome.json                   ← Linting + formatting (battle-tested config)
├── .vscode/                     ← Extensions + format-on-save settings
├── .husky/pre-commit            ← Runs Biome on staged files automatically
├── .env.example                 ← All env vars documented (committed to git)
├── package.json.template.md     ← Scripts + lint-staged reference
└── scripts/
    ├── setup-env.sh             ← Env wizard for dev/staging/production
    ├── dev.sh                   ← Dev environment orchestrator
    ├── start-db.sh              ← Quick database startup
    ├── start-ngrok.sh           ← ngrok tunnels for OAuth/webhook testing
    ├── staging-setup.sh         ← One-time server bootstrap
    ├── staging-deploy.sh        ← Incremental staging deploy
    ├── production-deploy.sh     ← Production deploy with safety gates
    └── trim-context.sh          ← Context window audit + mechanical cleanup
```

---

## Project Type System

`PROJECT.md` is the project identity card. Claude reads it every session.
It controls which rules apply and what `/setup-project` configures.

### Supported Types

| Type | Layers | Use case |
|------|--------|----------|
| `saas-web-app` | frontend + backend + database + auth | Full-stack web app |
| `api-only` | backend + database + auth | Backend API only |
| `fullstack-web` | frontend + backend + database | Web app without billing |
| `cli` | backend logic only | Command-line tool |
| `library` | types + utils | Reusable package or SDK |
| `static-site` | frontend only | Static site / landing page |

### Optional Integrations

| Integration | What it adds |
|-------------|-------------|
| `payments` | Stripe subscriptions + webhook handling |
| `email` | Resend + React Email templates |
| `storage` | S3-compatible object storage |
| `llm` | OpenAI / Anthropic provider integrations |
| `rag` | pgvector embeddings + similarity search (also switches postgres image) |
| `queue` | BullMQ background jobs + Redis |
| `realtime` | WebSockets / SSE support |

---

## Stack Overview

**Core (adapt per project type):**
- Monorepo: Nx 20 + pnpm 9
- Frontend: React 18 + Vite + TanStack Query v5 + React Hook Form + Zod + Tailwind + Shadcn/ui
- Backend: NestJS 11 + `@anatine/esbuild-decorators`
- Auth: Better Auth 1.4 + `@thallesp/nestjs-better-auth`
- Database: Prisma 7 + PostgreSQL 16 (pgvector when rag is enabled)
- Validation: Zod 3 (single source of truth for all types)
- Testing: **Jest + ts-jest ONLY** (never Vitest — breaks NestJS DI)
- Linting: **Biome 1.9 ONLY** (never ESLint — deprecated)

**Key rule:** Apps are THIN. All business logic lives in `libs/domain/`.

---

## Claude Code Setup

### Context Budget at Session Start

Always-loaded files cost ~47k tokens (~26% of a typical 180k window):

| Files | Approx tokens |
|-------|--------------|
| CLAUDE.md + PROJECT.md | ~5.5k |
| .claude/brain.md | ~1.5k |
| .claude/rules/ (8 files) | ~40k |
| **Total baseline** | **~47k** |

Knowledge files (`.claude/knowledge/`) are NOT always loaded — only when explicitly referenced.

### brain.md vs MEMORY.md

| | `MEMORY.md` | `brain.md` |
|---|---|---|
| Location | Outside repo (auto-managed by Claude) | Inside repo (in `.claude/`) |
| Version controlled | No | Yes |
| Purpose | Claude's private reminders + user prefs | Team-wide gotchas, patterns, decisions |
| Write when | User preference / Claude-specific note | Any new dev would need to know this |

### Auto-Approve Safe Operations

`.claude/settings.json` pre-approves test/lint/build runs and gates destructive ops.
Adjust to your preference.

---

## The Development Workflow

Every feature follows a 5-phase workflow:

```
1. /new-feature [name]        → Create idea document
2. /discuss-feature [name]    → Claude asks questions, identifies entities
3. /plan-feature [name]       → Spec + dev plan (dynamic step count: 2–12)
4. /start-step [name] N       → Implement step by step
   /start-step [name] all     → Or autopilot all steps (auto-commit between each)
5. /complete-feature [name]   → Archive + version bump
   /create-pr                 → GitHub PR
```

**Full details:** `docs/WORKFLOW-GUIDE.md`

### Git Rules

- Planning phases (idea → spec): stay on `main` (just markdown files, safe)
- Implementation: feature branch `feature/F[XXX]-[name]`
- Commit after each step — never batch
- Always push after committing — local data loss is real

---

## Context Window Management

When Claude starts feeling sluggish or forgetting earlier context:

**Mechanical cleanup:**
```bash
bash scripts/trim-context.sh
```
Archives completed features from `active/` → `completed/`, trims STATUS.md session history.

**Intelligent content trimming:**
```
/trim-context
```
Scans brain.md + rules for stale/duplicate content, proposes cuts with before/after sizes,
creates `.claude/context-trim-backup-YYYY-MM-DD/` before applying.

Run both every 2–3 weeks as the project grows.

---

## Environment Variables

`.env.example` is the source of truth. Run the wizard — it handles everything:

```bash
bash scripts/setup-env.sh --env dev        # local development
bash scripts/setup-env.sh --env staging    # staging server
bash scripts/setup-env.sh --env production # production server
```

**Security rules:**
- Never commit any `.env` file
- Generate secrets: `openssl rand -base64 32`
- Never reuse secrets across environments
- `chmod 600` applied automatically

---

## Docker Infrastructure

```bash
docker compose up -d                    # start all services
docker compose down                     # stop all
docker compose ps                       # check status
docker compose logs -f [service]        # view logs
```

Default ports (changed by `/setup-project`):
- PostgreSQL dev: 5442
- PostgreSQL test: 5443
- Redis: 6379

When `rag` integration is enabled, `/setup-project` automatically switches to `pgvector/pgvector:pg16`.

---

## Database Setup

```bash
pnpm nx run database:migrate:dev --name add_user_email   # create + apply migration
pnpm nx run database:generate                            # regenerate Prisma client
pnpm nx run database:studio                              # browser GUI
pnpm nx run database:seed                                # seed dev data
pnpm nx run database:migrate:deploy                      # CI/CD (non-interactive)
```

**Critical:** Use `pnpm nx run database:...` — NOT `prisma` directly. Nx sets the correct CWD.

---

## Biome Linting

```bash
pnpm check                # lint entire workspace
pnpm check:fix            # auto-fix
pnpm format               # format entire workspace
pnpm nx lint [project]    # lint specific project
```

Pre-commit hook runs automatically. If it fails and stashes your changes:
**DO NOT run `git stash drop`** — see `.claude/knowledge/stack-gotchas.md`.

---

## Staging Deployment

**First time (fresh server):**
```bash
bash scripts/staging-setup.sh
```
Installs Node, Docker, PM2, Nginx, Certbot. Sets up SSL + firewall (ports 22/80/443).

**Every deploy:**
```bash
bash scripts/staging-deploy.sh
```

---

## Production Deployment

```bash
bash scripts/production-deploy.sh
```

Safety gates: explicit confirmation, branch check, env validation (no localhost),
migration preview + confirm, 3-retry health check, auto-rollback on failure.

---

## Common Commands Reference

| Command | What it does |
|---------|-------------|
| `/setup-project` | Interactive project configuration wizard (run first!) |
| `/new-feature [name]` | Start a new feature |
| `/discuss-feature [name]` | Discussion phase |
| `/plan-feature [name]` | Generate spec + dev plan |
| `/start-step [name] N` | Implement step N |
| `/start-step [name] all` | Autopilot all remaining steps |
| `/update-status [name]` | Update progress — MANDATORY at end of each session |
| `/resume-feature [name]` | Resume from CONTEXT.md |
| `/complete-feature [name]` | Archive + version bump |
| `/create-pr` | Create GitHub PR |
| `/view-features` | See all features at a glance |
| `/trim-context` | Intelligent context window trimmer |
| `bash scripts/trim-context.sh` | Mechanical cleanup (archive completed features) |
| `bash scripts/dev.sh start` | Start development environment |
| `bash scripts/setup-env.sh` | Set up environment variables |

---

## Gotchas Quick Reference

Full details: `.claude/knowledge/stack-gotchas.md`

| Gotcha | Fix |
|--------|-----|
| NestJS DI injects `undefined` | Never `import type` for services; use `@Inject()` explicitly |
| esbuild strips metadata | `@Inject(Service)` on ALL constructor params |
| Tests break NestJS | Use Jest only — Vitest does not preserve decorator metadata |
| Prisma 7 datasource error | Remove `url = env(...)` from datasource block |
| Prisma commands fail | Use `pnpm nx run database:...` not `prisma` directly |
| Raw SQL wrong column | Columns are camelCase: `"userId"`, not `user_id` |
| lint-staged stash lost | NEVER `git stash drop` after hook failure |
| SPA navigation shows stale data | Use `setQueryData()` alongside `invalidateQueries()` |
| OAuth fails locally | Use ngrok: `bash scripts/start-ngrok.sh` |
