# Claude Code Instructions

---

## FIRST: Check for First-Time Setup

Read `PROJECT.md`. If `YOUR_APP_NAME` still appears anywhere in the file, or if the project type
hasn't been customized yet, **immediately say:**

```
Welcome! This looks like a freshly cloned Claude Dev Starter Kit.

Here's what you have:
  - A feature-driven development workflow with spec-first planning
  - Pre-configured Biome linting + pre-commit hooks
  - Smart context window management (brain.md + /trim-context)
  - Interactive project setup that configures everything for your stack

Run /setup-project to get started. It will:
  1. Connect this repo to your own GitHub remote (replacing the template remote)
  2. Ask about your project type, infrastructure, and ports
  3. Configure all files automatically for your stack
```

Then wait for the user to run `/setup-project` before doing anything else.

---

## Read at Start of EVERY Session

1. **This file** (you're reading it)
2. **`PROJECT.md`** — project type, active layers, integrations, ports
3. **`.claude/brain.md`** — institutional memory, active feature, recent gotchas

---

## Stack Overview

> Populated by `/setup-project`. Until then, these are template defaults.

- **Monorepo:** Nx + pnpm
- **Frontend:** React + Vite + TanStack Query v5 + React Hook Form + Zod + Tailwind + Shadcn/ui
- **Backend:** NestJS + BullMQ (if queue enabled)
- **Auth:** Better Auth + `@thallesp/nestjs-better-auth`
- **Database:** Prisma + PostgreSQL (pgvector if rag enabled)
- **Validation:** Zod (single source of truth)
- **Testing:** Jest ONLY (never Vitest)
- **Linting:** Biome ONLY (never ESLint)
- **API port:** 3333 | **Client port:** 4200

---

## The 6 Commandments

### 1. Search Before Creating 🔍
**Before writing ANY new code**, search for existing implementations:
```bash
grep -r "functionName" libs/    # search for existing code
ls libs/shared/ libs/domain/    # browse existing libs
pnpm nx graph                   # visualize the full dependency graph
```
**Code duplication is a defect.** If you're about to write something that looks like existing code,
stop and find the original. The second occurrence should be an import, not a copy.

### 2. Write for Reuse 🔄
When creating any new component, service, or utility — **build it generically from the start.**
Ask: could another feature use this? If yes, put it in `libs/shared/` immediately.
- UI components → `libs/shared/ui/`
- Pure utilities → `libs/shared/utils/`
- Types/schemas → `libs/shared/types/`
- NestJS modules → `libs/backend/core/`

### 3. Zod is Truth 📜
ALL types live in `libs/shared/types/` as Zod schemas. TypeScript types are inferred with `z.infer<>`.
The same schema validates API input, frontend forms, and DB seeds. **Never duplicate type definitions.**

### 4. No Logic in Controllers ⚖️
Controllers are HTTP plumbing only. Delegate all logic immediately to domain services:
```typescript
@Post()
create(@Body() dto: CreateDto) {
  return this.service.create(dto);  // that's it — nothing else.
}
```

### 5. One Mission Per Session 🎯
Complete ONE feature step before switching tasks. If a refactor is tempting, finish the current
task first, then ask. Never let scope creep sneak in.

### 6. Never Defer Type Changes ⚡
When a Zod schema changes, update all propagation targets (schema, migration, DTOs, services,
forms, seeds, tests) **in the same session**. Type drift across sessions causes subtle bugs.

---

## Import Rules

```
✅ apps/* → libs/*
✅ libs/domain/* → libs/shared/*
✅ libs/backend/* → libs/domain/* or libs/shared/*
❌ libs/* → apps/*           (forbidden)
❌ libs/shared/* → libs/domain/* (forbidden)

NEVER use `import type` for NestJS injectable services — erased at compile time, DI breaks.
ALWAYS use explicit @Inject(Service) in constructor params — esbuild strips metadata.
```

---

## Library Map

```
apps/
├── client/          # React app (THIN — no business logic)
├── api/             # NestJS app (THIN — no business logic)
└── gateway/         # Nginx (optional)

libs/
├── shared/          # Foundation — reusable, no business logic
│   ├── types/       # Zod schemas (SOURCE OF TRUTH for all types)
│   ├── ui/          # Shared UI components
│   ├── auth/        # Auth config
│   ├── config/      # Env validation
│   └── utils/       # Pure utility functions
├── domain/          # Business Logic Layer
│   ├── database/    # Prisma client + repositories
│   └── [feature]/   # One lib per domain
└── backend/         # NestJS-specific
    ├── core/        # Guards, interceptors, filters
    ├── auth/        # Auth integration
    └── email/       # Email templates + sending
```

---

## Quick Commands

```bash
# Infrastructure
docker compose up -d              # start PostgreSQL + Redis
docker compose down               # stop

# Apps (run locally, not in Docker)
pnpm nx serve api                 # NestJS: http://localhost:3333
pnpm nx serve client              # React: http://localhost:4200

# Database
pnpm nx run database:migrate:dev --name [name]
pnpm nx run database:generate
pnpm nx run database:seed
pnpm nx run database:studio

# Generate libs
pnpm nx g @nx/js:library [name] --directory=libs/domain/[name]
# IMPORTANT: After generating, remove the "build" target from project.json

# Test & Lint
pnpm nx test [project]
pnpm nx lint [project]
pnpm nx affected -t test
pnpm nx affected -t build
pnpm check:fix                    # Biome fix entire workspace
```

---

## Feature Workflow Commands

```bash
/new-feature [name]          # Start: create idea document
/discuss-feature [name]      # Discussion: Claude asks questions, identifies entities
/plan-feature [name]         # Spec + dev plan
/start-step [name] N         # Implement step N
/start-step [name] all       # Autopilot: all steps, auto-commit between each
/update-status [name]        # MANDATORY: end of every session
/resume-feature [name]       # Resume: loads CONTEXT.md + STATUS.md (~15k tokens)
/complete-feature [name]     # Archive + version bump
/create-pr                   # Create GitHub PR
/view-features               # See all features status
/trim-context                # Reduce context window bloat
/setup-project               # Interactive project configuration wizard
```

---

## Code Location Cheat Sheet

| What | Where |
|------|-------|
| Zod Schema | `libs/shared/types/src/lib/[name].schema.ts` |
| Business Logic | `libs/domain/[feature]/src/lib/[name].service.ts` |
| Database Query | `libs/domain/database/src/lib/repositories/` |
| API Controller | `apps/api/src/app/[feature]/[name].controller.ts` |
| API DTO | `apps/api/src/app/[feature]/dto/` |
| React Page | `apps/client/src/pages/` |
| Reusable UI Component | `libs/shared/ui/src/lib/components/` |
| NestJS Guard | `libs/backend/core/src/lib/guards/` |
| Email Template | `libs/backend/email/src/lib/templates/` |
| Background Job Processor | `libs/domain/[feature]/src/lib/processors/` |

---

## Detailed Rules

- **Architecture:** `.claude/rules/architecture.md` — layering, import rules, reuse commandments
- **Database:** `.claude/rules/database.md` — Prisma, migrations, gotchas
- **API:** `.claude/rules/api.md` — NestJS, Better Auth, validation
- **Frontend:** `.claude/rules/frontend.md` — React, TanStack Query, forms, Shadcn
- **Testing:** `.claude/rules/testing.md` — Jest setup, patterns, coverage requirements
- **Code Quality:** `.claude/rules/code-quality.md` — Biome, lint-staged, conventions
- **Deployment:** `.claude/rules/deployment.md` — Docker, environments, deploy scripts
- **AI Workflow:** `.claude/rules/ai-workflow.md` — Feature workflow, brain.md protocol

## Knowledge Base (Load On Demand)

- `.claude/knowledge/stack-gotchas.md` — Critical gotchas (DI, Prisma, testing, Biome, Zod)
- `.claude/knowledge/patterns.md` — Reusable code patterns (backend + frontend)
- `.claude/knowledge/decisions.md` — Architecture decisions log

---

**Remember:** Apps are THIN. Logic lives in `libs/domain/`. Zod is truth.
Search before creating. Write for reuse. Update brain.md when you learn something worth keeping.
