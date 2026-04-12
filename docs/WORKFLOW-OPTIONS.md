# Workflow Options — Features vs Services vs SubModules

This template supports **three different development workflows**. Choose the right one for what you're building.

---

## The Main Workflow: Features (Recommended)

Use `/new-feature` when building **user-facing capabilities** (frontend or API-focused work).

**Structure:**
```
docs/features/active/F[XXX]-feature-name/
├── 1-idea.md          # What and why
├── 2-discussion.md    # Questions and approach
├── 3-spec.md          # Technical spec (DB, API, UI)
├── 4-dev-plan.md      # Atomic steps (2–12)
├── STATUS.md          # Progress tracking
└── CONTEXT.md         # 1-page quick-load
```

**Phases:**
1. `/new-feature` → capture idea
2. `/discuss-feature` → explore approach
3. `/plan-feature` → spec + dev plan (or `/generate-spec` + `/plan-execution`)
4. `/start-coding` → implement step-by-step
5. `/complete-feature` → archive + version bump

**When to use:**
- ✅ New API endpoint + database changes
- ✅ New UI page or user workflow
- ✅ Auth feature (OAuth, 2FA)
- ✅ Payment/billing workflow
- ✅ Export/import functionality
- ✅ Anything with clear acceptance criteria

**Example:** "Email verification on signup" → feature

---

## Specialized Workflow: Services (Backend-Only)

Use `/new-service` when building **background processes** or **coordination systems** (no user-facing UI).

**Structure:**
```
docs/services/service-name/
└── spec.md            # Purpose, dependencies, data flow
```

**When to use:**
- ✅ Background job processor (email queue, notifications)
- ✅ Webhook receiver / event handler
- ✅ Data sync service (3rd party integrations)
- ✅ Analytics aggregator
- ✅ Report generator
- ✅ Any backend-only process

**Difference from features:**
- Simplified workflow (no discussion → spec → plan cycle)
- Spec is simpler (focus: purpose, data flow, dependencies)
- No frontend component
- Usually runs independently (cron, queue, webhook)

**Example:** "Send email notifications via queue" → service

---

## Advanced Workflow: Modules & SubModules (Hierarchical)

Use Modules when your project has **explicit domain boundaries** (bounded contexts).

### Creating a Module

```bash
/new-module billing
```

A Module is a top-level domain area (e.g., users, billing, notifications). It creates:
- `docs/modules/[name]/spec.md` — module specification
- `libs/domain/[name]/` — Nx domain library

### Adding SubModules to a Module

```bash
/new-submodule billing invoice-generation
/implement-submodule billing invoice-generation
```

SubModules are capabilities within a Module (e.g., invoice-generation inside billing).

**Structure:**
```
docs/modules/billing/
├── spec.md
└── submodules/
    ├── invoicing/
    │   └── idea-spec.md
    └── refunds/
        └── idea-spec.md
```

**When to use Modules:**
- ✅ Your project has explicit domain modules (User, Billing, Reporting)
- ✅ You want features organized under their parent module
- ✅ Multiple related features under one module (e.g., Billing: invoicing, subscriptions, refunds)

**When NOT to use:**
- ❌ You don't have a module structure yet (start with `/new-feature`)
- ❌ Features are standalone or cross-cutting

**Example:** Create a Billing module, then add "invoice-generation" and "refunds" as submodules

---

## Quick Actions (Lightweight — No Feature Docs)

For tasks that don't need the full feature workflow:

| Command | When | Time |
|---------|------|------|
| **`/quick [task]`** | Small fix, <5 files, no schema changes | 5-15 min |
| **`/debug [error]`** | Systematic error debugging | 10-30 min |
| **`/scaffold [type] [name]`** | Generate boilerplate (endpoint, page, hook, service, domain-lib) | 5 min |

**Examples:**
```bash
/quick fix typo in 404 page
/debug pnpm nx test api fails with "service is undefined"
/scaffold endpoint users
```

---

## Decision Tree

```
How big is this task?

├─ SMALL fix (5-15 min, <5 files)
│  └─ Use: /quick ✅
│
├─ DEBUGGING an error
│  └─ Use: /debug ✅
│
├─ BOILERPLATE generation
│  └─ Use: /scaffold ✅
│
├─ USER-FACING capability (API + UI + DB)
│  ├─ API endpoint, UI page, workflow
│  └─ Use: /new-feature ✅
│
├─ BACKEND-ONLY process
│  ├─ Queue worker, webhook, sync service
│  └─ Use: /new-service ✅
│
├─ NEW DOMAIN AREA (bounded context)
│  └─ Use: /new-module ✅
│
└─ FEATURE under an existing Module
   ├─ If you have module structure
   └─ Use: /new-submodule ✅
```

---

## Quick Comparison

| Aspect | Quick | Feature | Service | Module | SubModule |
|--------|-------|---------|---------|--------|-----------|
| **Purpose** | Small fix | New capability | Background process | Domain area | Module capability |
| **User-facing?** | Varies | Yes (usually) | No | N/A (container) | Yes (usually) |
| **Complexity** | 5-15 min | 2–12 steps | Simple | Simple | 4 steps |
| **Has Frontend?** | Maybe | Often | No | No | Often |
| **Creates docs?** | No | Yes (6 phases) | Yes (spec only) | Yes (spec) | Yes (idea-spec) |
| **Command** | `/quick` | `/new-feature` | `/new-service` | `/new-module` | `/new-submodule` |
| **Example** | Fix typo | OAuth login | Email queue | Billing domain | Invoice generation |

---

## Mixing Workflows in One Project

It's fine to use multiple patterns in the same project:

```
docs/
├── features/        ← Main workflows
│   └── active/
│       ├── F001-oauth-login/          (feature)
│       └── F002-payment-flow/         (feature)
├── services/        ← Background work
│   ├── email-queue/                   (service)
│   └── webhook-processor/             (service)
└── modules/         ← If you have domain structure
    ├── billing/
    │   ├── spec.md
    │   └── submodules/
    │       ├── invoicing/             (submodule)
    │       └── refunds/               (submodule)
    └── reporting/
        ├── spec.md
        └── submodules/
            └── analytics/             (submodule)
```

---

## Recommendation for New Projects

**Start with Features** (`/new-feature`).

- Simpler mental model
- Works for 90% of work
- You can migrate to Services or SubModules later if needed
- Default to features unless you have a specific reason not to

If you need Services or SubModules:
- You'll know it (clear backend-only process, or explicit module structure)
- Document which pattern you're using in your project README
- Reference this guide in `brain.md`

---

## Multi-Repo Projects

The patterns above assume a single repo. If your project lives across multiple repos (e.g. separate frontend + backend), see [`MULTI-REPO-HUB.md`](MULTI-REPO-HUB.md) for the hub-model variant. Short version: one repo owns the feature docs, every repo uses matching branch names, each dev-plan step declares a target repo, and `/create-pr` opens one PR per repo touched.
