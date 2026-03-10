---
description: Quick fix or small change (5-15 min, no feature docs)
---

Quick task: $ARGUMENTS

## Rules

- **NO** feature docs, branch, or registry entry — this is a fast lane
- Stay on current branch (or main if clean)
- Search before creating (this ALWAYS applies)
- If the task grows beyond ~15 minutes, stop and suggest `/new-feature` instead

---

## Steps

1. **Understand** — Parse `$ARGUMENTS` to determine what needs to change
2. **Search** — Check for existing code before writing anything:
   ```bash
   grep -r "relevant_term" libs/ apps/
   ```
3. **Load rules** — Based on task type, read the relevant rules:
   - Database changes → `.claude/rules/database.md`
   - API changes → `.claude/rules/api.md`
   - Frontend changes → `.claude/rules/frontend.md`
   - Test changes → `.claude/rules/testing.md`
4. **Implement** — Make the change. Keep it minimal and focused.
5. **Validate:**
   ```bash
   pnpm nx affected -t lint
   pnpm nx affected -t test
   ```
6. **Commit** — Use the appropriate prefix:
   - Bug fix → `fix(scope): description`
   - Cleanup/config → `chore(scope): description`
   - Small enhancement → `feat(scope): description`

---

## Scope Guard

If ANY of these are true, **stop and recommend `/new-feature` instead:**
- Task requires a new database table or migration
- Task touches more than 5 files
- Task requires new Zod schemas
- Task needs a new API endpoint + frontend page together

---

Usage:
/quick add lastName field to user form
/quick fix typo in 404 page
/quick update button color on dashboard
