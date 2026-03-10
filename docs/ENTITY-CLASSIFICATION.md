# Entity Classification Guide

This guide explains the different types of architectural components in the system and when to use each one.

## Key Concept: Features vs Entities

- **Feature** = a user-facing capability you're building ("Add OAuth login", "Export to PDF"). Created with `/new-feature`.
- **Entity** = an architectural component that features create or modify (a Module, Service, SubModule, or Processor).

You typically start with a **feature**, and during the discussion phase Claude identifies which **entities** to create or modify. However, you can also create entities directly using commands like `/new-module`, `/new-service`, `/scaffold`, etc.

---

## The 4 Entity Types

### 1. Module
A top-level domain area (bounded context). Lives in `libs/domain/`.

**Create when:** There is a new bounded context (a distinct subject area the software manages)

**Command:** `/new-module [name]` — creates docs + Nx domain lib

**Examples:** users, projects, billing, notifications, analytics

**Structure:**
```
libs/domain/[name]/
├── src/
│   └── lib/
│       ├── [name].service.ts
│       ├── [name].service.spec.ts
│       └── [name].module.ts   ← NestJS module (if backend)
└── index.ts
```

**Documented in:** `docs/architecture/modules/[name].md`

---

### 2. SubModule
A secondary capability within a Module. Lives inside its parent module.

**Create when:** A distinct slice of functionality belongs to an existing module but is large enough to warrant its own service file.

**Command:** `/new-submodule [parent] [name]` → `/implement-submodule [parent] [name]`

**Requires:** Parent Module must exist first (create with `/new-module`)

**Examples:** email-verification inside users, webhook-processing inside billing

**Structure:**
```
libs/domain/users/src/lib/
├── user.service.ts          ← core user logic
├── email-verification/
│   ├── email-verification.service.ts
│   └── email-verification.service.spec.ts
```

**Documented in:** `docs/architecture/modules/users.md` (subsection)

---

### 3. Service
A cross-cutting backend process or coordination layer. Lives in `libs/backend/`.

**Create when:** Logic serves multiple modules, or is infrastructure-adjacent (queues, webhooks, notifications).

**Command:** `/new-service [name]` → `/implement-service [name]`
**Scaffold:** `/scaffold service [name]` (for quick boilerplate without docs)

**Examples:** NotificationService, WebhookService, AnalyticsService

**Structure:**
```
libs/backend/[name]/
├── src/lib/
│   ├── [name].service.ts
│   └── [name].module.ts
└── index.ts
```

**Documented in:** `docs/architecture/services/[name].md`

---

### 4. Processor
A pure data transformation component. Zero side effects, fully testable.

**Create when:** There is a discrete transformation that is complex enough to isolate (PDF generation, price calculation, data normalization).

**No dedicated command** — processors are created as part of features or via `/scaffold service [name]`.

**Examples:** PdfGenerator, PriceCalculator, DataImporter

**Structure:**
```
libs/domain/[parent]/src/lib/processors/
├── [name].processor.ts
└── [name].processor.spec.ts
```

**Documented in:** `docs/architecture/processors/[name].md`

---

## Decision Guide: Which Entity?

```
Is this a new subject area the software manages?
  Yes → Module (/new-module [name])

Is this a secondary capability inside an existing module?
  Yes → SubModule (/new-submodule [parent] [name])

Does this serve multiple modules or is it infrastructure-adjacent?
  Yes → Service (/new-service [name])

Is this a pure data transformation with no side effects?
  Yes → Processor (created within a feature or via /scaffold)

Not sure? Just need boilerplate?
  → /scaffold [type] [name]
```

## Features vs Entities — The Key Difference

| | Feature | Entity |
|---|---------|--------|
| **What** | User-facing capability | Architectural component |
| **Example** | "Add OAuth login" | UserModule, AuthService |
| **Created by** | `/new-feature` | Features create entities during implementation |
| **Lifecycle** | Idea → Discuss → Spec → Plan → Implement → Complete | Lives permanently in the codebase |
| **Docs** | `docs/features/active/F[XXX]-[name]/` | `docs/modules/` or `docs/architecture/` |

**Rule of thumb:** Start with a Feature. Entities emerge from features during the discussion and planning phases. Only create entities directly (`/new-module`, `/new-service`) when you're setting up domain structure before building features.

---

## Architecture Documentation

Each entity gets a permanent doc in `docs/architecture/`:

```
docs/architecture/
├── modules/
│   ├── users.md
│   └── projects.md
├── services/
│   └── notification.md
└── processors/
    └── pdf-generator.md
```

**Template for a module doc:**

```markdown
# Module: [Name]

## Purpose
One sentence description of what this module manages.

## Location
`libs/domain/[name]/`

## Key Services
- `[Name]Service` — [what it does]

## Public API (exported from index.ts)
- `[Name]Service`
- `[Name]Module`

## Related Modules
- `[OtherModule]` — [why they interact]

## Created By Features
- F[XXX] — [feature name] (initial creation)
- F[YYY] — [feature name] (added capability X)
```
