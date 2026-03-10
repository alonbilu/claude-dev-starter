# Architecture Decisions Log

Record significant architectural decisions here. Format: context → decision → rationale → consequences.

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
