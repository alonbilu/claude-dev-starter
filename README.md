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
A structured 5-phase workflow that keeps multi-session features on track:

```
/new-feature [name]        → Capture the idea
/discuss-feature [name]    → Claude asks questions, proposes approach
/plan-feature [name]       → Spec + atomic dev plan (2–12 steps, complexity-scaled)
/start-step [name] N       → Implement step N
/start-step [name] all     → Autopilot all remaining steps with auto-commits
/complete-feature [name]   → Archive + version bump
```

Each feature gets a `CONTEXT.md` — a 1-page quick-load file that resumes any session in ~15k tokens without re-reading the entire history.

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
Run once after cloning. Asks about your project type, infrastructure choices, and ports — then:
- Populates `PROJECT.md`
- Updates `docker-compose.yml` (ports, container names, pgvector if rag enabled)
- Updates `.env.example`, `main.ts`, `vite.config.ts`, scripts
- Offers to run `pnpm install`, `docker compose up`, and initial migrations with your permission

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

### 7 Steps

```bash
# 1. Clone and point to your own repo
git clone https://github.com/alon-codes/claude-dev-starter my-project
cd my-project
git remote remove origin
git remote add origin https://github.com/YOUR_ORG/my-project.git

# 2. Open Claude Code and run the setup wizard
claude .
# Then in Claude: /setup-project

# 3. Set up dev environment secrets
bash scripts/setup-env.sh --env dev

# 4. Start infrastructure
docker compose up -d

# 5. Install dependencies + init database
pnpm install
pnpm nx run database:migrate:dev --name init

# 6. Start developing
pnpm nx serve api      # → http://localhost:3333
pnpm nx serve client   # → http://localhost:4200

# 7. Start your first feature
# In Claude: /new-feature my-first-feature
```

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
│   ├── WORKFLOW-GUIDE.md        ← Step-by-step feature workflow walkthrough
│   ├── FEATURE-STATUS.md        ← Central feature tracking dashboard
│   ├── ENTITY-CLASSIFICATION.md ← When to create modules/services/processors
│   └── features/
│       ├── active/              ← Work in progress
│       ├── completed/           ← Archived features
│       └── backlog/             ← Future ideas
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
    ├── dev.sh                   ← Development environment orchestrator
    ├── start-db.sh              ← Quick DB-only startup
    ├── start-ngrok.sh           ← ngrok tunnel for OAuth/webhook testing
    ├── staging-setup.sh         ← One-time server bootstrap (Ubuntu 22+)
    ├── staging-deploy.sh        ← Incremental staging deploy
    ├── production-deploy.sh     ← Production deploy with safety gates + rollback
    └── trim-context.sh          ← Context window audit + mechanical cleanup
```

---

## The 6 Commandments

These are encoded in `CLAUDE.md` and enforced by the rules files. Claude follows these on every session.

1. **Search before creating** — check for existing code before writing anything new
2. **Write for reuse** — build generically, put shared code in `libs/shared/` from day one
3. **Zod is truth** — all types defined as Zod schemas in `libs/shared/types/`; same schema for API, forms, seeding
4. **Apps are thin** — controllers and pages are routing only; ALL business logic in `libs/domain/`
5. **One mission per session** — complete one feature step fully before switching; run `/update-status` at end of every session
6. **No raw SQL** — use Prisma for all DB access; complex queries go to repositories

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

## Adapting to Your Stack

The workflow system (features, brain.md, knowledge/, CONTEXT.md) is stack-agnostic. Only the rules files and gotchas are stack-specific.

If you use a different stack:
1. Run `/setup-project` and select your project type
2. Update `.claude/rules/*.md` to reflect your tech choices
3. Replace `.claude/knowledge/stack-gotchas.md` with gotchas relevant to your stack
4. Update `CLAUDE.md` stack overview section
5. Update `package.json.template.md` with your dependencies
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
