# Claude Dev Starter Kit

> A development framework for Claude Code — structured workflows, automation, and institutional memory for multi-session projects.

Stop re-explaining your stack to Claude every session. Stop repeating the same mistakes. Stop losing context between sessions. This framework pre-loads Claude with architecture rules, critical gotchas, automated hooks, specialized subagents, and a feature workflow — so every session starts at full speed.

**Current version: 1.1.7** — see [CHANGELOG.md](CHANGELOG.md). New in 1.1.x: tier-aware commands, multi-repo hub variant, `/setup-project` asks about Claude Max plan + thinking mode, `/complete-feature` user-invoked-only review gate, explicit STOP-for-review checkpoints after each planning command, firm "STATUS.md updates every completed step" rule, a full usage-flow walkthrough, phase-transition reminders for x5 users (planning = Opus, implementation = Sonnet), and a `/start-coding` pre-flight check + README cost-math for the `/clear` + switch pattern before autopilot.

---

## What Problem This Solves

When you start a new project with Claude Code, you spend the first few sessions:
- Re-explaining your stack and architecture rules
- Re-discovering gotchas you already solved in a previous project
- Rebuilding workflow conventions from scratch
- Setting up environment scripts, linting, and pre-commit hooks manually
- Manually formatting code and running generators after every edit

This framework eliminates all of that. It encodes everything needed for Claude to work well across long multi-session projects — tested on a production SaaS application over 30+ features and 100+ sessions.

---

## What's Included

### Structured Workflows
- **Feature workflow** — 6-phase lifecycle: idea → discuss → spec → plan → implement → complete → PR → merge
- **Quick actions** — `/quick`, `/debug`, `/scaffold`, `/review` for tasks that don't need the full workflow
- **Entity hierarchy** — Features, Modules, SubModules, Services for organizing work at different scales
- **Hotfix workflow** — Emergency production bug fixes with patch version bump

### Automation
- **Auto-format** — Biome runs automatically after every file edit (`.ts/.tsx/.js/.jsx`)
- **Prisma generate** — Auto-runs after `schema.prisma` edits
- **Status reminder** — Reminds to run `/update-status` at end of every session
- **Pre-commit hooks** — Husky + lint-staged auto-fix staged files on every commit

### Specialized Subagents
Claude delegates to focused agents with domain-specific context:
- **db-expert** — Prisma schema, migrations, repositories, queries
- **test-writer** — Jest tests, mocks, factories, coverage
- **api-builder** — NestJS controllers, DTOs, modules, guards
- **ui-builder** — React pages, components, forms, TanStack Query hooks

### Institutional Memory
- **`brain.md`** — always-loaded memory (≤200 lines): active work, top gotchas, insights
- **`.claude/knowledge/`** — on-demand files: `stack-gotchas.md`, `patterns.md`, `decisions.md`
- **Feature docs** — `CONTEXT.md` + `STATUS.md` per feature for cross-session continuity

### Smart Setup
- **Interactive wizard** — `/setup-project` configures stack, ports, integrations, and infra in one session
- **Stack comparison** — explains trade-offs when swapping tools (e.g., React+Vite vs Next.js)
- **Post-setup context trim** — automatically removes setup-only content from always-loaded files (~24k tokens saved)
- **Architecture decisions** — records stack choices in `decisions.md` for future reference

### CI/CD & DevOps
- **GitHub Actions CI** — lint, test (with PostgreSQL), build on every PR
- **PR template** — structured PR descriptions with checklists
- **Deploy scripts** — staging and production with safety gates and auto-rollback
- **Environment wizard** — interactive setup for dev/staging/production `.env` files

---

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 20+ |
| pnpm | 10+ |
| Docker | Latest |
| Claude Code CLI | Latest |
| gh CLI | Latest (optional, for `/create-pr`) |

**On Ubuntu 22.04+?** Install everything with one command:
```bash
bash scripts/install-prerequisites-ubuntu.sh
```

### 4 Steps

```bash
# 1. Clone the template
git clone https://github.com/alonbilu/claude-dev-starter.git my-project-name
cd my-project-name

# 2. Open Claude Code — it detects a fresh clone automatically
claude .
# Claude says: "Run /setup-project to get started"

# 3. Run the setup wizard
# /setup-project
#
# The wizard:
#   - Connects repo to your own GitHub remote
#   - Confirms or customizes your stack (defaults to React + NestJS + Prisma)
#   - Patches all config files automatically
#   - Runs pnpm install, docker compose up, initial migration

# 4. Start your first feature
/new-feature my-first-feature
```

---

## Default Stack

The framework defaults to this production-tested stack. During `/setup-project`, you can swap any tool with a compatibility-checked alternative — the wizard explains trade-offs and warns about what needs manual adjustment.

| Layer | Default | Alternatives |
|-------|---------|-------------|
| Monorepo | Nx 20 + pnpm 10 | — |
| Frontend | React 19 + Vite 6 + Tailwind v4 + Shadcn/ui | Vue, Svelte, Next.js |
| State | TanStack Query v5 + React Hook Form + Zod | SWR, Redux |
| Backend | NestJS 11 + esbuild | Express, Fastify, Hono |
| Auth | Better Auth 1.5 | NextAuth, Clerk, Supabase Auth |
| Database | Prisma 7.4 + PostgreSQL 17 | Drizzle, TypeORM, Knex |
| Validation | Zod 3 (single source of truth) | — |
| Testing | Jest + ts-jest | (**never Vitest** — breaks NestJS DI) |
| Linting | Biome 2 | (**never ESLint**) |

**Why React + Vite + NestJS over Next.js?** The default uses separated frontend/backend apps. This gives you full NestJS power (DI, guards, interceptors, queues, WebSockets) and independent scaling. Next.js is better for content/SEO-heavy sites with simple APIs. The setup wizard explains the full comparison if you consider swapping. See [`decisions.md`](.claude/knowledge/decisions.md) for the detailed architecture decision record.

The rules, gotchas, and patterns are tuned for this stack. If you swap tools, update the rules files to match.

---

## Commands Reference

### Feature Workflow (Main Path)

| Command | Purpose |
|---------|---------|
| `/new-feature [name]` | Start a new feature — capture the idea |
| `/discuss-feature [name]` | Explore approach — Claude asks questions |
| `/plan-feature [name]` | **Combined** — generate spec + dev plan in one go (best for XS/S features) |
| `/generate-spec [name]` | **Split flow** — generate spec only, STOP for review |
| `/plan-execution [name]` | **Split flow** — generate dev plan from approved spec, STOP for review |
| `/start-coding [name] N` | Implement step N — auto-updates STATUS.md after completion |
| `/start-coding [name] all` | Autopilot — runs remaining steps (hard STOPS before `/complete-feature`) |
| `/update-status [name]` | Mid-session or end-of-session status save (hook nags if skipped) |
| `/resume-feature [name]` | Resume from a previous session (tier-aware: Opus loads full dir, Sonnet loads cursor) |
| `/revise-spec [name]` | Mid-feature spec revision when requirements change |
| `/complete-feature [name]` | **User-invoked only** — archive + version bump; may offer `/create-pr` via `[y/N]` |
| `/create-pr [name]` | Create GitHub PR (or run via `/complete-feature`'s offer) |

**Planning flow choice:**

```
XS/S features:  /new-feature → /discuss-feature → /plan-feature → /start-coding
M/L features:   /new-feature → /discuss-feature → /generate-spec → /plan-execution → /start-coding
                                                       ↑                 ↑
                                                 STOP for review    STOP for review
```

See `.claude/rules/ai-workflow.md` "Planning Checkpoints" for the full table and when to use each.

### Quick Actions (No Feature Docs)

| Command | Purpose |
|---------|---------|
| `/quick [task]` | Quick fix or small change (5-15 min) |
| `/debug [error]` | Systematic debugging: reproduce → check gotchas → isolate → fix → document |
| `/scaffold [type] [name]` | Scaffold: `endpoint`, `page`, `hook`, `service`, or `domain-lib` |
| `/review` | Pre-PR self-review: lint, tests, code quality checklist |

### Entity Workflows

| Command | Purpose |
|---------|---------|
| `/new-module [name]` | Create a top-level domain module |
| `/new-submodule [parent] [name]` | Add SubModule to a Module |
| `/implement-submodule [parent] [name]` | Implement a SubModule |
| `/new-service [name]` | Create a backend service |
| `/implement-service [name]` | Implement a service |
| `/hotfix` | Start emergency production fix |
| `/complete-hotfix` | Complete hotfix with patch version bump |

### Utilities

| Command | Purpose |
|---------|---------|
| `/view-features` | See all features status |
| `/trim-context` | Clean up context window bloat |
| `/setup-project` | Initial project configuration (run once) |
| `/revise-spec [name]` | Update spec mid-feature |
| `/release-milestone` | Major/minor version bump |
| `/check-updates` | Weekly stack version check — major upgrades and security fixes |
| `/help` or `/?` | Show all commands |

### GitHub (After `/create-pr`)

```bash
gh pr view 42                    # See PR details
gh pr checks 42                  # Check CI status
gh pr review 42 --approve        # Approve
gh pr merge 42 --delete-branch   # Merge + cleanup
```

---

## Usage Flow — First Feature End-to-End

Once `/setup-project` has configured the kit (see [Quick Start](#quick-start) above), here's what using it actually looks like from a developer's perspective.

### Phase 1 — Capture the idea

```
/new-feature google-oauth
```

Claude creates `docs/features/active/F001-google-oauth/1-idea.md` with a template. **STOP — your turn.** You edit the file (problem, user stories, success criteria, complexity estimate), save, tell Claude you're done.

### Phase 2 — Discuss

```
/discuss-feature google-oauth
```

Claude reads your idea and creates `2-discussion.md` with its paraphrased understanding, clarifying questions, and 2-3 proposed approaches with tradeoffs. **STOP — your turn.** Answer questions, pick an approach, update the doc.

When discussion is complete, Claude prompts:

> 📝 Discussion captured. Review 2-discussion.md yourself. When happy, run ONE of:
> - `/plan-feature google-oauth` — combined spec + dev plan (faster, best for XS/S)
> - `/generate-spec google-oauth` — spec only, then review before `/plan-execution` (safer for M/L)

### Phase 3 — Plan (choose: combined or split)

**Combined (XS/S features):**

```
/plan-feature google-oauth
```

Claude generates `3-spec.md` + `4-dev-plan.md` + `STATUS.md` + `CONTEXT.md` back-to-back. You review both artifacts before `/start-coding`.

**Split (M/L features — recommended for non-trivial work):**

```
/generate-spec google-oauth
```
Claude creates `3-spec.md` (requirements, schema, API, UI, validation, tests, acceptance criteria). **🛑 HARD STOP** — Claude asks you to review before continuing.

You read the spec, fix anything off. Then:

```
/plan-execution google-oauth
```

Claude creates `4-dev-plan.md` (atomic steps) + `STATUS.md` + `CONTEXT.md`. **🛑 HARD STOP** — review the plan, verify step ordering and "done when" criteria. Create the feature branch:

```bash
git switch -c feature/F001-google-oauth
```

### Phase 4 — Implement

**Step-by-step (cautious, default):**

```
/start-coding google-oauth 1
# Claude implements → lint/test → updates STATUS.md → commits → STOPS
# You review the diff
/start-coding google-oauth 2
```

**Autopilot (faster, once you trust the plan):**

```
/start-coding google-oauth all
```

Claude runs every remaining step; after each it runs lint → test → **updates STATUS.md** → commits. **🛑 After the last step, HARD STOP** — Claude reports:

> All N steps complete, ready for your review. Run `/complete-feature google-oauth` when you've reviewed the work.

> **STATUS.md is updated automatically after every completed step** — never skipped, even in autopilot. This is what makes `/resume-feature` work in the next session.

### Phase 5 — Save progress (if pausing)

```
/update-status google-oauth
```

Always before ending a session with active feature work. The Stop hook will nag if you forget.

### Phase 6 — Resume later (new session)

```
/resume-feature google-oauth
```

**Tier-aware:** on Opus 1M, Claude reads the full feature directory; on Sonnet 200k, it reads `CONTEXT.md` + `STATUS.md` + the current step's section. Continue with `/start-coding google-oauth N`.

### Phase 7 — The review gate (user-invoked)

After personally reviewing the diffs, running the feature, testing in a browser:

```
/complete-feature google-oauth
```

Claude verifies all steps ✅, bumps version, updates CHANGELOG, archives the feature dir, commits. **Then offers:**

> Feature complete and archived. Ready to open a PR now?
> Open PR? **[y/N]**

### Phase 8 — PR

**From the offer:** answer `y` → Claude runs `/create-pr` in the same turn.

**Later, manually:**

```
/create-pr google-oauth
```

### Phase 9 — GitHub (your terminal)

```bash
gh pr view 42
gh pr checks 42
gh pr review 42 --approve
gh pr merge 42 --delete-branch
```

---

## The Gate Map

Where Claude hands control back to you (HARD STOP) vs auto-advances:

| Transition | Advance? |
|------------|----------|
| `/new-feature` → `/discuss-feature` | 🛑 you invoke after editing `1-idea.md` |
| `/discuss-feature` → `/plan-feature` OR `/generate-spec` | 🛑 you invoke after reviewing `2-discussion.md` |
| `/generate-spec` → `/plan-execution` | 🛑 you invoke after reviewing `3-spec.md` |
| `/plan-execution` → `/start-coding 1` | 🛑 you invoke after reviewing `4-dev-plan.md` |
| `/plan-feature` → `/start-coding 1` | 🛑 you invoke after reviewing both artifacts |
| `/start-coding N` → `/start-coding N+1` | ⚙️ auto (between step commits) OR step-by-step stops between each |
| `/start-coding all` → `/complete-feature` | 🛑 **hard stop**, Claude reports; you invoke after reviewing implementation |
| `/complete-feature` → `/create-pr` | ✅ **offered `[y/N]`** — explicit prompt, you choose |
| `/create-pr` → merged | 🛑 you run `gh pr merge` |

**Two firm gates**: planning artifacts (each one), and autopilot-finished → completion. **One soft gate**: completion → PR (explicit offer).

### Mental shortcut

> **Planning phase** = every command is a pause-for-review. You invoke the next one.
>
> **Implementation phase** = autopilot through reversible committed steps. STATUS.md auto-updates after each step.
>
> **Completion phase** = one firm user gate (`/complete-feature`), then an offered `[y/N]` for the PR.

---

## Sizing & Timings

**Step sizing:** XS (2-3 steps), S (3-5), M (5-8), L (8-12) — Claude sizes automatically based on the spec's complexity.

**Session resumption cost:**
- Opus 1M: ~40-60k tokens (full feature dir)
- Sonnet 200k: ~15-20k tokens (CONTEXT + STATUS + current step)

**Multi-session continuity:** `/update-status` at end of every session + automatic STATUS.md updates after each step = 10+ session features work without losing context.

---

## Entity Hierarchy

The framework supports different organizational units for different scales of work:

| Entity | When to Use | Commands |
|--------|-------------|----------|
| **Feature** | User-facing capability (API + UI + DB) | `/new-feature` → `/plan-feature` → `/start-coding` |
| **Module** | Top-level domain area (users, billing, notifications) | `/new-module` → then add SubModules |
| **SubModule** | Feature within a bounded domain | `/new-submodule` → `/implement-submodule` |
| **Service** | Backend-only process (queue worker, webhook, sync) | `/new-service` → `/implement-service` |

**Most projects:** Start with `/new-feature` for everything. Graduate to Modules/SubModules only when you have 5+ features in the same domain.

See [`docs/WORKFLOW-OPTIONS.md`](docs/WORKFLOW-OPTIONS.md) and [`docs/ENTITY-CLASSIFICATION.md`](docs/ENTITY-CLASSIFICATION.md) for detailed decision trees.

---

## Built-In Automation

| Automation | Trigger | What it does |
|-----------|---------|-------------|
| **Auto-format** | Every file edit (`.ts/.tsx/.js/.jsx`) | Runs Biome auto-fix on the changed file |
| **Prisma generate** | Editing `schema.prisma` | Auto-runs `pnpm nx run database:generate` |
| **Status reminder** | End of session | Reminds to run `/update-status` if active feature exists |
| **Auto-save before compaction** | Context ~60% used | Proactively saves feature status before auto-compaction can erase unsaved progress |
| **Pre-commit** | Every `git commit` | Auto-fixes staged files with Biome |

These are configured as Claude Code hooks in `.claude/settings.json` — no manual setup needed.

---

## The 7 Commandments

Encoded in `CLAUDE.md` and enforced by rules files:

1. **Search before creating** — check for existing code before writing anything new
2. **Write for reuse** — build generically, put shared code in `libs/shared/` from day one
3. **Zod is truth** — all types as Zod schemas; same schema for API, forms, seeding
4. **No logic in controllers** — controllers are HTTP plumbing; logic in `libs/domain/`
5. **One mission per session** — complete one step before switching; `/update-status` at end
6. **Never defer type changes** — schema changes propagate to all targets in the same session
7. **Always use `gh` CLI** — GitHub CLI for all GitHub operations

---

## Context Budget

Always-loaded files cost ~47k tokens per session. Tier-aware commands (v1.1.0+) decide on **load depth per-tier**:

| Tier | Budget | Baseline | Usage |
|------|--------|----------|-------|
| Opus 1M | 1,000,000 | ~47k | ~4.7% |
| Sonnet 200k | 200,000 | ~47k | ~23% |

| Files | Tokens |
|-------|--------|
| CLAUDE.md + PROJECT.md | ~5.5k |
| .claude/brain.md | ~1.5k |
| .claude/rules/ (8 files) | ~40k |
| **Total baseline** | **~47k** |

Commands, knowledge files, and agents are loaded on-demand only — keeping the baseline lean.

**Post-setup trim:** After `/setup-project` completes, the wizard automatically removes setup-only content from always-loaded files (~2k tokens), deletes SETUP.md (~14k tokens), and removes the setup command itself (~8k tokens) — saving ~24k tokens total. This is automatic — no manual work needed.

Run `/trim-context` every few weeks (monthly on Sonnet, quarterly on Opus 1M) to prevent growth over time. `/trim-context` reports against your current tier's budget automatically.

---

## Tier-Aware Commands

Some commands detect the running model tier (Opus 1M vs Sonnet 200k) and adjust their behavior:

| Command | Sonnet 200k | Opus 1M |
|---------|-------------|---------|
| `/resume-feature` | Loads `CONTEXT.md` + `STATUS.md` + current-step section | Loads the full feature directory |
| `/trim-context` | Budget 200k, warn at >60k baseline | Budget 1M, warn at >250k baseline |

**Detection:** commands check if the running model ID contains `1m` (e.g. `claude-opus-4-6[1m]`). If yes → Opus 1M. Otherwise Sonnet-safe.

**Fallback:** if the model ID is ambiguous, commands read `PROJECT.md` → `claude.max_plan`:
- `x20` → default Opus 1M behavior
- `x5` → default Sonnet-safe (lean), upgrade when Opus is detected
- `legacy` / unset → Sonnet-safe

`/setup-project` asks for `max_plan` once during configuration. See ADR-003 in `.claude/knowledge/decisions.md`.

### Phase-based Model + Thinking Switching (x5 only)

For users on **x5 Max**, planning and implementation have different cost profiles:

| Phase | Model | Thinking | Why |
|-------|-------|----------|-----|
| `/discuss-feature`, `/generate-spec`, `/plan-feature`, `/plan-execution` | **Opus 1M** | on | Reasoning-heavy work |
| `/start-coding` (step or `all`) | **Sonnet 200k** | off | Pattern-following |
| `/complete-feature`, `/create-pr` | Either | Either | Mechanical |

Claude reminds you at the end of each phase's last command (e.g. at the end of `/plan-execution` before `/start-coding`). The recommended switch pattern is **`/clear` + restart**, not mid-session toggle — mid-session toggles invalidate the prompt cache:

```
/update-status <feature>      # save progress
/clear                         # fresh context (phase change = new session)
/model sonnet                  # or opus
/resume-feature <feature>      # reload state on new model
```

**x20 Max** users: stay on Opus 1M throughout. No switching needed.
**Legacy / no Max** users: Sonnet-safe throughout.

`/setup-project` also asks for your **thinking mode** preference (`per-phase` / `always` / `never` / `ask`) — stored alongside `max_plan` in `PROJECT.md`. See `.claude/rules/ai-workflow.md` "Model & Thinking Switching by Phase" for the full rule.

### When to `/clear` + switch (x5 specifically)

**Short answer:** yes, `/clear` + switch to Sonnet + thinking off before `/start-coding all`. Don't toggle model mid-session.

**Why not mid-session:**
- Prompt cache (5-min TTL, ~47k always-loaded tokens) is **model-specific**. Switching models invalidates the cache; next turn reads uncached.
- Extended thinking blocks from prior turns remain in context after you turn thinking off — behavior gets inconsistent.
- At long context on Opus 1M, attention quality softens; mid-session toggles add oddness without reducing context.

**Cost math for `/start-coding all` on an 8-step feature:**

| Mode | Per step | Rough total | Context at end |
|------|---------|-------------|----------------|
| Stay on Opus 1M + thinking on | ~$1-2 (input+thinking+output) | **~$10-20** | 200-400k, risk of auto-compact |
| `/clear` + Sonnet + thinking off | ~$0.10-0.20 | **~$1-2** | Comfortably lean |

One transition (`/update-status` + `/clear` + `/resume-feature`) costs ~15k tokens at Sonnet rates. That's recouped after the first 1-2 steps of savings; on `all` autopilot it's paid off many times over.

**The recommended sequence before `/start-coding all`:**

```
/update-status <feature>     # save STATUS.md — this is your reversible point
/clear                        # drop cached Opus context
/model sonnet                 # switch
# thinking OFF (via UI or settings) — per-phase mode
/resume-feature <feature>    # reload state on Sonnet
/start-coding <feature> all
```

**When to STAY on Opus (not switch):**
- Single step only (`/start-coding 1`) — one step isn't worth the transition overhead
- Plan has known ambiguities or judgment calls — keep the reasoning power
- First feature on the kit — pay for Opus to confirm autopilot behaves before trusting Sonnet
- You're on x20 — the cost arithmetic doesn't apply
- Currently debugging a tricky step

`/start-coding` itself will **pre-flight check** on x5: if you invoke it while on Opus (especially with `all`), it suggests the switch BEFORE running and asks "continue on Opus anyway? [y/N]".

---

## Multi-Repo Hub Variant

Default: one repo (typically Nx monorepo). If your project is split across multiple repos (e.g. separate FE + BE), see [`docs/MULTI-REPO-HUB.md`](docs/MULTI-REPO-HUB.md) for the hub-model variant: one repo owns feature docs, same branch names across repos, per-step repo targeting, cross-linked PRs.

---

## Deferred Features (Roadmap)

See [`docs/FUTURE-ROADMAP.md`](docs/FUTURE-ROADMAP.md). Currently deferred:

- **`/briefing <scope>`** — on-demand deep-load of all code for a subsystem, tier-aware
- **Multi-feature mode** — load 2–3 active features simultaneously on Opus 1M

Each includes a DIY guide if you need to implement early for your own project.

---

## Repository Structure

```
claude-dev-starter/
├── CLAUDE.md                        ← Claude's session instructions (always loaded)
├── PROJECT.md                       ← Project identity (configure via /setup-project)
│
├── .claude/
│   ├── brain.md                     ← Institutional memory (≤200 lines)
│   ├── settings.json                ← Permissions, hooks, statusline
│   ├── commands/                    ← Workflow commands (on-demand)
│   │   ├── new-feature.md           ← /new-feature
│   │   ├── discuss-feature.md       ← /discuss-feature
│   │   ├── plan-feature.md          ← /plan-feature
│   │   ├── start-coding.md          ← /start-coding
│   │   ├── quick.md                 ← /quick (lightweight tasks)
│   │   ├── debug.md                 ← /debug (systematic debugging)
│   │   ├── scaffold.md              ← /scaffold (boilerplate generation)
│   │   ├── review.md                ← /review (pre-PR self-review)
│   │   ├── new-module.md            ← /new-module (domain modules)
│   │   └── ...                      ← 20+ more commands
│   ├── agents/                      ← Specialized subagents
│   │   ├── db-expert.md             ← Prisma, migrations, queries
│   │   ├── test-writer.md           ← Jest tests, mocks, coverage
│   │   ├── api-builder.md           ← NestJS controllers, DTOs
│   │   └── ui-builder.md            ← React, TanStack Query, forms
│   ├── hooks/                       ← Automation scripts
│   │   ├── biome-format.sh          ← Auto-format after edits
│   │   ├── prisma-generate.sh       ← Auto-generate after schema changes
│   │   └── status-reminder.sh       ← End-of-session reminder
│   ├── knowledge/                   ← On-demand reference (not always loaded)
│   │   ├── stack-gotchas.md         ← Critical pitfalls with fixes
│   │   ├── patterns.md              ← Reusable code patterns
│   │   └── decisions.md             ← Architecture decision log
│   └── rules/                       ← Always loaded (referenced in CLAUDE.md)
│       ├── architecture.md          ← Layering, reuse, import boundaries
│       ├── api.md                   ← NestJS, Better Auth, validation
│       ├── database.md              ← Prisma 7, migrations, gotchas
│       ├── frontend.md              ← React, TanStack Query, forms
│       ├── testing.md               ← Jest setup, coverage requirements
│       ├── code-quality.md          ← Biome, lint-staged, conventions
│       ├── deployment.md            ← Docker, environments, deploy scripts
│       └── ai-workflow.md           ← Feature workflow, brain.md protocol
│
├── .github/
│   ├── workflows/ci.yml             ← CI: lint, test, build on every PR
│   └── pull_request_template.md     ← Structured PR template
│
├── docs/
│   ├── WORKFLOW-GUIDE.md            ← Step-by-step walkthrough
│   ├── WORKFLOW-OPTIONS.md          ← Features vs Services vs Modules
│   ├── ENTITY-CLASSIFICATION.md     ← Entity hierarchy guide
│   ├── GITHUB-WORKFLOW.md           ← PR review & merge operations
│   ├── GITHUB-CLI-REFERENCE.md      ← gh CLI command reference
│   ├── MIGRATION-FROM-EXISTING.md   ← Adopting in existing projects
│   └── templates/feature/           ← Feature document templates
│
├── scripts/
│   ├── setup-env.sh                 ← Env file wizard
│   ├── validate-setup.sh            ← Setup verification
│   ├── dev.sh                       ← Development orchestrator
│   ├── staging-deploy.sh            ← Staging deploy
│   ├── production-deploy.sh         ← Production deploy + rollback
│   └── trim-context.sh              ← Context audit + cleanup
│
├── docker-compose.yml               ← PostgreSQL + Redis
├── biome.json                       ← Linting + formatting
└── .env.example                     ← All env vars documented
```

---

## Critical Gotchas (Top 5)

Full details in `.claude/knowledge/stack-gotchas.md`:

| Gotcha | Fix |
|--------|-----|
| NestJS DI injects `undefined` | Never `import type` for services; always `import { Service }` |
| esbuild strips decorator metadata | Always `@Inject(Service)` on every constructor param |
| NestJS tests fail with Vitest | Use Jest only — Vitest doesn't preserve `emitDecoratorMetadata` |
| Prisma 7 datasource error | Remove `url = env(...)` from datasource block |
| lint-staged stash lost | NEVER `git stash drop` after a failed pre-commit hook |

---

## Power User Tips

| Technique | When | What it does |
|-----------|------|-------------|
| `/clear` | Between unrelated tasks | Resets context completely. Rules + brain.md reload automatically. |
| `/compact` | Mid-session, context heavy | Compresses conversation history so you can keep working. |
| Parallel sessions | Large features | Run separate Claude Code instances for DB/API and frontend work. Each loads the same rules independently. |
| `/start-coding [name] all` | Confident in the plan | Autopilot mode — implements all remaining steps with auto-commit between each. |
| `/trim-context` | Monthly | Audits and archives stale docs to keep context lean. |

**Context window lifecycle:** Start session (~47k baseline) → work → auto-saves status at ~60% → `/compact` when heavy → `/clear` when switching tasks → `/update-status` before ending.

**Auto-compaction protection:** Claude Code auto-compacts at ~26k tokens remaining. The framework proactively saves feature status at ~60% context usage so nothing is lost when that happens.

---

## Adapting to Your Stack

The workflow system (features, brain.md, knowledge/, agents) is stack-agnostic. Only rules files and gotchas are stack-specific.

1. Run `/setup-project` — confirm or swap stack tools during setup
2. Update `.claude/rules/*.md` for your tech choices
3. Replace `.claude/knowledge/stack-gotchas.md` with your stack's gotchas
4. Update `.claude/agents/*.md` for your frameworks
5. See [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) for detailed guidance

---

## Migrating an Existing Project

If you have an existing project:

1. **Read** [`docs/MIGRATION-FROM-EXISTING.md`](docs/MIGRATION-FROM-EXISTING.md) — 5-phase incremental adoption
2. Copy the files you want, customize rules for your stack
3. Start with the workflow commands (`/new-feature`) and institutional memory (`brain.md`) — adopt the rest gradually

---

## Contributing

Issues and PRs welcome. When contributing:
- Keep `CLAUDE.md` generic — no framework-specific rules that don't apply to all project types
- Add stack-specific gotchas to `.claude/knowledge/stack-gotchas.md`
- Test workflow commands end-to-end before submitting
- Keep `brain.md` under 200 lines
- Maintain zero impact on always-loaded context budget

---

## License

MIT — use freely, no attribution required.
