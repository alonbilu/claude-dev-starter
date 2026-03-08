# Code Quality & Linting

## Biome — The Only Linter (Never ESLint)

**Framework:** Biome 1.9+ (NOT ESLint — deprecated)
**Config:** `biome.json` at workspace root
**Pre-commit:** Automatically runs on staged files via Husky + lint-staged

---

## Commands

```bash
pnpm check                           # lint entire workspace
pnpm check:fix                       # auto-fix all fixable issues
pnpm format                          # format entire workspace
pnpm nx lint [project]               # lint specific project
pnpm nx lint [project] -- --write    # lint + auto-fix specific project
```

### Pre-Commit Hook (Automatic)

Every `git commit` runs Biome on staged files automatically.
Auto-fixes are re-staged and included in the commit.
Commit is blocked only if there are unfixable errors.

```bash
# Normal commit — hook runs automatically
git commit -m "feat: add user endpoint"

# Emergency bypass only (fix immediately after)
git commit -m "hotfix" --no-verify
```

---

## Key Rules

### noExplicitAny
```typescript
// ❌
function handle(data: any) {}

// ✅
function handle(data: unknown) {}
// or
function handle(data: Record<string, unknown>) {}
```

### noUnusedVariables / noUnusedImports
```typescript
// ❌ — will block commit
import { useState, useMemo } from 'react';  // useMemo unused

// ✅ — remove unused, prefix intentionally-unused with _
const [_, setCount] = useState(0);
```

### noUnusedTemplateLiteral
```typescript
// ❌
const msg = `Hello world`;  // no interpolation

// ✅
const msg = 'Hello world';
```

### useOptionalChain
```typescript
// ❌
const name = user && user.profile && user.profile.name;

// ✅
const name = user?.profile?.name;
```

---

## Suppression (Use Sparingly)

```typescript
// ✅ OK — suppress with a reason
// biome-ignore lint/suspicious/noExplicitAny: third-party lib has no types
const config: any = externalLib.getConfig();
```

**When to suppress:**
- Third-party library has no TypeScript types
- Required by a framework interface
- Intentionally unused (document why)

**Never suppress:**
- "I'll fix it later"
- "Too hard to fix"

**Stale suppressions:** Remove `biome-ignore` comments when the violation no longer exists
(`suppressions/unused` rule will catch these and fail your commit).

---

## lint-staged Configuration

Add to `package.json`:

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "biome check --write --no-errors-on-unmatched --files-ignore-unknown=true"
    ]
  }
}
```

---

## Pre-Commit Hook Recovery

If lint-staged fails, it stashes your working changes. **NEVER run `git stash drop`** — you'll lose everything.

Safe recovery:
```bash
git show stash@{0}           # inspect the stash
git checkout -- .nx/         # clear conflict source (Nx cache)
git stash pop                # retry
```

---

## Nx Project Lint Target

Each project's `project.json` should have:

```json
{
  "targets": {
    "lint": {
      "executor": "nx:run-commands",
      "options": {
        "command": "biome check --write apps/[project]/src"
      }
    }
  }
}
```

---

## Conventions

```typescript
// Naming
const myVariable = 'value';          // camelCase variables
function myFunction() {}             // camelCase functions
class MyClass {}                     // PascalCase classes
const MY_CONSTANT = 'value';         // UPPER_SNAKE_CASE constants
interface MyInterface {}             // PascalCase interfaces

// Imports: organized automatically by Biome
// 1. External libs (alphabetical)
// 2. Internal @app/* libs (alphabetical)
// 3. Relative imports (alphabetical)

// String quotes: single quotes (Biome enforced)
const str = 'hello world';
const jsx = <div className="tailwind-class" />;  // double in JSX
```
