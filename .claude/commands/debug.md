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
If a matching gotcha exists, follow its documented solution. Skip to Step 5.

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

### 5. Fix & Verify

Implement the fix, then verify:
```bash
pnpm nx test [project]
pnpm nx lint [project]
pnpm nx build [project]
```
Confirm the original error is resolved AND no new errors introduced.

### 6. Document

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
