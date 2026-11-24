---
description: Systematic debugging workflow for errors and issues
---

Debug: $ARGUMENTS

## Workflow

Follow these steps IN ORDER. Do NOT skip steps.

### 1. Reproduce

Get the exact error. Run the failing command or action to see the full error output:
```bash
# Run the failing test, build, or serve command
pnpm nx test [project]
pnpm nx build [project]
pnpm nx serve [project]
```
Capture the **exact error message**, stack trace, and file/line references.

### 2. Check Known Gotchas

Read `.claude/knowledge/stack-gotchas.md` and search for patterns matching this error:
```bash
grep -i "error_keyword" .claude/knowledge/stack-gotchas.md
```
If a matching gotcha exists, follow its documented solution. Skip to Step 5 (the failing test still comes before the fix).

### 3. Isolate

Narrow down to the specific file and function:
- Trace the error stack from top to bottom
- Read the failing file and surrounding code
- Check imports, dependencies, and configuration
- Use `grep` to find where the problematic value originates

### 4. Hypothesize

**State your theory BEFORE changing any code:**
```
Theory: [What I think is causing this error and why]
Evidence: [What supports this theory]
Test: [How I'll verify this theory]
```
This prevents shotgun debugging. If your theory is wrong, form a new one.

### 5. Write a failing test (BEFORE the fix)

Turn the theory into a test that reproduces the bug, and run it:
```bash
pnpm nx test [project] -- [path/to/file.spec.ts]
```
It must **fail**, and fail for the reason in your theory — not because of a typo, a missing
import, or a fixture that never reaches the faulty code. If it passes, the theory (or the
test) is wrong: go back to Step 4. Do not change production code yet.

Skip this step only when the failure is not a behaviour bug: the error *is* an already-failing
test, a build/type error, or a tooling/config problem. In those cases the failing command
from Step 1 is the regression check — say which one you are using.

### 6. Fix & Verify

Implement the fix, then:
```bash
pnpm nx test [project] -- [path/to/file.spec.ts]   # the test from Step 5 — must now PASS
pnpm verify                                         # lint, boundaries, typecheck, test + coverage, build
```
Confirm the original error is resolved AND no new errors introduced. If you are not certain
the test exercises the fix, revert the production change, confirm the test goes red again,
then restore it.

### 7. Document

If this was a **new gotcha** not already in `stack-gotchas.md`:
- Append to `.claude/knowledge/stack-gotchas.md` under the relevant section
- Include: symptom, cause, fix, and example code
- If it's a top-5 critical gotcha, add a one-liner to `.claude/brain.md`

If the fix touches a Zod schema, follow the 8-step propagation protocol (see `.claude/rules/database.md`).

---

## Commit

```
fix(scope): description of what was fixed
```

---

Usage:
/debug TypeError: Cannot read properties of undefined
/debug pnpm nx test api fails with "service is undefined"
/debug Prisma migration error on deploy
