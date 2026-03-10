# Claude Dev Starter Kit

> A development framework for Claude Code — structured workflows, automation, and institutional memory for multi-session projects.

Stop re-explaining your stack to Claude every session. Stop repeating the same mistakes. Stop losing context between sessions. This framework pre-loads Claude with architecture rules, critical gotchas, automated hooks, specialized subagents, and a feature workflow — so every session starts at full speed.

---

## What Problem This Solves

When you start a new project with Claude Code, you spend the first few sessions:
- Re-explaining your stack and architecture rules
- Re-discovering gotchas you already solved in a previous project
- Rebuilding workflow conventions from scratch
- Setting up environment scripts, linting, and pre-commit hooks manually
- Manually formatting code and running generators after every edit

This framework eliminates all of that. It encodes everything needed for Claude to work well across long multi-session projects — tested on a production SaaS application over 30+ features and 100+ sessions.

---

## What's Included

### Structured Workflows
- **Feature workflow** — 6-phase lifecycle: idea → discuss → spec → plan → implement → complete → PR → merge
- **Quick actions** — `/quick`, `/debug`, `/scaffold`, `/review` for tasks that don't need the full workflow
- **Entity hierarchy** — Features, Modules, SubModules, Services for organizing work at different scales
- **Hotfix workflow** — Emergency production bug fixes with patch version bump

### Automation
- **Auto-format** — Biome runs automatically after every file edit (`.ts/.tsx/.js/.jsx`)
- **Prisma generate** — Auto-runs after `schema.prisma` edits
- **Status reminder** — Reminds to run `/update-status` at end of every session
- **Pre-commit hooks** — Husky + lint-staged auto-fix staged files on every commit

### Specialized Subagents
Claude delegates to focused agents with domain-specific context:
- **db-expert** — Prisma schema, migrations, repositories, queries
- **test-writer** — Jest tests, mocks, factories, coverage
- **api-builder** — NestJS controllers, DTOs, modules, guards
- **ui-builder** — React pages, components, forms, TanStack Query hooks

### Institutional Memory
- **`brain.md`** — always-loaded memory (≤200 lines): active work, top gotchas, insights
- **`.claude/knowledge/`** — on-demand files: `stack-gotchas.md`, `patterns.md`, `decisions.md`
- **Feature docs** — `CONTEXT.md` + `STATUS.md` per feature for cross-session continuity

### Smart Setup
- **Interactive wizard** — `/setup-project` configures stack, ports, integrations, and infra in one session
- **Stack comparison** — explains trade-offs when swapping tools (e.g., React+Vite vs Next.js)
- **Post-setup context trim** — automatically removes setup-only content from always-loaded files (~24k tokens saved)
- **Architecture decisions** — records stack choices in `decisions.md` for future reference

### CI/CD & DevOps
- **GitHub Actions CI** — lint, test (with PostgreSQL), build on every PR
- **PR template** — structured PR descriptions with checklists
- **Deploy scripts** — staging and production with safety gates and auto-rollback
- **Environment wizard** — interactive setup for dev/staging/production `.env` files

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
# 1. Clone the template
git clone https://github.com/alonbilu/claude-dev-starter.git my-project-name
cd my-project-name

# 2. Open Claude Code — it detects a fresh clone automatically
claude .
# Claude says: "Run /setup-project to get started"

# 3. Run the setup wizard
# /setup-project
#
# The wizard:
#   - Connects repo to your own GitHub remote
#   - Confirms or customizes your stack (defaults to React + NestJS + Prisma)
#   - Patches all config files automatically
#   - Runs pnpm install, docker compose up, initial migration

# 4. Start your first feature
/new-feature my-first-feature
```

---

## Default Stack

The framework defaults to this production-tested stack. During `/setup-project`, you can swap any tool with a compatibility-checked alternative — the wizard explains trade-offs and warns about what needs manual adjustment.

| Layer | Default | Alternatives |
|-------|---------|-------------|
| Monorepo | Nx 20 + pnpm 9 | — |
| Frontend | React 18 + Vite 6 + Tailwind v3 + Shadcn/ui | Vue, Svelte, Next.js |
| State | TanStack Query v5 + React Hook Form + Zod | SWR, Redux |
| Backend | NestJS 11 + esbuild | Express, Fastify, Hono |
| Auth | Better Auth 1.4 | NextAuth, Clerk, Supabase Auth |
| Database | Prisma 7 + PostgreSQL 16 | Drizzle, TypeORM, Knex |
| Validation | Zod 3 (single source of truth) | — |
| Testing | Jest + ts-jest | (**never Vitest** — breaks NestJS DI) |
| Linting | Biome 1.9 | (**never ESLint**) |

**Why React + Vite + NestJS over Next.js?** The default uses separated frontend/backend apps. This gives you full NestJS power (DI, guards, interceptors, queues, WebSockets) and independent scaling. Next.js is better for content/SEO-heavy sites with simple APIs. The setup wizard explains the full comparison if you consider swapping. See [`decisions.md`](.claude/knowledge/decisions.md) for the detailed architecture decision record.

The rules, gotchas, and patterns are tuned for this stack. If you swap tools, update the rules files to match.

---

## Commands Reference

### Feature Workflow (Main Path)

| Command | Purpose |
|---------|---------|
| `/new-feature [name]` | Start a new feature — capture the idea |
| `/discuss-feature [name]` | Explore approach — Claude asks questions |
| `/plan-feature [name]` | Generate spec + dev plan |
| `/start-coding [name] N` | Implement step N |
| `/start-coding [name] all` | Autopilot — implement all remaining steps |
| `/update-status [name]` | **MANDATORY** — update progress at end of every session |
| `/resume-feature [name]` | Resume from a previous session |
| `/complete-feature [name]` | Archive + version bump |
| `/create-pr` | Create GitHub PR |

### Quick Actions (No Feature Docs)

| Command | Purpose |
|---------|---------|
| `/quick [task]` | Quick fix or small change (5-15 min) |
| `/debug [error]` | Systematic debugging: reproduce → check gotchas → isolate → fix → document |
| `/scaffold [type] [name]` | Scaffold: `endpoint`, `page`, `hook`, `service`, or `domain-lib` |
| `/review` | Pre-PR self-review: lint, tests, code quality checklist |

### Entity Workflows

| Command | Purpose |
|---------|---------|
| `/new-module [name]` | Create a top-level domain module |
| `/new-submodule [parent] [name]` | Add SubModule to a Module |
| `/implement-submodule [parent] [name]` | Implement a SubModule |
| `/new-service [name]` | Create a backend service |
| `/implement-service [name]` | Implement a service |
| `/hotfix` | Start emergency production fix |
| `/complete-hotfix` | Complete hotfix with patch version bump |

### Utilities

| Command | Purpose |
|---------|---------|
| `/view-features` | See all features status |
| `/trim-context` | Clean up context window bloat |
| `/setup-project` | Initial project configuration (run once) |
| `/revise-spec [name]` | Update spec mid-feature |
| `/release-milestone` | Major/minor version bump |
| `/help` or `/?` | Show all commands |

### GitHub (After `/create-pr`)

```bash
gh pr view 42                    # See PR details
gh pr checks 42                  # Check CI status
gh pr review 42 --approve        # Approve
gh pr merge 42 --delete-branch   # Merge + cleanup
```

---

## How the Feature Workflow Works

```
/new-feature user-auth
  → Creates docs/features/active/F001-user-auth/1-idea.md

/discuss-feature user-auth
  → Claude asks questions, proposes approaches
  → Creates 2-discussion.md

/plan-feature user-auth
  → Assesses complexity (XS/S/M/L), generates spec + dev plan
  → Creates 3-spec.md, 4-dev-plan.md, STATUS.md, CONTEXT.md
  → Creates feature branch

/start-coding user-auth 1        # step-by-step
/start-coding user-auth all      # or autopilot

/complete-feature user-auth      # archive + version bump
/create-pr                       # open GitHub PR
gh pr merge 42 --delete-branch   # merge when approved
```

**Step sizing:** XS (2-3 steps), S (3-5), M (5-8), L (8-12) — Claude sizes automatically.

**Session resumption:** `/resume-feature [name]` loads CONTEXT.md + STATUS.md + branch health check (~15-20k tokens).

**Multi-session continuity:** `/update-status` at end of every session is what makes 10+ session features work.

---

## Entity Hierarchy

The framework supports different organizational units for different scales of work:

| Entity | When to Use | Commands |
|--------|-------------|----------|
| **Feature** | User-facing capability (API + UI + DB) | `/new-feature` → `/plan-feature` → `/start-coding` |
| **Module** | Top-level domain area (users, billing, notifications) | `/new-module` → then add SubModules |
| **SubModule** | Feature within a bounded domain | `/new-submodule` → `/implement-submodule` |
| **Service** | Backend-only process (queue worker, webhook, sync) | `/new-service` → `/implement-service` |

**Most projects:** Start with `/new-feature` for everything. Graduate to Modules/SubModules only when you have 5+ features in the same domain.

See [`docs/WORKFLOW-OPTIONS.md`](docs/WORKFLOW-OPTIONS.md) and [`docs/ENTITY-CLASSIFICATION.md`](docs/ENTITY-CLASSIFICATION.md) for detailed decision trees.

---

## Built-In Automation

| Automation | Trigger | What it does |
|-----------|---------|-------------|
| **Auto-format** | Every file edit (`.ts/.tsx/.js/.jsx`) | Runs Biome auto-fix on the changed file |
| **Prisma generate** | Editing `schema.prisma` | Auto-runs `pnpm nx run database:generate` |
| **Status reminder** | End of session | Reminds to run `/update-status` if active feature exists |
| **Pre-commit** | Every `git commit` | Auto-fixes staged files with Biome |

These are configured as Claude Code hooks in `.claude/settings.json` — no manual setup needed.

---

## The 7 Commandments

Encoded in `CLAUDE.md` and enforced by rules files:

1. **Search before creating** — check for existing code before writing anything new
2. **Write for reuse** — build generically, put shared code in `libs/shared/` from day one
3. **Zod is truth** — all types as Zod schemas; same schema for API, forms, seeding
4. **No logic in controllers** — controllers are HTTP plumbing; logic in `libs/domain/`
5. **One mission per session** — complete one step before switching; `/update-status` at end
6. **Never defer type changes** — schema changes propagate to all targets in the same session
7. **Always use `gh` CLI** — GitHub CLI for all GitHub operations

---

## Context Budget

Always-loaded files cost ~47k tokens per session (~26% of a 180k context window):

| Files | Tokens |
|-------|--------|
| CLAUDE.md + PROJECT.md | ~5.5k |
| .claude/brain.md | ~1.5k |
| .claude/rules/ (8 files) | ~40k |
| **Total baseline** | **~47k** |

Commands, knowledge files, and agents are loaded on-demand only — keeping the baseline lean.

**Post-setup trim:** After `/setup-project` completes, the wizard automatically removes setup-only content from always-loaded files (~2k tokens), deletes SETUP.md (~14k tokens), and removes the setup command itself (~8k tokens) — saving ~24k tokens total. This is automatic — no manual work needed.

Run `/trim-context` every few weeks to prevent growth over time.

---

## Repository Structure

```
claude-dev-starter/
├── CLAUDE.md                        ← Claude's session instructions (always loaded)
├── PROJECT.md                       ← Project identity (configure via /setup-project)
│
├── .claude/
│   ├── brain.md                     ← Institutional memory (≤200 lines)
│   ├── settings.json                ← Permissions, hooks, statusline
│   ├── commands/                    ← Workflow commands (on-demand)
│   │   ├── new-feature.md           ← /new-feature
│   │   ├── discuss-feature.md       ← /discuss-feature
│   │   ├── plan-feature.md          ← /plan-feature
│   │   ├── start-coding.md          ← /start-coding
│   │   ├── quick.md                 ← /quick (lightweight tasks)
│   │   ├── debug.md                 ← /debug (systematic debugging)
│   │   ├── scaffold.md              ← /scaffold (boilerplate generation)
│   │   ├── review.md                ← /review (pre-PR self-review)
│   │   ├── new-module.md            ← /new-module (domain modules)
│   │   └── ...                      ← 20+ more commands
│   ├── agents/                      ← Specialized subagents
│   │   ├── db-expert.md             ← Prisma, migrations, queries
│   │   ├── test-writer.md           ← Jest tests, mocks, coverage
│   │   ├── api-builder.md           ← NestJS controllers, DTOs
│   │   └── ui-builder.md            ← React, TanStack Query, forms
│   ├── hooks/                       ← Automation scripts
│   │   ├── biome-format.sh          ← Auto-format after edits
│   │   ├── prisma-generate.sh       ← Auto-generate after schema changes
│   │   └── status-reminder.sh       ← End-of-session reminder
│   ├── knowledge/                   ← On-demand reference (not always loaded)
│   │   ├── stack-gotchas.md         ← Critical pitfalls with fixes
│   │   ├── patterns.md              ← Reusable code patterns
│   │   └── decisions.md             ← Architecture decision log
│   └── rules/                       ← Always loaded (referenced in CLAUDE.md)
│       ├── architecture.md          ← Layering, reuse, import boundaries
│       ├── api.md                   ← NestJS, Better Auth, validation
│       ├── database.md              ← Prisma 7, migrations, gotchas
│       ├── frontend.md              ← React, TanStack Query, forms
│       ├── testing.md               ← Jest setup, coverage requirements
│       ├── code-quality.md          ← Biome, lint-staged, conventions
│       ├── deployment.md            ← Docker, environments, deploy scripts
│       └── ai-workflow.md           ← Feature workflow, brain.md protocol
│
├── .github/
│   ├── workflows/ci.yml             ← CI: lint, test, build on every PR
│   └── pull_request_template.md     ← Structured PR template
│
├── docs/
│   ├── WORKFLOW-GUIDE.md            ← Step-by-step walkthrough
│   ├── WORKFLOW-OPTIONS.md          ← Features vs Services vs Modules
│   ├── ENTITY-CLASSIFICATION.md     ← Entity hierarchy guide
│   ├── GITHUB-WORKFLOW.md           ← PR review & merge operations
│   ├── GITHUB-CLI-REFERENCE.md      ← gh CLI command reference
│   ├── MIGRATION-FROM-EXISTING.md   ← Adopting in existing projects
│   └── templates/feature/           ← Feature document templates
│
├── scripts/
│   ├── setup-env.sh                 ← Env file wizard
│   ├── validate-setup.sh            ← Setup verification
│   ├── dev.sh                       ← Development orchestrator
│   ├── staging-deploy.sh            ← Staging deploy
│   ├── production-deploy.sh         ← Production deploy + rollback
│   └── trim-context.sh              ← Context audit + cleanup
│
├── docker-compose.yml               ← PostgreSQL + Redis
├── biome.json                       ← Linting + formatting
└── .env.example                     ← All env vars documented
```

---

## Critical Gotchas (Top 5)

Full details in `.claude/knowledge/stack-gotchas.md`:

| Gotcha | Fix |
|--------|-----|
| NestJS DI injects `undefined` | Never `import type` for services; always `import { Service }` |
| esbuild strips decorator metadata | Always `@Inject(Service)` on every constructor param |
| NestJS tests fail with Vitest | Use Jest only — Vitest doesn't preserve `emitDecoratorMetadata` |
| Prisma 7 datasource error | Remove `url = env(...)` from datasource block |
| lint-staged stash lost | NEVER `git stash drop` after a failed pre-commit hook |

---

## Adapting to Your Stack

The workflow system (features, brain.md, knowledge/, agents) is stack-agnostic. Only rules files and gotchas are stack-specific.

1. Run `/setup-project` — confirm or swap stack tools during setup
2. Update `.claude/rules/*.md` for your tech choices
3. Replace `.claude/knowledge/stack-gotchas.md` with your stack's gotchas
4. Update `.claude/agents/*.md` for your frameworks
5. See [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) for detailed guidance

---

## Migrating an Existing Project

If you have an existing project:

1. **Read** [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) — 5-phase incremental adoption
2. Copy the files you want, customize rules for your stack
3. Start with the workflow commands (`/new-feature`) and institutional memory (`brain.md`) — adopt the rest gradually

---

## Contributing

Issues and PRs welcome. When contributing:
- Keep `CLAUDE.md` generic — no framework-specific rules that don't apply to all project types
- Add stack-specific gotchas to `.claude/knowledge/stack-gotchas.md`
- Test workflow commands end-to-end before submitting
- Keep `brain.md` under 200 lines
- Maintain zero impact on always-loaded context budget

---

## License

MIT — use freely, no attribution required.
