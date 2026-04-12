# Changelog

All notable changes to Claude Dev Starter Kit are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] — 2026-04-12

Lessons learned from installing the kit into two downstream projects (admin panel + background worker sharing a database). Bundles one hard bug fix (Biome config broken on current Biome versions), one enum gap (no `worker` project type), and three smaller upgrades (project name in statusline, independent multi-repo doc, `.tsbuildinfo` pre-ignored).

### Fixed

- **`biome.json` migrated to Biome 2.4 schema.** The previous config used 2.0-era keys (`files.ignore`, top-level `organizeImports`, `suspicious.noConsoleLog`, `overrides[].include`) that Biome ≥ 2.1 refuses to parse. Every new clone hit this on first `npm run lint` / `pnpm check`. The config now uses the 2.4 schema: `files.includes` with negation syntax, `assist.actions.source.organizeImports`, `suspicious.noConsole`, `overrides[].includes`. `@biomejs/biome` pin in `package.json.template.md` bumped from `2.x.x` → `^2.4.0`. Downstream users stuck on 2.0-era configs can run `npx @biomejs/biome migrate` to auto-upgrade.

### Added

- **New project type: `worker`.** For long-running Node processes (BullMQ consumers, queue runners, cron loops) with no HTTP surface. `api-only` and `cli` were both wrong fits — `api-only` implies HTTP, `cli` implies one-shot invocation. `worker` captures the actual shape: backend + queue (+ optional DB), no frontend, no `app.listen()`. Added to the enum in `PROJECT.md`, `SETUP.md`, `.claude/commands/setup-project.md` (Q3 list), and `docs/MIGRATION-FROM-EXISTING.md`.

- **New doc `docs/INDEPENDENT-MULTI-REPO.md`.** Sibling to `docs/MULTI-REPO-HUB.md`. Describes the "each repo fully independent" multi-repo pattern: per-repo `.claude/`, per-repo feature backlog (independent F-number counters), coordination only on shared runtime infra (DB schema, queue names, env vars). Sweet spot: 2–4 loosely-coupled services sharing a database or queue — admin panel + background worker + webhook handler. `MULTI-REPO-HUB.md` now has a signpost comparing the two patterns; README points at both from the renamed "Multi-Repo Variants" section.

- **Statusline shows `Project: <dirname>`.** Line 1 of `.claude/statusline/statusline.sh` now starts with a magenta-bold `Project:` indicator (basename of the git toplevel) so CLI sessions in multi-repo workspaces can tell which repo they're rooted at. Doesn't affect the VS Code extension (which doesn't render the custom statusline), but for anyone using Claude Code from a terminal it removes "wait, which repo am I in?" ambiguity.

- **`*.tsbuildinfo` pre-ignored.** Added to both the starter's own `.gitignore` and the `.gitignore` snippet in `docs/MIGRATION-FROM-EXISTING.md` Phase 1. TypeScript incremental build caches are machine-local artifacts that have no business in version control; pre-ignoring prevents the "why is my diff full of tsbuildinfo?" confusion on first `tsc` run.

### Why

All five items came from a real downstream install. The Biome breakage and the missing `worker` type were immediate papercuts that would hit anyone cloning the kit today — fixing them is a strict dependency on the kit being usable. The statusline addition and the independent multi-repo doc were lessons worth codifying: once you run two repos side-by-side you find that (a) telling them apart visually matters, and (b) the existing hub-variant doc doesn't cover the simpler pattern most real multi-repo installs actually want.

No API changes to workflow commands (`new-feature`, `start-coding`, etc.). Fully backwards-compatible for projects that cloned an older version — they keep working unchanged; pulling this version only requires the Biome migrate step if they pinned to 2.x and are on a recent install.

---

## [1.1.8] — 2026-04-12

Critical Prisma 7 migration gotcha corrected + NestJS env-loading gotcha added. Based on battle-tested knowledge from a production downstream project.

### Changed

- **Prisma migrations gotcha REPLACED.** Previous advice ("use Nx targets") was wrong for Prisma 7.x. The correct workflow is **raw `npx prisma migrate dev` from the workspace root with explicit `--schema=...` flag** — Nx targets fail because Nx changes CWD and `.env` (containing `DATABASE_URL`) is only at root. Also documents: killing idle DB connections before migrating (avoids advisory-lock timeouts), `db push` vs `migrate deploy` for test DBs.
- **Top Gotchas updated** — brain.md "Top 5" → "Top 6". Prisma entry now mentions the root + `--schema` rule, not just the "no url in datasource" change. New entry: `@nestjs/config` + `process.env`.

### Added

- **New gotcha: `@nestjs/config` does NOT populate `process.env`.** `ConfigModule.forRoot()` only makes values available via `ConfigService.get()` — code reading `process.env.FOO` directly gets `undefined`. Fix: `import 'dotenv/config'` as the FIRST import in `main.ts`. Also use bracket notation `process.env['VAR']` (esbuild-safe, dot notation can be stripped at build time). Symptom: works locally, breaks on staging.

### Why

These are both real failure modes that cost real debugging hours on a production project. The Prisma one actively contradicts what the kit previously recommended — keeping the incorrect advice would route users into the same 2-hour debugging session the downstream project went through. The env-loading gotcha is the canonical "works locally, breaks on staging" fail — worth a first-class entry.

Both gotchas are entirely project-agnostic: they apply to any Prisma 7.x + Nx monorepo and any NestJS project respectively.

---

## [1.1.7] — 2026-04-12

Makes the `/clear` + switch pattern concrete and proactive for x5 users.

### Added

- **`/start-coding` pre-flight check (x5 only)** — when invoked on Opus with `max_plan: x5`, prompts BEFORE running: "You're on Opus about to run `/start-coding ... {{STEP}}`. Implementation is pattern-following, Sonnet is ~5x cheaper. Continue on Opus anyway? [y/N]". Emphasized for `all` autopilot where savings compound per step. Skipped if already on Sonnet or if `max_plan: x20 | legacy`.
- **README "When to `/clear` + switch (x5 specifically)" sub-section** under Tier-Aware Commands with:
  - Short answer: yes, `/clear` + Sonnet + thinking off before `/start-coding all`
  - Why not mid-session (cache invalidation, thinking-block inconsistency, attention)
  - Cost math table: ~$10-20 on Opus vs ~$1-2 on Sonnet for 8-step feature
  - Exact command sequence for the transition
  - When to STAY on Opus (single step, ambiguous plan, cross-repo reasoning, debugging)
- **Enriched phase-transition reminder in `/plan-feature`** — explicit mention that `/start-coding all` is where the switch pays off most, pointing to README for cost reasoning.

### Why

v1.1.6 established the pattern but docs were mostly in the rules file. The decision about switching happens at README-discovery time and at `/start-coding`-invocation time. This patch puts the reasoning where the decision happens — in the README (discovery) and in the command itself (proactive suggestion at the exact moment of decision).

---

## [1.1.6] — 2026-04-12

Phase-based model + thinking switching for x5 Max users. x20 and legacy users are unaffected.

### Added

- **`claude.thinking_mode` field** in `PROJECT.md`. Values: `per-phase` (default for x5) / `always` (default for x20) / `never` (default for legacy) / `ask`.
- **`/setup-project` Step 3d** — asks for thinking mode preference, with defaults keyed to the chosen plan.
- **Extended `/setup-project` Step 3c** — when the user picks x5, shows a phase-based switching explainer (planning = Opus, implementation = Sonnet, transitions via `/clear` + restart).
- **New ai-workflow.md section: "Model & Thinking Switching by Phase (x5 only)"** — rule of thumb, the `/clear`-and-restart pattern, when Claude reminds the user, and when NOT to toggle mid-session (cache invalidation).
- **Phase-transition reminders** in `/new-feature`, `/discuss-feature`, `/generate-spec`, `/plan-feature`, `/plan-execution`. Each reads `claude.max_plan` from `PROJECT.md` and suggests a model switch (via `/clear` + `/resume-feature`) only if `x5` AND on the "wrong" model for the next phase.
- **README** — new "Phase-based Model + Thinking Switching" sub-section under Tier-Aware Commands; updated version-at-top line.

### Rationale

Mid-session model toggles **invalidate the prompt cache** (5-min TTL) and waste budget — the opposite of the goal. The `/clear` + restart pattern aligns with the natural phase boundary: discussion is done, save STATUS.md, clear, switch model (and thinking), reload. Phase transitions already feel like natural sessions breaks; this makes them the model-switch points too.

Thinking mode is treated as a separate question from max_plan because on x20 the user may still prefer thinking always-on or always-off independent of model. On x5, `per-phase` is the natural default (correlates with model).

### Not changing

- x20 and legacy users see no new behavior — reminders only fire for `max_plan: x5`.
- No command API changes. Every phase-transition reminder is additive output, not a behavior block.
- The Stop-for-review rules from v1.1.3 are unchanged; reminders are appended to those messages.

---

## [1.1.5] — 2026-04-12

Documentation release — overhauls README.md to describe the full usage flow and include commands that were missing from the reference table.

### Changed

- **README Commands Reference table** — adds `/generate-spec` and `/plan-execution` (the split-flow planning commands). Adds a "Planning flow choice" diagram showing when to use combined vs split. Clarifies `/complete-feature` as user-invoked-only.
- **New "Usage Flow — First Feature End-to-End" section** in README — 9-phase walkthrough with command examples, STOP markers at review gates, and explicit mentions of both planning flows (combined `/plan-feature` and split `/generate-spec` → `/plan-execution`).
- **New "Gate Map" section** — transition table showing every advance point (🛑 hard stop / ⚙️ auto / ✅ offered), plus a mental-shortcut summary.
- **Replaces the old short "How the Feature Workflow Works" section** which only showed the combined flow and omitted review gates.
- VERSION → 1.1.5.

### Why

Previous README only listed `/plan-feature` in the commands table even after 1.1.3 elevated `/generate-spec` and `/plan-execution` with their own review checkpoints. New developers reading the README couldn't discover the split flow. This fixes that and makes the full lifecycle legible without having to read multiple docs.

---

## [1.1.4] — 2026-04-12

Elevates the "update STATUS.md after every step" rule from a bullet in a list to a firm, prominent requirement. Behavior unchanged — docs clarified.

### Changed

- **`.claude/commands/start-coding.md`** — the post-step checklist (lint → test → **update STATUS.md** → commit) is now marked MANDATORY with an explicit enumeration of the STATUS.md fields to update (progress counter, current step, session-log entry with commit hash + time, last-updated date). Autopilot (`all`) repeats the same mandatory order after each step — never skips STATUS.md even in batch mode.
- Added framing: "STATUS.md is the session-resumption anchor. Skipping its update means the next session's `/resume-feature` loads a stale state. Treat the update as part of the step, not cleanup after."
- The Rules section now says: "a step that completes without a STATUS.md update is an incomplete step."
- README + CHANGELOG + VERSION → 1.1.4.

### Why

With auto-compaction, tier-aware resumption, and `/resume-feature` all depending on STATUS.md as the single source of session state, a skipped update was the cheapest-to-prevent failure mode in the system. Making it non-optional closes that gap.

---

## [1.1.3] — 2026-04-12

Adds explicit STOP-for-review checkpoints after each planning command. No auto-chaining through the planning phase — every artifact gets its own review window.

### Changed

- **`/discuss-feature`** — ends with an explicit "review 2-discussion.md" prompt, then lists both next-step options (combined `/plan-feature` for XS/S, split `/generate-spec` for M/L). No auto-advance.
- **`/generate-spec`** — ends with an explicit "review 3-spec.md" prompt. Do NOT auto-chain into `/plan-execution`. Mentions `/revise-spec` as the escape hatch if scope issues surface.
- **`/plan-execution`** — ends with an explicit "review 4-dev-plan.md" prompt. Do NOT auto-chain into `/start-coding`. Reminds user to create the feature branch before coding.
- **`.claude/rules/ai-workflow.md`** — adds a "Planning Checkpoints (Pre-Implementation Review Gates)" section with a transition table and "when to split vs combine" guidance (XS/S → combined, M/L → split).

### Why

The split planning flow (`/generate-spec` → `/plan-execution`) exists precisely to create a human review checkpoint between "design" (spec) and "execution" (dev plan). Without explicit STOPs, there was ambiguity about whether Claude should prompt-and-continue vs fully hand back control. This patch makes the STOP explicit everywhere in the planning phase — consistent with the existing rules for `/start-coding all → /complete-feature` and `/complete-feature → /create-pr`.

### Flow recap

```
Combined: /new-feature → /discuss-feature → /plan-feature → /start-coding
                              ↑                   ↑
                          2 checkpoints       good for XS/S

Split:    /new-feature → /discuss-feature → /generate-spec → /plan-execution → /start-coding
                              ↑                   ↑                ↑
                          4 checkpoints                         good for M/L
```

---

## [1.1.2] — 2026-04-12

Refinement of 1.1.1. `/complete-feature` remains user-invoked only (autopilot does NOT chain into it), but AFTER the user invokes `/complete-feature`, Claude may proactively OFFER `/create-pr` via `[y/N]` — the user's deliberate `/complete-feature` invocation is the review gate.

### Changed

- **`/complete-feature` can offer `/create-pr` with `[y/N]`.** On "yes", proceeds to `/create-pr` in the same turn. Restores the approved chain pattern. Explicit `[y/N]` prompt is required — no silent auto-forward.
- `/start-coding <name> all` autopilot **still stops** after the last step — never auto-chains to `/complete-feature`.
- `.claude/rules/ai-workflow.md` — "Manual-Only Commands" section refined: completion is the review gate, PR can be offered post-completion.

### Why the refinement

1.1.1 was over-strict. The review-gate concern is satisfied by the user's deliberate `/complete-feature` invocation; requiring them to also type `/create-pr` adds friction without added safety. The firm gate stays where it matters: between implementation (autopilot) and completion (human review).

---

## [1.1.1] — 2026-04-12

Patch release — safety guardrail around completion and PR commands. Superseded by 1.1.2's refinement.

### Changed

- `/complete-feature` and `/create-pr` marked user-invoked only. (Later relaxed in 1.1.2 to allow `/complete-feature` → `/create-pr` offer-chaining.)
- `/start-coding <name> all` autopilot stops after the last step and does not suggest in a way that could auto-continue.
- `.claude/rules/ai-workflow.md` — adds "Manual-Only Commands (Never Auto-Run)" section.

---

## [1.1.0] — 2026-04-12

First versioned release with additions from production use. Backward-compatible — no breaking changes.

### Added

- **Tier-aware command behavior.** Commands that load context (`/resume-feature`, `/trim-context`) now detect whether the running model is Opus 1M (model ID contains `1m`) or another tier (Sonnet 200k). On Opus 1M they load eagerly (full feature directory, wider budget thresholds); on Sonnet they stay lean (CONTEXT.md + STATUS.md only, tighter thresholds). Works without user configuration. See `.claude/rules/ai-workflow.md` and `.claude/knowledge/decisions.md` ADR-003.
- **Claude Max plan question in `/setup-project`.** Asks whether the user is on `x5` Max (mixed Opus/Sonnet usage) or `x20` Max (always Opus 1M). The answer is stored in `PROJECT.md` under `claude.max_plan` and used by tier-aware commands as a fallback when model-ID detection alone isn't enough.
- **Optional `.claude/knowledge/codebase-map.md` pattern.** Template at `.claude/knowledge/codebase-map.md.template` — a short always-loaded file that catalogs the top-level structure, services, and key API endpoints of the project. Useful once the codebase grows past ~20 files. Generated on demand; setup wizard flags it as opt-in after the first feature ships.
- **Multi-repo hub variant documented.** `docs/MULTI-REPO-HUB.md` explains how to adapt the workflow for projects split across multiple repos (e.g. separate frontend + backend): hub repo owns feature docs, branches named the same across repos, commits per repo per step, cross-linked PRs. This is an OPTION — the default is still single-repo/Nx monorepo. Pointer added to `docs/WORKFLOW-OPTIONS.md` and `README.md`.
- **`docs/FUTURE-ROADMAP.md`** documenting intentionally deferred additions:
  - **`/briefing [scope]`** — on-demand deep-load of all code for a subsystem, tier-aware. Deferred until the right default scope vocabulary is learned from real projects.
  - **Multi-feature mode** — load 2–3 active features simultaneously on Opus 1M. Deferred until there's empirical evidence users need it (attention quality concerns).
- **Versioning introduced.** This `CHANGELOG.md` + a plain-text `VERSION` file at the repo root. Releases are git-tagged (`v1.1.0` for this one).
- **ADRs in `.claude/knowledge/decisions.md`**:
  - ADR-003: Tier-aware command behavior.
  - ADR-004: Optional codebase-map knowledge pattern.

### Changed

- `README.md` — adds Tier-Aware Commands paragraph, pointer to `MULTI-REPO-HUB.md` + `FUTURE-ROADMAP.md`, mention of the plan-tier setup question, Changelog link.
- `.claude/rules/ai-workflow.md` — adds a "Tier Awareness" section.
- `.claude/commands/setup-project.md` — adds the plan-tier question early in the flow; persists to `PROJECT.md`.
- `.claude/commands/resume-feature.md` — tier-aware load depth.
- `.claude/commands/trim-context.md` — tier-aware budget thresholds.
- `CLAUDE.md` — references `claude.max_plan` from `PROJECT.md` during session startup.
- `PROJECT.md` — adds a `claude:` block with `max_plan` field.

### Not Changed

- Core feature workflow commands (`/new-feature`, `/discuss-feature`, `/plan-feature`, `/start-coding`, `/update-status`, `/complete-feature`, `/create-pr`) — unchanged.
- Default stack (React + Vite + NestJS + Prisma + Nx + pnpm + Biome) — unchanged.
- Rules files split across 8 files — unchanged (consolidation remains a project-by-project judgement).
- Command names — `/trim-context` kept (not renamed to `/context-audit`) for backward compat; tier-aware logic added in place.

---

## [1.0.0] — pre-2026-04-12

First public release, baselined retroactively as version 1.0.0. Content included:

- 6-phase feature workflow commands (new-feature → discuss → plan → start-coding → update-status → complete-feature → create-pr)
- Quick actions (`/quick`, `/debug`, `/scaffold`, `/review`)
- Entity commands (`/new-module`, `/new-submodule`, `/new-service`, etc.)
- Hotfix workflow (`/hotfix`, `/complete-hotfix`)
- `/setup-project` interactive wizard
- `/trim-context`, `/check-updates`, `/view-features`, `/help`
- Specialized subagents: `db-expert`, `test-writer`, `api-builder`, `ui-builder`
- Institutional memory: `brain.md`, `.claude/knowledge/{stack-gotchas.md, patterns.md, decisions.md}`
- Always-loaded rules split across 8 files
- Feature doc templates (`1-idea`, `2-discussion`, `3-spec`, `4-dev-plan`, `STATUS`, `CONTEXT`)
- Pre-commit + post-edit hooks (Biome format, Prisma generate, status reminder)
- CI/CD workflow + PR template
- Stack: React 19 + Vite 6 + NestJS 11 + Prisma 7 + Nx 20 + pnpm 10 + Better Auth 1.5 + Zod 3

---

[1.1.1]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.1
[1.1.8]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.8
[1.1.7]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.7
[1.1.6]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.6
[1.1.5]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.5
[1.1.4]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.4
[1.1.3]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.3
[1.1.2]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.2
[1.1.1]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.1
[1.1.0]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.0
