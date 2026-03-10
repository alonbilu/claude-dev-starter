# AI Workflow (Claude Code Protocol)

Rules for how Claude Code operates in this project.

---

## At the Start of Every Session

**Step 1: Check for unconfigured project**
Read `PROJECT.md`. If `APP_NAME` is still `YOUR_APP_NAME` or the project type is the template default
with no customization, say:
```
This looks like a freshly cloned template. Run /setup-project to configure it for your project —
I'll walk you through it interactively and set everything up automatically.
```

**Step 2: Read institutional memory**
Read `.claude/brain.md` before doing anything else. Note:
- Any active feature work
- Known gotchas relevant to today's task
- Recent architectural decisions

**Step 3: Check active features**
```bash
/view-features   # or check docs/FEATURE-STATUS.md
```

---

## ⚠️ CRITICAL: Search Before Creating

**ALWAYS search before writing new code.**

```bash
# Search for similar services / functions
grep -r "functionName" libs/

# Browse existing libs
ls libs/shared/ libs/domain/ libs/backend/

# Visualize the whole dependency graph
pnpm nx graph
```

Code duplication is a defect. If you write something that resembles existing code, stop and find
the existing implementation. The second instance should be an import, not a copy.

---

## Feature Development Workflow

### Core Principle: Features First, Entities Second

**Work on FEATURES, not entities directly.**
- **Feature** = user-facing capability ("Add OAuth login", "Export to PDF")
- **Entity** = architectural component created BY features (a new service, a new module)

### The 5-Phase Workflow

```
PHASE 1: IDEA (main branch)
  /new-feature [name]
  → Creates docs/features/active/F[XXX]-[name]/1-idea.md
  → User fills in the idea document

PHASE 2: DISCUSSION (main branch)
  /discuss-feature [name]
  → Claude reads 1-idea.md, creates 2-discussion.md
  → Asks clarifying questions, proposes 2-3 approaches
  → User fills in answers
  → Discussion verification: Claude re-reads answers, checks for gaps
  → Confirms: "Ready to generate spec. Run /plan-feature [name]."

PHASE 3: SPEC + DEV PLAN (main branch)
  /plan-feature [name]
  → Generates 3-spec.md (schema, API, frontend, testing...)
  → Assesses complexity (XS/S/M/L) → determines step count
  → Generates 4-dev-plan.md with dynamic step count
  → Creates STATUS.md + CONTEXT.md
  → Offers to create the feature branch

PHASE 4a: STEP-BY-STEP IMPLEMENTATION (feature branch)
  /start-coding [name] N
  → Implements one step
  → After each step: "Commit and push before we continue"

PHASE 4b: AUTOPILOT IMPLEMENTATION (feature branch)
  /start-coding [name] all
  → Implements ALL remaining steps automatically
  → Auto-commits + pushes between each step
  → Stops and reports if a step fails

PHASE 5: COMPLETION
  /complete-feature [name]
  → Validates all steps done
  → Archives feature docs
  → Bumps version, updates CHANGELOG
  → Prepares final commit message
  /create-pr
  → Creates PR with auto-generated description
```

### Git Branching — Manual Only

Workflow commands create **documentation files only** — they do NOT create branches.

| Phase | Branch | Claude action |
|-------|--------|---------------|
| idea → spec → plan | `main` | (just docs, safe) |
| After /plan-feature | → | Offers to create `feature/F[XXX]-[name]` |
| During implementation | `feature/...` | Reminds to commit after each step |
| Autopilot | `feature/...` | Auto-commits + pushes |
| After completion | `feature/...` | Reminds to create PR |

---

## Dynamic Step Sizing

| Size | When | Steps | Token budget/step |
|------|------|-------|-------------------|
| XS | ≤3 files, no schema change | 2–3 | ~60k |
| S | ≤6 files, single domain | 3–5 | ~50k |
| M | New lib OR schema change | 5–8 | ~40k |
| L | Multiple new libs OR major UI + backend | 8–12 | ~35k |

**Step format in dev plan:**
```markdown
## Step N: [Title]

**Complexity:** S
**Reads:** path/to/file.ts (~Nk tokens)
**Writes:** path/to/new-service.ts (new), path/to/new-service.spec.ts (new)
**Done when:** Service created, N tests pass, lint clean
**Commit message:** `feat(scope): description (F[XXX] step N/Total)`
```

---

## CONTEXT.md per Feature

Each feature gets a `CONTEXT.md` — a 1-page quick-load file for session resumption:

```markdown
# F[XXX] Context — [Feature Name]

## What we're building
One sentence.

## Key decisions
- Decision 1 (why)
- Decision 2 (why)

## Files that matter most
- `path/to/service.ts` — the core service
- `path/to/schema.prisma` — new table: FeatureXxx

## Current state
Step N of M complete. Next: [description of next step]

## Acceptance criteria
- [ ] User can do X
- [ ] API returns Y
- [ ] Tests cover Z
```

`/resume-feature [name]` loads: CONTEXT.md + STATUS.md + current step ≈ 15–20k tokens.

---

## Insight Writing (Two-Way brain.md)

### On-discovery (reactive):
When you find a gotcha or learn a reusable pattern mid-session:
1. Write to the appropriate knowledge file immediately
2. Add a one-liner to brain.md linking to the full detail
3. Continue working without prompting the user

### End-of-step (proactive):
After each `/start-coding` and `/update-status`:
1. Review what was just implemented
2. Ask: "Did I learn anything not already in brain.md or MEMORY.md?"
3. If yes → write immediately, mention briefly: `[Added to stack-gotchas.md: ...]`
4. If no → move on silently

---

## Context Window Awareness

After completing each step, estimate context usage. If approaching ~70% used:
```
Context is getting full (~70%). Recommend committing this step, then starting
a fresh session for step N+1. Run /update-status [name] now.
```

---

## One Mission Per Session

Complete ONE feature step (or one focused task) before switching to anything else.
If a refactor or unrelated fix is needed, finish the current task first, then ask.

---

## Commit Message Format

```
feat(scope): description (F[XXX] step N/Total)
fix(scope): description (hotfix)
chore: complete F[XXX] [name] (vX.Y.Z)

Examples:
feat(users): add email verification endpoint (F003 step 4/6)
feat(billing): implement webhook signature validation (F007 step 2/5)
chore: complete F003 email-verification (v1.2.0)
```

---

## Testing — Mandatory at Each Step

1. Implement code
2. Write tests immediately
3. Run: `pnpm nx test [project] --watch`
4. Mark step complete ONLY when tests pass
5. Also run: `pnpm nx lint [project]` and `pnpm nx build [project]`

**Coverage minimums:**
| Layer | Minimum |
|-------|---------|
| `libs/domain/*` services | 70% |
| `libs/domain/database/repositories/` | 80% |
| `libs/shared/utils/` | 80% |
| `libs/backend/*` | 60% |
| Controllers | Not required |

---

## Zod Schema Changes = Immediate Propagation

When ANY Zod schema in `libs/shared/types` changes, update ALL of these in the SAME session:

1. Zod schema (`libs/shared/types/`)
2. Prisma schema (`libs/domain/database/prisma/schema.prisma`)
3. Generate migration (`pnpm nx run database:migrate:dev --name [name]`)
4. Backend DTOs (`apps/api/src/app/[feature]/dto/`)
5. Domain services (handle new field)
6. Frontend forms/queries
7. Seed data
8. Run all tests

**NEVER defer any step to "later session" — this creates type drift.**

---

## Before Marking Any Step Complete

- [ ] Code compiles (`pnpm nx build [project]`)
- [ ] Linting passes (`pnpm nx lint [project]`)
- [ ] Tests pass (`pnpm nx test [project]`)
- [ ] No import boundary violations
- [ ] No duplicate code created — searched before writing
- [ ] All types imported from shared types lib
- [ ] STATUS.md updated

---

## Quick Actions (Lightweight Alternatives)

Not everything needs the full feature workflow. Use these for small tasks:

| Command | When to use | Creates docs? |
|---------|-------------|---------------|
| `/quick [task]` | Small fix, 5-15 min, <5 files | No |
| `/debug [error]` | Debugging an error systematically | No (but may update stack-gotchas.md) |
| `/scaffold [type] [name]` | Generate boilerplate (endpoint, page, hook, service, domain-lib) | No |

**Scope guard:** If a `/quick` task grows beyond 15 minutes or needs a new DB table, stop and suggest `/new-feature` instead.

---

## Module Workflow

For projects with explicit domain boundaries:

```
/new-module [name]                    # Create top-level domain module
/new-submodule [parent] [name]        # Add SubModule to a Module
/implement-submodule [parent] [name]  # Implement the SubModule
```

Modules are created when a new bounded context emerges. SubModules are capabilities within a Module.

---

## Automation & Subagents

### Built-In Hooks (Automatic — No User Action Required)

| Hook | Trigger | Action |
|------|---------|--------|
| biome-format | Write/Edit on `.ts/.tsx/.js/.jsx` | Auto-runs `biome check --write` |
| prisma-generate | Write/Edit on `schema.prisma` | Auto-runs `pnpm nx run database:generate` |
| status-reminder | Session end | Reminds to run `/update-status` if active feature exists |

### Specialized Subagents (Automatic Delegation)

Claude delegates to focused agents based on task context:

| Agent | Loads | When triggered |
|-------|-------|----------------|
| **db-expert** | database.md + Prisma gotchas | Schema changes, migrations, repositories |
| **test-writer** | testing.md + test gotchas | Writing or fixing tests |
| **api-builder** | api.md + NestJS gotchas | Creating controllers, DTOs, modules |
| **ui-builder** | frontend.md + React gotchas | Creating pages, components, forms |

You don't invoke these manually — Claude uses them automatically for better output quality and context efficiency.
