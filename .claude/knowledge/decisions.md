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
| B2B API + embeddable widget/whitelabel | **Option 1** — see ADR-003 |

### Consequences
- Template rules, agents, hooks, and gotchas are tuned for Option 1
- Choosing Option 2 or 3 requires manual updates to rules files, agents, and hooks
- `/setup-project` wizard explains trade-offs during stack confirmation step

---

## ADR-003: B2B Whitelabel + API architecture

**Date:** 2026-03-10
**Status:** accepted

### Context
For B2B whitelabel solutions where customers embed a storefront/widget into their own websites, the architecture needs to serve two audiences: (1) an API for customer backend integrations, and (2) an embeddable frontend component that lives inside the customer's site.

### Decision
Use the **separated architecture (React + Vite + NestJS)** with the frontend built as an embeddable widget rather than a full SPA.

### Rationale

**Why NOT Next.js for whitelabel:**
- Whitelabel UIs are **embedded into customer sites** (via iframe, Web Component, or JS SDK) — they don't need SSR because they're not crawled by Google
- Next.js assumes it owns the page — it controls routing, head tags, and the HTML shell. An embeddable widget should NOT own the page
- Customers integrate via `<script>` tag or iframe, not by deploying a Next.js app
- SSR adds server-side complexity for something that renders client-side inside someone else's page

**Recommended B2B whitelabel architecture:**

```
┌─────────────────────────────────────────────┐
│ NestJS API (your backend)                    │
│  ├── Public API (REST/GraphQL) — customers   │
│  │   integrate their own backends            │
│  ├── Admin API — your internal dashboard     │
│  └── Widget config API — serves widget       │
│      settings per customer (theme, products) │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───┴────┐          ┌─────┴──────┐
│ Widget │          │ Admin SPA  │
│ (React)│          │ (React +   │
│ embed  │          │  Vite)     │
│ via JS │          │ your team  │
│ SDK or │          │ manages    │
│ iframe │          │ customers  │
└────────┘          └────────────┘
```

**Three deployment artifacts:**
1. **NestJS API** — the core product. Public REST/GraphQL API for B2B customers + admin endpoints
2. **Embeddable widget** — React app built as a JS bundle (not a full SPA). Loaded via `<script src="https://cdn.you.com/widget.js">` or iframe. Configured per customer (theme, products, branding)
3. **Admin dashboard** — internal React + Vite SPA for managing customers, products, config

**Widget build approach:**
- Build with Vite in **library mode** → outputs a single JS file
- Or use Web Components → framework-agnostic, shadow DOM isolates styles
- Or iframe → simplest isolation, no CSS conflicts, but less integrated feel

**Why this is better than Next.js for whitelabel:**
- Widget is a lightweight client-side bundle — no server needed per customer
- CDN-hosted — scales infinitely, no per-customer server costs
- API-first design — customers who don't want the widget can build their own UI
- Admin dashboard is a standard SPA — no SSR complexity needed for internal tools

### Consequences
- Frontend is split into two build targets: widget (library mode) and admin (SPA)
- Widget needs its own Vite config with library mode output
- Must handle theming/branding via API config (CSS variables, logo URL, color palette)
- CORS must allow customer domains (dynamic origin whitelist)
- Consider a customer onboarding flow that generates embed code snippets
