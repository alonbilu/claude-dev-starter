# Architecture Decisions Log

This file is the project's **Architecture Decision Records** (ADRs) log — a short,
chronological list of significant technical choices the team has made.

## What is an ADR?

An **Architecture Decision Record** captures one significant technical choice, **why** it was
made, what alternatives were ruled out, and what changes as a result. It's how future
contributors (and future-you) understand *why* the codebase looks the way it does without
reconstructing it from git history or guessing at the original tradeoffs.

A good ADR:

- Is **scoped to one decision** — not a feature spec, not a code design doc
- Captures the **alternatives ruled out** and the reason
- Is **dated**, **numbered** (ADR-001, ADR-002, …), and has a **status**
  (`proposed` / `accepted` / `superseded` / `deprecated`)
- Is **immutable** once accepted — if the decision changes, add a new ADR that **supersedes**
  the old one rather than rewriting history

If you're tempted to write a long PR description justifying a stack choice — that PR
description IS an ADR. Put it here and link from the PR.

**Scaffold a new ADR with the `/new-adr [title]` command** — it auto-increments the number,
stamps today's date, and inserts the template with `Status: proposed`.

Format: `context → decision → rationale → consequences`.

---

## Template

```markdown
## ADR-[N]: [Decision Title]
**Date:** YYYY-MM-DD
**Status:** accepted | superseded | deprecated

### Context
What situation led to this decision?

### Decision
What was decided?

### Rationale
Why this option over alternatives?

### Consequences
What changes as a result? Any trade-offs?
```

---

## ADR-001: Example — Use Zod as single source of truth for types
**Date:** (fill in)
**Status:** accepted

### Context
Need shared types between frontend, backend, and database layer without duplication.

### Decision
All types defined as Zod schemas in `libs/shared/types`. TypeScript types inferred with `z.infer<>`.
Same schema used for: API validation, form validation, DB seeding.

### Rationale
- One schema change propagates everywhere at compile time
- Runtime validation at API boundary for free
- No manual interface maintenance

### Consequences
- Must update types in one session when schema changes (never defer)
- Prisma types are NOT used directly — always re-mapped through Zod schemas
- Heavier `libs/shared/types` but simpler everything else

---

## ADR-002: Frontend architecture — React + Vite vs Next.js vs Both

**Date:** 2026-03-10
**Status:** accepted

### Context
When setting up a new project, users need to choose between three frontend architectures:
1. React + Vite (separate SPA) + NestJS backend
2. Next.js only (replaces both frontend and backend)
3. Next.js (frontend) + NestJS (backend) — both together

### Decision
Default to **React + Vite + NestJS** (separated architecture). Recommend alternatives only for specific use cases.

### Rationale

**Option 1: React + Vite + NestJS (DEFAULT — recommended for most projects)**
- Clean separation — each app has one job
- NestJS gives full backend power: DI, guards, interceptors, queues, WebSockets, module system
- Independent deploy & scaling (static CDN for frontend, autoscaled API)
- Simpler mental model — frontend calls API, that's it
- Vite dev server is extremely fast
- Drawbacks: no SSR (bad for SEO-heavy public pages), CORS config needed, two servers in dev

**Option 2: Next.js only (replaces both React+Vite AND NestJS)**
- SSR/SSG/ISR for SEO out of the box
- One deploy (Vercel makes this trivial)
- API routes co-located with pages, less boilerplate for simple APIs
- Drawbacks: API routes are thin functions — no DI, guards, interceptors, or module system. Background jobs need a separate service. Coupled scaling. For SaaS with complex business logic, you end up reinventing NestJS patterns poorly.

**Option 3: Next.js + NestJS + Prisma (both)**
- SSR/SSG for public pages (landing, blog, docs, pricing) with full NestJS backend power
- Best of both for SaaS: marketing pages are SSR, app pages are SPA-like
- Auth can use Next.js middleware for route protection on the frontend
- Drawbacks: three moving parts instead of two, redundant API layer (Next.js API routes unused or used as BFF proxy adding a hop), two Node.js runtimes in production, Prisma shared between two servers, can't just "deploy to Vercel," overkill for most projects

### When to recommend each

| Use case | Recommendation |
|----------|---------------|
| SaaS behind auth (dashboard, CRUD, billing) | **Option 1** — logged-in pages don't need SSR/SEO |
| Content platform / marketplace (public pages ARE the product) | **Option 2 or 3** — SSR matters for SEO |
| Landing/docs site only | **Option 2** — Next.js alone, no complex backend needed |
| Complex backend (queues, WebSockets, multi-tenant) + SEO pages | **Option 3** — but consider if a separate static marketing site is simpler |
| B2B API + embeddable widget/whitelabel | **Option 1** — separated architecture, widget as embeddable JS bundle |

### Consequences
- Template rules, agents, hooks, and gotchas are tuned for Option 1
- Choosing Option 2 or 3 requires manual updates to rules files, agents, and hooks
- `/setup-project` wizard explains trade-offs during stack confirmation step (including B2B whitelabel guidance)
- B2B whitelabel architectural guidance lives in `setup-project.md` — deleted after setup to save context

---

## ADR-003: Tier-aware command behavior (Opus 1M vs Sonnet 200k)

**Date:** 2026-04-12
**Status:** accepted

### Context
Anthropic offers Claude Opus 4.6 with an optional 1M-token context window, while Sonnet stays at 200k. Users often switch between them based on task complexity and cost. A workflow kit that hard-codes one context size either wastes Opus capacity or breaks on Sonnet.

### Decision
Commands that load context (currently `/resume-feature` and `/trim-context`) detect the running model tier and branch behavior:

- **Opus 1M** — model ID contains `1m`: eager loading (full feature directories, 1M budget thresholds).
- **Sonnet 200k (or Opus non-1M)**: lean loading (CONTEXT.md + STATUS.md only, 200k budget thresholds).

Default baseline (always-loaded files: CLAUDE.md + brain.md + rules/) stays ≤~60k tokens so Sonnet sessions start comfortable.

If model-ID detection is ambiguous, commands consult `PROJECT.md` → `claude.max_plan`:
- `x20` → Opus 1M behavior
- `x5` → Sonnet-safe behavior (lean)
- `legacy` / unset → Sonnet-safe

`/setup-project` asks for `max_plan` once during initial configuration.

### Rationale
- Works on both tiers without user configuration per session
- Opus 1M unlocks power-user behavior automatically when available
- Encourages designing for 200k as the floor so nobody gets stuck
- Single source of truth (`claude.max_plan`) avoids per-session declarations

### Consequences
- Affected commands include tier-aware branches in their instructions (see `.claude/commands/resume-feature.md`, `.claude/commands/trim-context.md`)
- `.claude/rules/ai-workflow.md` documents the pattern in its "Tier Awareness" section
- Adding new commands that load context should consider whether they benefit from tier-aware behavior

---

## ADR-004: Optional codebase-map knowledge pattern

**Date:** 2026-04-12
**Status:** accepted

### Context
Once a project crosses ~20 files, Claude spends a lot of tool calls grepping for file paths that a short structural reference could provide instantly. An always-loaded file catalog pays for itself quickly in saved tool calls.

### Decision
Ship a `.claude/knowledge/codebase-map.md.template` — a structural stub users can fill in when their project outgrows "read everything when asked." Rename to `codebase-map.md` and reference it from `CLAUDE.md` to make it always-loaded.

Content target: ≤8k tokens. File tree (top 2 levels), key services/libs, API endpoints, DB models, frontend routes (if applicable), i18n namespaces (if applicable), quick commands.

### Rationale
- Pays back in fewer `grep -r` and `ls` calls per session
- Opt-in (not always generated) — small projects don't need it
- Projects fill it in when real structure exists, not against the template

### Consequences
- New projects default to NOT having `codebase-map.md` — they rename the template when ready
- Tier-aware commands may still grep/explore beyond what the map lists; the map is a starting point
- When the map drifts from reality, `/trim-context` will flag it for refresh

---

## ADR-005: TanStack Router as the default frontend router

**Date:** 2026-05-17
**Status:** accepted

### Context

The kit shipped with TanStack Query for server state but no documented router. Real projects
ended up adopting either React Router (string-typed routes, manual search-param handling) or
TanStack Router (file-based, typed search params). Filter-heavy UIs (catalog/search/admin
listings) hit the search-param-typing pain repeatedly.

### Decision

Default the frontend stack to **TanStack Router**. Routes live in `apps/client/src/routes/`
(file-based). Search params are validated with Zod schemas from `libs/shared/types/`. The
generated `routeTree.gen.ts` is never edited by hand.

### Rationale

- **Typed search params eliminate a class of refactor bugs.** Renaming a route param or
  search key fails at compile time at every call site, not at runtime in a forgotten flow.
- **Loaders pair naturally with TanStack Query** — start the fetch on navigation, keep
  `useQuery` as the read path. No third state library needed.
- **Scaling note we explicitly checked:** route-tree size scales with the app's structure,
  not with tenant count. Storefront/admin in the 30-80 route range performs comfortably; the
  "hundreds of routes" caveat doesn't apply here.
- Ruled out: React Router (string-typed routes), TanStack Start (overlaps with the existing
  Vite + NestJS split).

### Consequences

- `frontend.md` documents file-based routing + typed search params + loader/query interplay.
- `apps/client/src/pages/` is renamed to `apps/client/src/routes/` across the kit's docs.
- `/setup-project` confirms TanStack Router during stack-confirmation; users can still swap
  to React Router (will require rewriting `frontend.md`).

---

## ADR-006: Pluggable auth provider — Better Auth (default) + Zitadel + Hydra

**Date:** 2026-05-17
**Status:** accepted

### Context

Better Auth was hardcoded as the auth provider. Real downstream projects sometimes need a
full external OIDC identity provider (Zitadel) — enterprise SSO, org/role models, Management
API for backend-side user queries. Separately, machine-to-machine tokens (third-party API
clients, service-to-service, webhook callers) are a different problem entirely — not a human
login.

### Decision

- Make the app auth provider **pluggable** via `PROJECT.md` → `auth_provider`:
  `better-auth` (default) or `zitadel`. Pick one.
- Add `hydra` as a separate opt-in **integration** (not a provider swap) for M2M auth.
  Coexists with Better Auth or Zitadel — they handle different traffic.
- Provider-specific setup + gotchas live in `.claude/knowledge/integrations.md`. The rules
  files (`api.md`, `stack-gotchas.md`) keep Better Auth as the documented default; the
  knowledge file is loaded on-demand for Zitadel/Hydra projects.

### Rationale

- Better Auth stays the simplest path — library, no external service, ships with everything.
- Zitadel is the cleanest "we need a real IdP" upgrade — OIDC + Management API + multi-tenant
  org model out of the box.
- Hydra handles M2M cleanly via `client_credentials`. Combining it with Better Auth/Zitadel
  on a single Better-Auth-only setup would have meant reinventing OAuth2 token issuance.
- Keeping integration content in `knowledge/` rather than `rules/` keeps the always-loaded
  context budget flat for projects that don't use them.

### Consequences

- `api.md` opens its Auth section with the provider-choice preamble pointing at the knowledge
  file for the non-default options.
- `/setup-project` asks Q6a "Auth provider" when the auth layer is active.
- Two new env-var blocks in `.env.example` (commented; uncommented per choice).
- Future provider additions (Clerk, Supabase Auth) can slot in alongside without disturbing
  the default.

---

## ADR-007: Testing runner split — Vitest (frontend) + Jest (backend)

**Date:** 2026-05-17
**Status:** accepted

### Context

The kit's rule was "Jest ONLY, never Vitest." The reason was real — Vitest's esbuild/SWC
transformer does NOT preserve `emitDecoratorMetadata`, which silently breaks NestJS DI
(services come back `undefined` in controllers/guards). But the blanket rule overcorrected:
on the React frontend, decorator metadata isn't used at all, and Vitest pairs natively with
Vite, sharing config + transform pipeline + watch behavior.

### Decision

Split the testing rule by app:

| App / lib | Runner | Reason |
|-----------|--------|--------|
| `apps/client` + frontend libs (React) | **Vitest** | Vite-native, fast |
| `apps/api` + backend/domain libs (NestJS) | **Jest** + ts-jest | Decorator metadata preserved |
| E2E | **Playwright** | Cross-browser, ships with debugger |

The hard rule remains: **NEVER run NestJS tests under Vitest** — DI silently fails.

### Rationale

- Two runners means two configs, but each is the natural choice for its app — no compromise
  toolchain for either side.
- `pnpm nx test [project]` abstracts the runner, so day-to-day commands stay identical.
- E2E sits separately because it isn't unit/integration; Playwright is the de facto pick.

### Consequences

- `testing.md` documents both configs + a Playwright section.
- `test-writer` agent description and rules updated to mention both runners and the hard
  rule.
- `package.json.template.md` lists Jest + ts-jest + @types/jest for the backend, and Vitest +
  @vitejs/plugin-react + jsdom + @testing-library/\* for the frontend.
- The "NEVER use Vitest for the NestJS backend" gotcha in `stack-gotchas.md` is reframed to
  scope the rule to NestJS, not all tests.
