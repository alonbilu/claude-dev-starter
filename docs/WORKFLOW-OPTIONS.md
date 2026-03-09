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

## Advanced Workflow: SubModules (Hierarchical)

Use `/new-submodule` when building **features within a bounded context** (Module structure).

**Structure:**
```
docs/modules/parent-module/
├── spec.md
└── submodules/
    └── sub-feature-name/
        └── idea-spec.md
```

**When to use:**
- ✅ Your project has explicit domain modules (User, Billing, Reporting)
- ✅ You want features organized under their parent module
- ✅ Multiple related features under one module (e.g., Billing: invoicing, subscriptions, refunds)

**When NOT to use:**
- ❌ You don't have a module structure yet (start with `/new-feature`)
- ❌ Features are standalone or cross-cutting

**Example:** In a Billing module, add "invoice-generation" as a submodule

---

## Decision Tree

```
Is this a feature or process?

├─ USER-FACING capability
│  ├─ API endpoint, UI page, workflow
│  └─ Use: /new-feature ✅
│
├─ BACKEND-ONLY process
│  ├─ Queue worker, webhook, sync service
│  └─ Use: /new-service ✅
│
└─ FEATURE under an existing Module
   ├─ If you have module structure
   └─ Use: /new-submodule ✅
```

---

## Quick Comparison

| Aspect | Feature | Service | SubModule |
|--------|---------|---------|-----------|
| **User-facing?** | Yes (usually) | No | Yes (usually) |
| **Complexity** | 2–12 steps | Simple | 4 steps |
| **Has Frontend?** | Often | No | Often |
| **Phases** | 6 (idea → discuss → spec → plan → implement → complete) | 1 (spec only) | 4 (idea-spec → implement) |
| **Best for** | New capabilities | Background work | Modular features |
| **Example** | OAuth login | Email queue | Billing invoice generation |

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
