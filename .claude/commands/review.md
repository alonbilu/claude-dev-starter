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
pnpm verify
```

One command, the same one CI runs: lint, import boundaries, typecheck, test + coverage
minimums, build. If it fails, fix it before continuing the review.

### 3. Code Quality Checklist

For each changed file, check:

**Architecture:**
- [ ] No import boundary violations — enforced by `pnpm verify` (`scripts/check-boundaries.js`); don't re-check by eye
- [ ] Business logic in `libs/domain/`, NOT in controllers or components
- [ ] Reusable code in `libs/shared/`, not duplicated across features
- [ ] No circular dependencies — also enforced by `pnpm verify`

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
- [ ] New services have tests (coverage minimums are enforced by `pnpm verify` — check the tests are *meaningful*, not just present)
- [ ] No `it.skip` or `describe.skip` in new tests
- [ ] External services mocked
- [ ] Test DB used for integration tests (port 5443, not 5442)
- [ ] **Falsify the acceptance test** — for a new rule/acceptance test, confirm it goes RED without the
      change under test. A test that passes because it never exercised the case is worse than none; watch
      for fixtures shaped to match the implementation (single-mode / edge-case seed data is the tell).

**Shared-field semantics (catches "correct in isolation, contradictory together"):**
- [ ] When a change adds a check that reads a field ANOTHER rule/consumer already reads, verify they
      AGREE on what that field means. This is a GENERAL pattern for any shared field — a denormalized
      copy, a user-supplied value, an upstream/LLM echo, a cached flag — not one domain. Divergent
      interpretations pass every isolated test yet contradict each other: e.g. one consumer treats the
      value as *committed* (derives downstream state from it) while a new one treats it as merely
      *advisory*. Grep the field name across all rules/consumers and reconcile before shipping.

**Amendment sweep (catches "the doc/code contradicts itself after a revision"):**
- [ ] When amending a decision — in a spec, a plan, OR code — grep the whole doc/code set for every
      RESTATEMENT of the old design and sweep them all in the same pass. Amendments applied only at the
      decision's home section leave downstream sections (API tables, error matrices, test descriptions,
      commit-message templates, CONTEXT primers) describing the superseded design — and those are what
      implementers/tests actually read.
- [ ] **"Edit executed" ≠ "edit landed":** after ANY review-application pass, grep the target docs for
      each finding ID before declaring it applied. Scripted find-replace against stale document state
      fails SILENTLY, and the failure is invisible until someone diffs intent against text. Verify every
      replacement matched at edit time AND grep-verify per finding before commit.

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

✅ pnpm verify: green (lint · boundaries · typecheck · test + coverage · build)

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
