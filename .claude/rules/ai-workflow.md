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

**Step 3: Know your tier**
Check the running model ID. If it contains `1m` (e.g. `claude-opus-4-6[1m]`), you're on **Opus 1M** — wider context budget; tier-aware commands load eagerly. Otherwise assume **Sonnet 200k** — stay lean.

If model-ID detection is ambiguous, consult `PROJECT.md` → `claude.max_plan`:
- `x20` → user's default is Opus 1M; lean toward eager loading
- `x5` → user often switches to Sonnet; lean toward conservative loading
- `legacy` or unset → Sonnet-safe default

See "Tier Awareness" below for the full behavior table.

**Step 4: Check active features**
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

## Context Window Management

### During a step (~50-70% context used)
Run `/compact` to compress conversation history without losing key context. Continue working.

### After completing a step (~70%+ context used)
```
Context is getting full (~70%). Recommend committing this step, then starting
a fresh session for step N+1. Run /update-status [name] now.
```

### Between unrelated tasks
Run `/clear` to reset context completely. This is free — institutional memory (brain.md, rules, knowledge) reloads automatically on the next message.

### ⚠️ Before ANY context reset — Save Progress First
This applies to `/clear`, `/compact`, **and auto-compaction** (triggered automatically at ~95% context).

If there is an active feature (check brain.md → "Active Feature Work"), **always** run `/update-status [name]` before any context compression or reset.

### Two-checkpoint auto-save (active feature only)

Thresholds are configured in `PROJECT.md` → "Context Auto-Save Checkpoints" (default: 60% and 85%).

| Checkpoint | When | Action |
|------------|------|--------|
| **First save** | `first_save`% context used | Run `/update-status [name]` — early snapshot of progress |
| **Second save** | `second_save`% context used | Run `/update-status [name]` again — captures work done since first save. Suggest `/compact` or new session. |

Both checkpoints only trigger when brain.md shows an active feature. Skip silently if no feature is in progress.

After second save, tell the user:
```
Status saved ([second_save]% context used). Recommend either:
  /compact — to continue in this session
  /clear   — to start fresh (status is already saved)
```

### On user-initiated `/clear` or `/compact`
If a feature is active, save first:
```
Active feature detected: [name]. Running /update-status first to save progress.
```

**Rule of thumb:** `/compact` to squeeze more out of a session. `/clear` when switching tasks. The two-checkpoint system ensures status is always saved before auto-compaction can hit.

---

## Tier Awareness

Some commands detect the running model tier (Opus 1M vs Sonnet 200k) and branch their behavior. The design principle: **default to 200k-safe** so Sonnet sessions aren't punished; **unlock deeper loading on Opus 1M** for free when it's available.

### Detection

Primary signal: the running model ID. If it contains `1m` — treat as Opus 1M tier. Otherwise Sonnet 200k.

Secondary signal (fallback when model ID is ambiguous): `PROJECT.md` → `claude.max_plan`:
- `x20` — user's default is Opus 1M
- `x5` — user mixes Opus and Sonnet; default to the leaner path
- `legacy` or unset — Sonnet-safe

### Tier-aware commands

| Command | Sonnet 200k behavior | Opus 1M behavior |
|---------|---------------------|------------------|
| `/resume-feature` | Loads `CONTEXT.md` + `STATUS.md` + current-step section of dev plan only | Loads the full feature directory (all of `1-idea`, `2-discussion`, `3-spec`, `4-dev-plan`, `STATUS`, `CONTEXT`) |
| `/trim-context` | Budget 200k; warning at >60k baseline | Budget 1M; warning at >250k baseline |

Context auto-save thresholds (`first_save` / `second_save` in PROJECT.md) are NOT tier-aware by default — they measure percentage of current budget either way. You can set looser thresholds on Opus 1M manually if you want fewer interrupts.

### Non-tier-aware (intentional)

Core commands (`/new-feature`, `/plan-feature`, `/start-coding`, `/update-status`, etc.) don't branch on tier — their I/O patterns are the same regardless.

### When tier matters for YOU (the dev)

- If you're on `x20` Max, everything's eager loaded automatically. No action needed.
- If you're on `x5` Max, `/trim-context` reports tighter thresholds. Run it more often (monthly).
- Switching a live session Sonnet → Opus: no command state change needed; the next tier-aware command reads the new model ID and behaves accordingly.

See ADR-003 in `.claude/knowledge/decisions.md` for the rationale.

---

## Model & Thinking Switching by Phase (x5 only)

For users on the **x5 Max plan** (declared as `claude.max_plan: x5` in `PROJECT.md`), phase transitions are natural points to switch model and/or thinking mode to preserve Opus budget.

**Rule of thumb:**

| Phase | Model | Thinking | Why |
|-------|-------|----------|-----|
| `/discuss-feature`, `/generate-spec`, `/plan-feature`, `/plan-execution`, `/revise-spec` | **Opus 1M** | on | Reasoning-heavy work. Opus's quality pays for itself. |
| `/start-coding` (step-by-step or `all`) | **Sonnet 200k** | off | Pattern-following work. Sonnet is 80% as good for 20% the cost. |
| `/complete-feature`, `/create-pr`, `/update-status` | Either | Either | Mechanical; don't bother switching. |

**On x20 Max** (`max_plan: x20`) — stay on Opus 1M throughout. No switching needed; budget tolerates it.

**On legacy / no Max** (`max_plan: legacy`) — Sonnet-safe throughout. Opus may not be accessible.

### The `/clear`-and-restart pattern (recommended for x5)

Mid-session model/thinking toggles **invalidate the prompt cache** and can cost more than they save. The recommended pattern is:

```bash
/update-status <feature>    # save progress
/clear                       # reset context (phase change = fresh session anyway)
/model opus                  # or /model sonnet
# toggle thinking via UI or /thinking if applicable
/resume-feature <feature>   # reload state on new model
```

### When Claude reminds you

Tier-aware commands emit phase-transition reminders at the STOP-for-review message at the END of the previous phase:

| End of this command | Reminder fires if | Suggests |
|---------------------|-------------------|----------|
| `/new-feature` | `max_plan: x5` AND currently on Sonnet | switch to Opus before `/discuss-feature` |
| `/discuss-feature` | `max_plan: x5` AND currently on Sonnet | confirm Opus for planning |
| `/plan-feature`, `/plan-execution` | `max_plan: x5` AND currently on Opus | switch to Sonnet before `/start-coding` (via `/clear` + restart) |
| `/start-coding all` (last step) | `max_plan: x5` AND currently on Sonnet | optional switch back to Opus for review + `/complete-feature` if desired |

**Reminders follow `claude.thinking_mode`:**
- `per-phase` → reminders mention both model AND thinking mode
- `always` → reminders mention only model (keep thinking on)
- `never` → reminders mention only model (keep thinking off)
- `ask` → ask the user their thinking preference for the next phase

### When NOT to switch mid-session

Don't toggle model or thinking in the middle of a step or mid-command. Finish what you're doing, run `/update-status`, then `/clear` → switch → `/resume-feature`. Mid-session toggles waste cache.

---

## Planning Checkpoints (Pre-Implementation Review Gates)

The pre-implementation phase has several review checkpoints. After each planning command, Claude STOPS and asks the user to review before they invoke the next command. This is what makes the split planning flow worth its extra commands — each generated artifact gets its own review window.

### Two planning flows

**Combined (shortcut, faster):**
```
/new-feature → /discuss-feature → /plan-feature → /start-coding
                                        ↑ generates spec + dev plan together
```
Two review checkpoints (after discussion, after combined plan). Good for XS/S features.

**Split (safer, default for M/L):**
```
/new-feature → /discuss-feature → /generate-spec → /plan-execution → /start-coding
                                        ↑                  ↑
                                    review spec       review dev plan
```
Four review checkpoints. Worth it for anything non-trivial: new DB model, cross-repo work, risky migrations, payment/auth flows.

### The rule: STOP after each planning command — do NOT auto-chain

| Command | After running it | Next command? |
|---------|------------------|---------------|
| `/new-feature` | user fills in `1-idea.md` | `/discuss-feature` when ready |
| `/discuss-feature` | user answers questions, picks approach | `/plan-feature` OR `/generate-spec` when happy |
| `/generate-spec` | user reviews `3-spec.md` | `/plan-execution` when happy (or `/revise-spec` if off) |
| `/plan-execution` | user reviews `4-dev-plan.md` | `/start-coding` 1 when happy |
| `/plan-feature` (combined) | user reviews both `3-spec.md` + `4-dev-plan.md` | `/start-coding` 1 when happy |

The user's manual invocation of the next command IS the approval. Claude never silently advances through planning — each artifact gets its own review window.

### When to use which flow

| Feature size | Flow |
|--------------|------|
| XS (2-3 steps, 1 file) | Combined `/plan-feature` |
| S (3-5 steps, 1-2 new files, minor API) | Combined `/plan-feature` |
| M (5-8 steps, new endpoint + UI) | Split recommended |
| L (8-12 steps, new DB model, cross-cutting) | Split strongly recommended |

Not a hard rule — if discussion was thorough and the approach is obvious, combined is fine for M too. When in doubt, split.

---

## Manual-Only Commands (Review Gate — Completion & PR)

These commands control irreversible-ish actions. The rule is: **the user must invoke `/complete-feature` manually** — that's the review gate. After that gate is passed, Claude MAY offer to chain into `/create-pr` since the user's `/complete-feature` invocation already confirms review.

### The two commands

- **`/complete-feature`** — archives the feature dir, bumps versions, updates CHANGELOG(s). **User-invoked only**, never auto-chained from anywhere.
- **`/create-pr`** — opens GitHub PR(s) (public-facing, notifies reviewers, burns CI). May be offered by `/complete-feature` with a `[y/N]` prompt; may also be invoked directly by the user at any time.

### How this affects related commands

| Transition | Auto-chain? |
|------------|-------------|
| `/start-coding ... all` → `/complete-feature` | ❌ No. Autopilot STOPS. Report "all steps complete, ready for your review → run `/complete-feature` when done reviewing." |
| `/complete-feature` → `/create-pr` | ✅ Yes — but only via an explicit `[y/N]` offer. Don't skip the prompt. |
| `/start-coding ... N` (specific step) → anything | ❌ No. Report step completion, stop. |

### Why the asymmetry

- The gate between **implementation and completion** is where human review matters most. Autopilot might produce output that looks right in green checkmarks but misses an intent-level bug. `/complete-feature` = "I've read the diff, I'm happy."
- The gate between **completion and PR** is ceremonial once review has happened. Requiring a second manual command doesn't add safety; it adds friction.

Autopilot stays safe for implementation steps because each step is committed and reversible on its own. Completion + PR are protected by a single human gate.

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
