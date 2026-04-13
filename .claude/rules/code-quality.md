# Code Quality & Linting

## The point: Biome enforced via husky pre-commit hook

**Biome alone is just a developer-side checker.** Without a git pre-commit hook, nothing prevents code that fails `biome check` from being committed. The husky + lint-staged combo IS the enforcement layer — it turns Biome from "occasionally noticed advice" into "you literally cannot commit until it's clean."

If husky is not active in your project, your Biome rules are decorative.

**Setup (one-shot, idempotent):**

```bash
bash scripts/install-pre-commit.sh
```

That script:
- Verifies Biome is installed
- Installs `husky` + `lint-staged` as dev deps
- Runs `npx husky init` (creates `.husky/` + the git hook stub)
- Writes `.husky/pre-commit` to invoke `npx lint-staged`
- Adds the `lint-staged` config + `"prepare": "husky"` to your `package.json`

After the script finishes, every `git commit` runs Biome on staged `.ts/.tsx/.js/.jsx` files. Auto-fixes are re-staged and proceed. Unfixable errors block the commit.

> Run this AS PART of project setup (`/setup-project` triggers it). Don't defer it to "later" — every commit before the hook is installed is a potential regression nobody will notice.

---

## Biome — The Only Linter (Never ESLint)

**Framework:** Biome 2.4+ (NOT ESLint — deprecated)
**Config:** `biome.json` at workspace root — uses 2.4-era schema syntax (`files.includes` with negation, `assist.actions.source.organizeImports`, `suspicious.noConsole`). Older installs MUST upgrade or run `npx @biomejs/biome migrate` to avoid parse errors.
**Pre-commit:** Automatically runs on staged files via Husky + lint-staged (see "The point" above).

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

## ⚠️ Biome formatter writes during Edit — beware massive commit diffs

The `biome-format.sh` PostToolUse hook runs `biome check --write` on every file you Edit/Write. If a file hasn't been formatted in a while AND you make a small semantic change to it, the resulting commit will include the entire file's reformat (often hundreds or thousands of lines) plus your few lines of intent. Reviewers can't spot your actual change in that noise.

**Mitigations:**

- **(a) Format-first-commit pattern:** before making your semantic change, do `npx biome check --write <file>` and commit it as `chore(format): biome auto-format <file>`. THEN make your semantic change in a second commit — that commit's diff is now just your intent.
- **(b) Document the noise:** if (a) is too much ceremony, write the commit message body with explicit line numbers of the semantic changes so reviewers know where to look. Example:
  ```
  feat(api): add retry logic to ImportLegs

  Semantic changes only:
  - src/index.ts:81  — wrap supplierTools.ImportLegs in retry helper
  - src/index.ts:147 — extract retry config to constant
  Everything else in this commit is biome auto-format.
  ```
- **(c) Skip the hook for one Edit:** rarely warranted. If you must, temporarily comment out the hook entry in `.claude/settings.json`, do your edit, restore the hook, manually run `biome check --write` so the file is normalized at the end.

The format-first pattern is the right default for any project that has lived without consistent formatting.

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
