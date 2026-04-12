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
| Built-in hooks (auto-format, prisma, status) | `.claude/hooks/` |
| Specialized subagents (db, test, api, ui) | `.claude/agents/` |

---

## Top 6 Gotchas (Always Remember)

1. **NEVER `import type` for NestJS injectables** — erased at runtime, DI breaks silently
2. **Always `@Inject(Service)` explicitly** — esbuild strips decorator metadata inconsistently
3. **Never Vitest for API** — breaks NestJS DI (`emitDecoratorMetadata` not preserved)
4. **Never `git stash drop` after failed lint-staged** — you lose all working changes
5. **Prisma 7.x migrations run from workspace ROOT with `--schema` flag, NEVER via Nx targets** — no `url = env(...)` in datasource; Nx changes CWD which breaks `.env` lookup. Kill idle DB connections first.
6. **`@nestjs/config` does NOT populate `process.env`** — add `import 'dotenv/config'` as FIRST import in `main.ts`. Use bracket notation `process.env['VAR']` (esbuild-safe).

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

- **Custom statusline configured** — Shows context window %, cache efficiency, branch, session duration. Auto-configured in all clones. (`.claude/statusline/statusline.sh`)

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
- **End of step (proactive):** After each `/start-coding`, check: "Did I learn anything new?"
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
