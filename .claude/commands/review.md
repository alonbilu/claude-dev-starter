---
description: Pre-PR review — pnpm verify, then an independent read-only reviewer with fresh context
---

Review changes before creating a PR.

The session that wrote the code is the worst-placed to review it: it reads what it meant to
write. So this command does two things only — proves the branch is green, then hands the diff
to the **`code-reviewer` subagent**, which starts with no memory of this session and cannot
edit files. You relay its report; the user decides what to do with it.

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

### 3. Independent review (code-reviewer subagent)

1. Save the diff where the reviewer can read it (inside `.git/`, so it can never be committed):
   ```bash
   git diff main...HEAD > .git/REVIEW.diff
   ```
2. Find the spec: if the branch belongs to a feature, it is
   `docs/features/active/F[XXX]-[name]/3-spec.md`; for a hotfix,
   `docs/hotfixes/active/HF[XXX]-[name]/1-hotfix.md`; for a quickbranch, its
   `docs/quickbranches/` entry. Otherwise `none`.
3. Spawn the `code-reviewer` agent (`subagent_type: code-reviewer`) with **exactly** this
   prompt and nothing else:
   ```
   DIFF: .git/REVIEW.diff
   SPEC: <path, or none>
   BASE: main
   Review this diff per your instructions and return the report in the fixed format.
   ```
   **Do not add your own summary, explanation, test results or opinion of the change.** The
   reviewer is only independent if it sees the spec and the diff, not your account of them.
   One agent, one pass — do not split the diff across several reviewers.
4. When it returns, show its report to the user **in full and unedited** (keep the tables).
   Do not filter out findings you disagree with; if you think one is wrong, say so *after*
   the report, with evidence.
5. **Do not fix anything yet.** The user decides which findings to act on. A BLOCK or
   REQUEST CHANGES verdict means "not ready for PR" until the user says otherwise.

If the `code-reviewer` agent is unavailable, say so and stop — do not fall back to reviewing
your own work and calling it a review.

### Code Quality Checklist (applied by the reviewer)

This is the checklist the `code-reviewer` agent applies — it reads this section. Keep it here
as the single source; add new guards here, not in the agent file.

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

**Diff hygiene:**
- [ ] No leftover `console.log` or debug statements
- [ ] No TODO/FIXME that should have been resolved in this change
- [ ] No overly complex logic that could be simplified
- [ ] Error handling present at system boundaries (HTTP, DB, queue, external APIs)

### 4. Report

Output, in this order:

```
🔍 Pre-PR Review — [branch name]

Files changed: [N]
Lines: +[X] / -[Y]

pnpm verify: green | RED (which steps)

Independent review (code-reviewer): [APPROVE | REQUEST CHANGES | BLOCK]
```

…followed by the reviewer's report, verbatim. End with:

```
Recommendation: [Ready for PR / Not ready — N blocking issue(s)]
```

The same reviewer can run on every pull request in CI — see `docs/UNATTENDED.md` →
"Independent review on every PR".

---

## Rules

- You (the authoring session) do not review — you run `pnpm verify`, spawn the reviewer, and relay
- Never pass the reviewer your own description of the change
- Never apply the reviewer's suggestions without the user's say-so
- Biome handles formatting — the reviewer does not flag formatting issues
- If you find a new gotcha, add it to `.claude/knowledge/stack-gotchas.md`

Usage:
/review
