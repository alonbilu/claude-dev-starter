# Changelog

All notable changes to Claude Dev Starter Kit are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

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
[1.1.5]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.5
[1.1.4]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.4
[1.1.3]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.3
[1.1.2]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.2
[1.1.1]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.1
[1.1.0]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.0
