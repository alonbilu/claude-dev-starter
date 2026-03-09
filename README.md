# Claude Dev Starter Kit

> A project template that makes Claude Code work effectively from session 1 — and keeps it that way.

Stop re-explaining your stack to Claude every session. Stop repeating the same mistakes. Stop losing context between sessions. This template pre-loads Claude with your architecture rules, critical gotchas, a feature workflow, institutional memory, and environment tooling — so every session starts at full speed.

---

## What Problem This Solves

When you start a new project with Claude Code, you spend the first few sessions:
- Re-explaining your stack and architecture rules
- Re-discovering gotchas you already solved in a previous project
- Rebuilding workflow conventions from scratch
- Setting up environment scripts, linting, and pre-commit hooks manually

This template eliminates all of that. It's a starting point that encodes everything needed for Claude to work well across long multi-session projects — tested on a production SaaS application over 30+ features and 100+ sessions.

---

## Features

### 🧠 Institutional Memory System
- **`brain.md`** (≤200 lines, always loaded) — institutional memory: active feature work, top gotchas, project-specific insights
- **`.claude/knowledge/`** — detailed on-demand files: `stack-gotchas.md`, `patterns.md`, `decisions.md` (not loaded every session, keeping the context budget lean)
- A clear protocol for *when* and *how* to update both

### 🔄 Feature Development Workflow
A structured 6-phase workflow that keeps multi-session features on track:

```
/new-feature [name]        → Capture the idea (creates 1-idea.md)
/discuss-feature [name]    → Claude asks questions, proposes approach (creates 2-discussion.md)
/plan-feature [name]       → Spec + atomic dev plan (creates 3-spec.md + 4-dev-plan.md + STATUS.md)
/start-step [name] N       → Implement step N (auto-creates feature branch, updates STATUS.md)
/start-step [name] all     → Autopilot all remaining steps with auto-commits
/complete-feature [name]   → Archive + version bump
/create-pr                 → Open GitHub PR with auto-generated description
```

Each feature gets TWO quick-reference files:
- **`CONTEXT.md`** — 1-page quick-load that resumes any session in ~15k tokens (what you're building, key decisions, next action)
- **`STATUS.md`** — persistent progress tracker across sessions (step completion, session logs, gotchas, blockers)

See [`docs/WORKFLOW-OPTIONS.md`](docs/WORKFLOW-OPTIONS.md) to understand when to use features vs services vs submodules.

### ⚙️ Project Type System
`PROJECT.md` declares what kind of project this is. Claude adapts its rules accordingly.

| Type | Use case |
|------|----------|
| `saas-web-app` | Full-stack: frontend + API + DB + auth |
| `api-only` | Backend API only |
| `fullstack-web` | Frontend + API (no billing layer) |
| `cli` | Command-line tool |
| `library` | Reusable package or SDK |
| `static-site` | Static frontend only |

Optional integrations (off by default): `payments` · `email` · `storage` · `llm` · `rag` · `queue` · `realtime`

### 🧙 `/setup-project` Interactive Wizard
Run once after cloning. Validates Node/pnpm/Docker, asks about your project type, infrastructure choices, and ports — then:
- Validates pre-flight requirements (Node 20+, pnpm 9+, git, Docker) with helpful errors
- Connects repo to your own GitHub remote
- Populates `PROJECT.md`
- Updates `docker-compose.yml` (ports, container names, pgvector if rag enabled)
- Updates `.env.example`, `main.ts`, `vite.config.ts`, scripts
- Offers to run `pnpm install`, `docker compose up`, and initial migrations with your permission
- **At the end**, asks if you want to archive/delete `SETUP.md` (saves ~14k context tokens)
- Auto-deletes the `setup-project.md` command file so it won't be needed again

### 🔍 The Two Reuse Rules (Encoded in Rules Files)
Claude is instructed to follow two non-negotiable rules:
1. **Search before creating** — always searches for existing code before writing new code
2. **Write for reuse from day one** — builds generically, puts shared code in `libs/shared/`

### 🔐 Environment Setup Wizard
`scripts/setup-env.sh --env dev|staging|production` walks through every env var:
- Prompts one at a time with current value shown
- Type `generate` for any secret → `openssl rand -base64 32` auto-runs
- Validates required fields, warns on `localhost` in production
- Enforces `chmod 600`, refuses weak production secrets

### 🚀 Deploy Scripts with Safety Gates
`scripts/production-deploy.sh` enforces:
- Explicit `deploy` confirmation
- Clean `main` branch check
- No `localhost` in `.env.production`
- Migration preview + confirmation
- 3-retry health check with **auto-rollback** on failure

### 🪟 Context Window Management
Two-tier cleanup system:
- **`bash scripts/trim-context.sh`** — mechanical: archives completed features, trims STATUS.md session logs, warns when `brain.md` exceeds 200 lines
- **`/trim-context`** (Claude command) — intelligent: scans for stale brain.md sections, duplicate rules, inactive integration rules — proposes cuts with before/after sizes, backs up before applying

### 🧹 Biome + Pre-Commit Hook
- `biome.json` — battle-tested config with NestJS decorator support
- Husky + lint-staged wired up — auto-fixes staged files on every commit
- Never ESLint, never Prettier — Biome does both

---

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 20+ |
| pnpm | 9+ |
| Docker | Latest |
| Claude Code CLI | Latest |
| gh CLI | Latest (optional, for `/create-pr`) |

**On Ubuntu 22.04+?** Install everything with one command:
```bash
bash scripts/install-prerequisites-ubuntu.sh
```

### 4 Steps

```bash
# 1. Clone the template — replace "my-project-name" with your actual project name
git clone https://github.com/alonbilu/claude-dev-starter.git my-project-name
cd my-project-name

# 2. Open Claude Code — it will detect a fresh clone and prompt you automatically
claude .
# Claude will say: "Run /setup-project to get started"

# 3. Run the setup wizard
# /setup-project
#
# The wizard handles everything:
#   - Connects repo to your own GitHub remote (replaces the template remote)
#   - Asks project type, infrastructure, ports
#   - Patches all config files automatically
#   - Runs pnpm install, docker compose up, initial migration (with permission)

# 4. Verify setup (optional but recommended)
bash scripts/validate-setup.sh

# 5. Start your first feature
/new-feature my-first-feature
```

**After `/setup-project` completes**, the wizard will optionally archive `SETUP.md` (saves ~14k context tokens) and delete `setup-project.md` (won't need it again).

---

## Stack

This template is opinionated about the following stack (the defaults you get out of the box):

| Layer | Technology |
|-------|-----------|
| Monorepo | Nx 20 + pnpm 9 |
| Frontend | React 18 + Vite 6 + TanStack Query v5 + React Hook Form + Zod + Tailwind v3 + Shadcn/ui |
| Backend | NestJS 11 + esbuild (`@anatine/esbuild-decorators`) |
| Auth | Better Auth 1.4 + `@thallesp/nestjs-better-auth` |
| Database | Prisma 7 + PostgreSQL 16 |
| Validation | Zod 3 (single source of truth — same schema for API, forms, seeding) |
| Testing | Jest + ts-jest (**never Vitest** — breaks NestJS DI) |
| Linting | Biome 1.9 (**never ESLint** — deprecated in this stack) |

The rules, gotchas, and patterns in this template are tuned for this stack. If you use a different stack (e.g. Express instead of NestJS, Drizzle instead of Prisma), the workflow system still applies — update the rules files to match your stack.

---

## Repository Structure

```
claude-dev-starter/
├── SETUP.md                     ← Detailed setup guide
├── PROJECT.md                   ← Project identity card (configure via /setup-project)
├── CLAUDE.md                    ← Claude's session instructions (always loaded)
│
├── .claude/
│   ├── brain.md                 ← Institutional memory (≤200 lines, always loaded)
│   ├── settings.json            ← Auto-approve safe ops; gate destructive ones
│   ├── commands/
│   │   ├── setup-project.md     ← /setup-project wizard
│   │   └── trim-context.md      ← /trim-context intelligent cleanup
│   ├── knowledge/               ← On-demand — NOT loaded every session
│   │   ├── stack-gotchas.md     ← Critical pitfalls with fixes
│   │   ├── patterns.md          ← Reusable backend + frontend patterns
│   │   └── decisions.md         ← Architecture decision log template
│   └── rules/                   ← Loaded every session (referenced in CLAUDE.md)
│       ├── architecture.md      ← Layering, reuse rules, import boundaries
│       ├── api.md               ← NestJS, Better Auth, validation
│       ├── database.md          ← Prisma 7, migrations, camelCase column gotcha
│       ├── frontend.md          ← React, TanStack Query v5, forms
│       ├── testing.md           ← Jest setup, patterns, coverage requirements
│       ├── code-quality.md      ← Biome, lint-staged, suppression rules
│       ├── deployment.md        ← Docker, env files, deploy scripts
│       └── ai-workflow.md       ← Session protocol, feature workflow, brain.md protocol
│
├── docs/
│   ├── WORKFLOW-GUIDE.md           ← Step-by-step feature workflow walkthrough
│   ├── WORKFLOW-OPTIONS.md         ← When to use /new-feature vs /new-service vs /new-submodule
│   ├── MIGRATION-FROM-EXISTING.md  ← How to adopt this template in existing projects
│   ├── FEATURE-STATUS.md           ← Central feature tracking dashboard
│   ├── ENTITY-CLASSIFICATION.md    ← When to create modules/services/processors
│   ├── templates/
│   │   └── feature/
│   │       ├── 1-idea.md           ← Feature idea template (what + why)
│   │       ├── 2-discussion.md     ← Discussion template (questions + approach)
│   │       ├── 3-spec.md           ← Specification template (full technical spec)
│   │       ├── 4-dev-plan.md       ← Development plan template (atomic steps)
│   │       ├── STATUS.md           ← Progress & session log template
│   │       └── CONTEXT.md          ← 1-page quick-load template for session resumption
│   └── features/
│       ├── active/                 ← Work in progress
│       ├── completed/              ← Archived features
│       └── backlog/                ← Future ideas
│
├── docker-compose.yml           ← PostgreSQL (dev + test) + Redis
├── biome.json                   ← Linting + formatting config
├── package.json.template.md     ← Dependency reference for new workspaces
├── .env.example                 ← All env vars documented (committed, no secrets)
├── .vscode/                     ← Format-on-save, recommended extensions
├── .husky/pre-commit            ← Runs Biome on staged files
│
└── scripts/
    ├── setup-env.sh             ← Env wizard (dev/staging/production)
    ├── validate-setup.sh        ← Verify setup is complete: Node, Docker, builds, tests, etc.
    ├── dev.sh                   ← Development environment orchestrator
    ├── start-db.sh              ← Quick DB-only startup
    ├── start-ngrok.sh           ← ngrok tunnel for OAuth/webhook testing
    ├── staging-setup.sh         ← One-time server bootstrap (Ubuntu 22+)
    ├── staging-deploy.sh        ← Incremental staging deploy
    ├── production-deploy.sh     ← Production deploy with safety gates + rollback
    └── trim-context.sh          ← Context window audit + mechanical cleanup
```

---

## The 7 Commandments

These are encoded in `CLAUDE.md` and enforced by the rules files. Claude follows these on every session.

1. **Search before creating** — check for existing code before writing anything new
2. **Write for reuse** — build generically, put shared code in `libs/shared/` from day one
3. **Zod is truth** — all types defined as Zod schemas in `libs/shared/types/`; same schema for API, forms, seeding
4. **No logic in controllers** — controllers and pages are HTTP/routing only; ALL business logic in `libs/domain/`
5. **One mission per session** — complete one feature step fully before switching; run `/update-status` at end of every session
6. **Never defer type changes** — when a Zod schema changes, update ALL propagation targets (migrations, DTOs, forms, tests) in the same session
7. **Always use `gh` CLI** — use GitHub CLI for all GitHub operations (repos, PRs, issues, releases)

---

## Context Budget

Always-loaded files cost ~47k tokens per session (~26% of a typical 180k context window):

| Files | Tokens |
|-------|--------|
| CLAUDE.md + PROJECT.md | ~5.5k |
| .claude/brain.md | ~1.5k |
| .claude/rules/ (8 files) | ~40k |
| **Total baseline** | **~47k** |

Knowledge files (`.claude/knowledge/`) are NOT always loaded — only when explicitly referenced. This keeps the baseline lean so the rest of the window is available for actual code.

Run `/trim-context` every few weeks to keep this number from growing as the project accumulates history.

---

## Critical Gotchas (The Top 5)

Full details in `.claude/knowledge/stack-gotchas.md`. The most important:

| Gotcha | Fix |
|--------|-----|
| NestJS DI injects `undefined` | Never `import type` for services; always `import { Service }` |
| esbuild strips decorator metadata | Always `@Inject(Service)` on every constructor param — explicitly |
| NestJS tests fail with Vitest | Use Jest only — Vitest's esbuild doesn't preserve `emitDecoratorMetadata` |
| Prisma 7 datasource error | Remove `url = env(...)` from datasource block — Prisma 7 reads it automatically |
| lint-staged stash lost | NEVER `git stash drop` after a failed pre-commit hook |

---

## How the Feature Workflow Works

```
docs/features/
└── active/
    └── F001-user-auth/
        ├── 1-idea.md      ← you write this
        ├── 2-discussion.md ← Claude fills during /discuss-feature
        ├── 3-spec.md       ← Claude generates during /plan-feature
        ├── 4-dev-plan.md   ← atomic steps with token budgets
        ├── STATUS.md       ← updated every session (the "cursor")
        └── CONTEXT.md      ← 1-page quick-load for /resume-feature
```

**Step sizing:** Claude assesses complexity (XS/S/M/L) and sizes steps accordingly:
- XS: 2–3 steps (~60k tokens/step budget)
- S: 3–5 steps
- M: 5–8 steps (new lib or schema change)
- L: 8–12 steps (multiple new libs or major feature)

**Session resumption:** `/resume-feature [name]` loads CONTEXT.md + STATUS.md — enough to pick up exactly where you left off, in ~15–20k tokens.

**Multi-session continuity:** `/update-status [name]` is mandatory at the end of every session. This is what makes features that span 10+ sessions work without losing context.

---

## Workflow Options

This template supports **three development workflows**. Most projects use `/new-feature`:

| Workflow | Use When | Commands |
|----------|----------|----------|
| **Feature** (default) | Building user-facing capabilities, API endpoints, UI flows | `/new-feature`, `/discuss-feature`, `/plan-feature`, `/start-step` |
| **Service** | Backend-only: queues, webhooks, sync services, background jobs | `/new-service`, `/implement-service` |
| **SubModule** | Features within a bounded domain (advanced: requires module structure) | `/new-submodule`, `/implement-submodule` |

**Most projects:** Start with `/new-feature` for everything. See [`docs/WORKFLOW-OPTIONS.md`](docs/WORKFLOW-OPTIONS.md) for detailed decision tree and when to graduate to Services or SubModules.

---

## Migrating an Existing Project

If you have an existing project and want to adopt this template:

1. **Read** [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) — 5-phase incremental adoption strategy
2. **Key point:** You don't have to adopt everything at once. Copy files you want, customize rules for your stack, migrate at your pace.
3. **Stack customization:** Update `.claude/rules/*.md` to match your tech choices (Express, Drizzle, Vue, etc.)

---

## Adapting to Your Stack

The workflow system (features, brain.md, knowledge/, CONTEXT.md) is stack-agnostic. Only the rules files and gotchas are stack-specific.

If you use a different stack:
1. Run `/setup-project` and select your project type
2. Update `.claude/rules/*.md` to reflect your tech choices
3. Replace `.claude/knowledge/stack-gotchas.md` with gotchas relevant to your stack
4. Update `CLAUDE.md` stack overview section
5. Update `package.json.template.md` with your dependencies
6. Refer to [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) for detailed customization guidance
6. Update `docker-compose.yml` for your infrastructure

---

## Contributing

Issues and PRs welcome. This template improves over time as new patterns and gotchas are discovered.

When contributing:
- Keep `CLAUDE.md` generic — no framework-specific rules that don't apply to all project types
- Add stack-specific gotchas to `.claude/knowledge/stack-gotchas.md` with the technology clearly labeled
- Test workflow commands end-to-end before submitting
- Keep `brain.md` under 200 lines

---

## License

MIT — use freely, no attribution required.
