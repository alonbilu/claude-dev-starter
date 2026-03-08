# Brain — Project Institutional Memory

> **Keep this file ≤200 lines.** Move detailed content to `.claude/knowledge/` files.
> Read this at the START of every session. Update it whenever you learn something worth keeping.

---

## Quick Reference

| What | Where |
|------|-------|
| All gotchas (DI, Prisma, testing, Biome) | `.claude/knowledge/stack-gotchas.md` |
| Reusable code patterns | `.claude/knowledge/patterns.md` |
| Architecture decisions log | `.claude/knowledge/decisions.md` |
| Workflow commands | `docs/WORKFLOW-GUIDE.md` |
| Entity type guide | `docs/ENTITY-CLASSIFICATION.md` |

---

## Top 5 Gotchas (Always Remember)

1. **NEVER `import type` for NestJS injectables** — erased at runtime, DI breaks silently
2. **Always `@Inject(Service)` explicitly** — esbuild strips decorator metadata inconsistently
3. **Never Vitest** — breaks NestJS DI (`emitDecoratorMetadata` not preserved)
4. **Never `git stash drop` after failed lint-staged** — you lose all working changes
5. **Prisma 7.x: NO `url = env(...)` in datasource block** — reads DATABASE_URL automatically

→ Full details: `.claude/knowledge/stack-gotchas.md`

---

## Active Feature Work

> Update this section when starting/resuming a feature.

**Current feature:** (none — add when work begins)
**Branch:** main
**Last session:** (date)

---

## Project-Specific Insights

> Add insights as you discover them. Format: one-liner + link to detail if needed.

*(empty — add as you build)*

---

## Testing Conventions
- Jest only (never Vitest)
- `tsconfig.spec.json`: `"module": "commonjs"`, `"emitDecoratorMetadata": true`
- `jest.setup.ts`: `import 'reflect-metadata'` as first line
- Test DB runs on port 5443 (separate from dev DB on 5442)
- Co-locate tests: `user.service.ts` → `user.service.spec.ts` in same folder

---

## brain.md Update Protocol
- **On discovery (reactive):** When you find a gotcha mid-session, write to knowledge/ immediately
- **End of step (proactive):** After each `/start-step`, check: "Did I learn anything new?"
  - If yes → write to appropriate knowledge file, one-liner summary here
  - If no → move on silently
- **End of feature:** Add a one-liner summary of key insights to the "Project-Specific Insights" section

---

## MEMORY.md vs brain.md

| | `MEMORY.md` | `brain.md` |
|---|---|---|
| Location | `~/.claude/projects/.../memory/` (outside repo) | `.claude/brain.md` (inside repo) |
| Version controlled | No | Yes |
| Purpose | Claude's private reminders & user preferences | Team-wide gotchas, patterns, decisions |
| Write to it when | User expresses a preference / Claude-specific note | Anyone joining would need to know this |
