# Entity Classification Guide

Entities are the architectural components that features create or modify.
You don't start with an entity — you start with a feature, and the discussion phase identifies which entities to create.

---

## The 4 Entity Types

### 1. Module
A top-level domain area. Lives in `libs/domain/`.

**Create when:** There is a new bounded context (a distinct subject area the software manages)

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
  Yes → Module

Is this a secondary capability inside an existing module?
  Yes → SubModule

Does this serve multiple modules or is it infrastructure-adjacent?
  Yes → Service

Is this a pure data transformation with no side effects?
  Yes → Processor
```

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
