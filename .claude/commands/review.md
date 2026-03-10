---
description: Pre-PR self-review — catch issues before teammates see them
---

Review changes before creating a PR.

## Steps

### 1. Gather Changes

```bash
git diff main...HEAD --stat
git diff main...HEAD --name-only
```

Read every changed file. Understand the full scope of changes.

### 2. Run Automated Checks

```bash
pnpm nx affected -t lint
pnpm nx affected -t test
pnpm nx affected -t build
```

If any fail, fix them before continuing the review.

### 3. Code Quality Checklist

For each changed file, check:

**Architecture:**
- [ ] No import boundary violations (libs → apps is forbidden)
- [ ] Business logic in `libs/domain/`, NOT in controllers or components
- [ ] Reusable code in `libs/shared/`, not duplicated across features
- [ ] No circular dependencies

**Types & Schemas:**
- [ ] All types imported from `@app/types` (not defined locally)
- [ ] No `import type` for NestJS injectable services
- [ ] Zod schema changes propagated to all 8 targets (schema → migration → DTOs → services → frontend → seeds → tests)

**Code Patterns:**
- [ ] No duplicate code — search: `grep -r "functionName" libs/`
- [ ] Controllers are thin (delegate immediately to services)
- [ ] Explicit `@Inject()` on all constructor params
- [ ] TanStack Query for all API calls (no `useEffect` fetching)
- [ ] `setQueryData` + `invalidateQueries` in mutation `onSuccess`

**Security:**
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No `.env` files staged
- [ ] User input validated (Zod schemas + ZodValidationPipe)
- [ ] SQL injection safe (Prisma parameterized queries)

**Testing:**
- [ ] New services have tests (70%+ coverage for domain services)
- [ ] No `it.skip` or `describe.skip` in new tests
- [ ] External services mocked
- [ ] Test DB used for integration tests (port 5443, not 5442)

### 4. Diff Review

Review the actual code changes:
```bash
git diff main...HEAD
```

Look for:
- Leftover `console.log` or debug statements
- TODO/FIXME comments that should be resolved
- Unused variables or imports (Biome should catch these)
- Overly complex logic that could be simplified
- Missing error handling at system boundaries

### 5. Report

Output a summary:

```
🔍 Pre-PR Review — [branch name]

Files changed: [N]
Lines: +[X] / -[Y]

✅ Lint: pass
✅ Tests: pass
✅ Build: pass

Issues found: [N]
[List any issues with file:line references]

Recommendation: [Ready for PR / Fix N issues first]
```

---

## Rules

- Be thorough but practical — flag real issues, not style preferences
- Biome handles formatting — don't flag formatting issues
- If you find a new gotcha, add it to `.claude/knowledge/stack-gotchas.md`

Usage:
/review
