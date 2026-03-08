# Architecture Rules

## ⚠️ CRITICAL: The Two Reuse Rules

### Rule 1 — Search Before Creating

**Before writing ANY new code, ask:**

1. **Does this already exist?**
   ```bash
   pnpm nx graph                          # visualize all libs
   grep -r "functionName\|ClassName" libs/ # search for existing implementations
   ls libs/shared/ libs/domain/ libs/backend/  # browse existing libs
   ```

2. **Can I extend or compose what exists?**
   - Prefer extending an existing service over creating a new one
   - Prefer composing existing utilities over writing new ones
   - Prefer importing from `libs/shared/ui` over building new UI components

3. **Is this type already defined?**
   - Check `libs/shared/types/` first — if the type exists, import it
   - Never copy-paste type definitions

**Golden rule:** Code duplication is a bug. If you find yourself writing something that looks like
existing code, stop and find the existing implementation.

---

### Rule 2 — Write for Reuse from Day One

**When creating any new component or utility, build it generically — not just for this one feature.**

Ask before finalizing any new piece of code:
- Could another feature use this with different props/params? → make it configurable
- Is this UI pattern going to appear again? → put it in `libs/shared/ui/`
- Is this business logic pattern going to appear again? → put it in `libs/shared/utils/`
- Is this data access pattern repeated? → extract to a repository method

**Concrete examples:**

```typescript
// ❌ Built just for this feature — will be duplicated
function formatUserDate(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ✅ Built for reuse — goes in libs/shared/utils/date.utils.ts
export function formatDate(date: Date, locale = 'en-US', options?: Intl.DateTimeFormatOptions) {
  return date.toLocaleDateString(locale, options ?? { month: 'short', day: 'numeric' });
}
```

```tsx
// ❌ Hardcoded for one use case
function UserStatusBadge({ user }: { user: User }) {
  return <span className="bg-green-100 text-green-800 px-2 py-1 rounded">{user.status}</span>;
}

// ✅ Generic — goes in libs/shared/ui/ and works for any entity
function StatusBadge({ label, color }: { label: string; color: 'green' | 'yellow' | 'red' | 'gray' }) {
  const colors = { green: 'bg-green-100 text-green-800', ... };
  return <span className={`${colors[color]} px-2 py-1 rounded`}>{label}</span>;
}
```

**Where reusable code lives:**

| Type | Location |
|------|----------|
| Reusable UI components | `libs/shared/ui/src/lib/components/` |
| Pure utility functions | `libs/shared/utils/src/lib/[topic].utils.ts` |
| Shared types/schemas | `libs/shared/types/src/lib/` |
| Shared NestJS modules | `libs/backend/core/src/lib/` |
| Complex DB queries | `libs/domain/database/src/lib/repositories/` |

**When in doubt:** If you're about to write something for the second time — stop. Extract the first
instance first, then reuse it.

---

## Layered Architecture

```
┌─────────────────────────────────────┐
│           apps/                      │  ← HTTP/UI Layer (THIN — no business logic)
│  client/  api/  gateway/            │
└──────────────┬──────────────────────┘
               │ imports ↓
┌──────────────┴──────────────────────┐
│        libs/backend/                 │  ← Framework-specific modules (NestJS)
│  core/  auth/  email/               │
└──────────────┬──────────────────────┘
               │ imports ↓
┌──────────────┴──────────────────────┐
│        libs/domain/                  │  ← Business Logic (lives here)
│  users/  projects/  [feature]/      │
│  database/  storage/                │
└──────────────┬──────────────────────┘
               │ imports ↓
┌──────────────┴──────────────────────┐
│        libs/shared/                  │  ← Foundation (reusable, no business logic)
│  types/  ui/  config/  utils/       │
└─────────────────────────────────────┘
```

**Rules:**
- Top layers can import from bottom layers
- Bottom layers CANNOT import from top layers
- Verify with: `pnpm nx graph`

---

## Import Restrictions

| From ↓ → To | `apps/*` | `libs/backend/*` | `libs/domain/*` | `libs/shared/*` |
|-------------|----------|------------------|-----------------|-----------------|
| **`apps/*`** | ❌ | ✅ | ✅ | ✅ |
| **`libs/backend/*`** | ❌ | ⚠️ | ✅ | ✅ |
| **`libs/domain/*`** | ❌ | ❌ | ⚠️ | ✅ |
| **`libs/shared/*`** | ❌ | ❌ | ❌ | ⚠️ |

---

## Apps are THIN

`apps/` contains ONLY:
- HTTP entry points and routing
- Framework bootstrap code
- Minimal glue between libs

**ALL business logic goes to `libs/domain/`.**

---

## No Duplicate Logic — The Core Rule

### ❌ Never do this:
```typescript
// Don't write the same validation in multiple places
// Don't copy-paste error handling
// Don't create a new util when one already exists in libs/shared/utils/
// Don't define a type that already exists in libs/shared/types/
```

### ✅ Always do this:
```typescript
// Find the existing util: grep -r "formatDate" libs/shared/utils/
import { formatDate } from '@app/utils';

// Find the existing type: ls libs/shared/types/src/lib/
import type { User } from '@app/types';

// Find the existing component: ls libs/shared/ui/src/lib/
import { Button, Card } from '@app/ui';
```

### Cross-domain reuse:
If multiple domain libs need the same logic, extract it:
- Pure functions → `libs/shared/utils/`
- Shared types → `libs/shared/types/`
- Shared UI → `libs/shared/ui/`
- Shared NestJS modules → `libs/backend/core/`

---

## Domain Lib Split for Frontend Safety

When a domain lib has heavy Node.js dependencies (file system, crypto, external SDKs),
split it into two entry points so the browser-safe code is importable by the frontend:

```
libs/domain/my-feature/
├── src/
│   ├── index.ts          ← backend entry (all exports, including Node.js-specific)
│   └── client.ts         ← client entry (pure functions + types only, NO Node.js)
```

```typescript
// Backend imports from index
import { MyService } from '@app/my-feature';

// Frontend imports from client entry
import { parseMyData } from '@app/my-feature/client';
```

---

## When to Create a New Library

**Create a new lib when:**
- ✅ Logic is genuinely distinct (new domain or bounded context)
- ✅ Multiple apps or libs will import it
- ✅ You want independent testing with clear boundaries

**Do NOT create a new lib when:**
- ❌ A single function or class (add to nearest relevant existing lib)
- ❌ The code is only used in one place (put it there)
- ❌ You're duplicating an existing lib under a different name

---

## After Generating a Lib — Remove Build Target

Domain libs are consumed directly. They don't need their own build step.

```bash
# After generating:
pnpm nx g @nx/js:library my-feature --directory=libs/domain/my-feature

# Remove from libs/domain/my-feature/project.json:
# "build": { ... }   ← delete this entire target block
```

---

## Checklist Before Writing New Code

- [ ] Searched for existing implementation (`grep -r` + `pnpm nx graph`)
- [ ] Checked `libs/shared/types/` for existing types
- [ ] Checked `libs/shared/ui/` for existing components
- [ ] Checked `libs/shared/utils/` for existing utilities
- [ ] Verified import direction is legal (bottom → bottom is never allowed)
- [ ] This lib needs a `build` target? (domain libs: NO)
