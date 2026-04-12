# Multi-Repo Hub — Workflow Variant

The default starter-kit workflow assumes a single repo (typically an Nx monorepo with `apps/` + `libs/`). If your project is split across **multiple repos** — for example, separate frontend and backend — this guide adapts the workflow without giving up the feature-tracking discipline.

This is an OPTION, not a default. Use it only if you already have split repos and a monorepo migration isn't on the table.

---

## The Model

Designate **one repo as the hub.** The hub owns:

- `docs/features/active/` + `docs/features/archive/` — feature spec, dev plan, STATUS.md, CONTEXT.md
- `brain.md`, `.claude/rules/`, `.claude/knowledge/`, `.claude/commands/` — workflow commands + always-loaded context
- Everything else in `.claude/`

Every other repo in the project gets a lightweight `.claude/` subset — rules, hooks, knowledge — but **no workflow commands.** Feature lifecycle happens in the hub; only code lives in the non-hub repos.

### Which repo is the hub?

Pick the one you work in most. For a FE + BE split where the FE drives the user experience and BE is "just an API," the FE repo is usually the better hub. For an API-first product with a thin client, the BE might be the hub. No fixed rule — consistency matters more than the choice.

---

## Repo Layout Example

```
my-project/
├── my-project-web/          ← HUB: frontend + feature tracking
│   ├── .claude/
│   │   ├── commands/        ← ALL workflow commands live here
│   │   ├── agents/
│   │   ├── hooks/
│   │   ├── knowledge/
│   │   ├── rules/
│   │   └── settings.json
│   ├── brain.md
│   ├── docs/
│   │   ├── features/active/
│   │   ├── features/archive/
│   │   ├── templates/feature/
│   │   └── WORKFLOW-GUIDE.md
│   └── src/                 ← frontend code
│
├── my-project-api/          ← backend (no feature-workflow commands)
│   ├── .claude/
│   │   ├── hooks/           ← e.g. biome-format.sh, prisma-generate.sh
│   │   ├── knowledge/       ← backend-specific gotchas
│   │   ├── rules/           ← backend.md + tier-aware ai-workflow.md subset
│   │   └── settings.json    ← hooks + permissions only
│   ├── CLAUDE.md            ← short instructions, points at the hub for workflow
│   └── src/                 ← backend code
│
└── my-project-legacy/       ← optional: read-only reference repo
    └── (never modify)
```

---

## Branch Strategy

For any feature that spans multiple repos, **use the same branch name in every repo involved:**

```bash
# Hub
git switch -c feature/F042-my-feature

# Other repo(s)
(cd ../my-project-api && git switch -c feature/F042-my-feature)
```

The matching name is what lets `/sync-repos` (see below) detect branch state across repos, and what lets reviewers match PRs.

Single-repo features only need a branch in the target repo. The feature doc still lives in the hub.

---

## Dev Plan Changes

The `4-dev-plan.md` template should declare a **target repo per step:**

```markdown
### Step 1: Add Prisma model + migration

- **Goal:** Add `PromoCode` model with code + discount + expiry
- **Repo:** `my-project-api`   ← EXPLICIT per step
- **Files:** prisma/schema.prisma, prisma/migrations/
- **Done when:** migration generated + applied, `prisma generate` regenerates client
- **Commit message:** `feat(F042): step 1 — add PromoCode model`
```

**Rule:** every step targets exactly ONE repo. A step that touches both is a code smell — split it.

Your `/start-coding` command should:

1. Read the step's `Repo:` field
2. `cd` to that repo (or run subcommands via `(cd <repo> && ...)` from the hub)
3. Ensure the feature branch is checked out there
4. Implement, commit in that repo with `feat(F###): step N — ...`
5. **Also commit `STATUS.md` in the hub** after the step completes (so hub's git log shows per-step progress as a dedicated commit)

---

## Cross-Repo Contracts

When the FE and BE share types (an API payload, a DTO shape), you have two choices:

### Option A — Shared package (ideal if feasible)
Extract shared types into an npm workspace or a published package. Both repos depend on it. Type drift is impossible.

### Option B — Manual mirror (acceptable debt)
Define the types in each repo independently. Discipline: when one side changes, the other updates in the **same step.** Never defer.

Document whichever approach you pick in a dedicated ADR in `.claude/knowledge/decisions.md`. The spec template should include a "Types & Contracts" section forcing you to list the mirror if you went with Option B.

A pre-PR review step should flag contract drift — you can automate this with a simple script (compare the type shapes in a CI job) or manually in `/review`.

---

## PRs

For a cross-repo feature, `/create-pr` opens **one PR per repo touched,** cross-linked in each description:

```markdown
## F042 — Promo Codes

Cross-repo feature:
- Frontend: https://github.com/you/my-project-web/pull/123
- Backend: https://github.com/you/my-project-api/pull/456

...
```

Merge order usually: **backend first, then frontend.** A BE PR adding a new endpoint without a FE consumer is safe to deploy; a FE PR calling a not-yet-deployed endpoint 404s in production.

---

## Optional: `/sync-repos` Command

For cross-repo features, add a pre-flight check. Create `.claude/commands/sync-repos.md` in the hub with logic like:

```markdown
---
description: Pre-flight check for cross-repo features — verify branches + working tree across all repos
---

Sync check for feature {{FEATURE_NAME}}.

Steps:
1. Read CONTEXT.md — determine which repos the feature targets
2. For each repo:
   - `git branch --list feature/F[XXX]-{{FEATURE_NAME}}` — does the branch exist?
   - `git status --porcelain` — is the working tree clean?
   - `git log master..HEAD | head` — ahead of master
   - `git log HEAD..origin/master | head` — behind master
3. Report a table. Flag any ❌ (missing branch, dirty tree, behind master).
4. On Opus 1M tier, also run lint/build/test per repo as a health check.
```

We haven't shipped this command in the starter kit's default install because most projects won't need it. Copy-paste the above into your hub and adapt to your repo list.

---

## CLAUDE.md in the Non-Hub Repos

Each non-hub repo gets a short `CLAUDE.md` that points back to the hub:

```markdown
# <non-hub-repo> — Claude Instructions

This is the BACKEND for the my-project project. **The feature-tracking HUB is `../my-project-web/`.**

When working on feature-scoped changes:
- Feature docs live in `../my-project-web/docs/features/active/F###-<name>/`
- Branch name matches the hub: `feature/F###-<name>`
- Each step commit here: `feat(F###): step N — <description>`
- STATUS.md updates commit in the hub, not here

For standalone changes (hotfixes, refactors) that don't need a feature doc, commit normally with `fix(scope):` / `chore(scope):` messages.

## Stack

<stack details>

## Key patterns

<backend-specific conventions>

## Commands

<backend-specific commands>

## Reference

- Full workflow: ../my-project-web/docs/WORKFLOW-GUIDE.md
- Cross-repo mechanics: ../my-project-web/docs/CROSS-REPO-GUIDE.md (your per-project version)
```

---

## When NOT to Use This Variant

- **Single repo / monorepo ready** — just use the default workflow. Nx handles multi-package concerns well.
- **You can afford a monorepo migration** — ~1-2 weeks of cleanup; long-term benefits outweigh the variant's complexity.
- **Two unrelated products that share nothing** — they should have independent kits, not a cross-repo hub.

Use this variant when you have real constraints: legacy separation, independent deploy cadences, team ownership boundaries.

---

## Migration Path

Starting from separate repos with no coordination → hub model:

1. **Pick the hub.** Usually the repo you open first each morning.
2. **Install the full starter kit in the hub** (follow `docs/MIGRATION-FROM-EXISTING.md`).
3. **Install a `.claude/` subset in each non-hub repo** — rules + hooks + knowledge, no workflow commands.
4. **Add a short `CLAUDE.md` in each non-hub repo** pointing to the hub.
5. **Update the dev plan template** in the hub to include `Repo:` per step.
6. **Decide cross-repo contract strategy** (shared package vs manual mirror) and document as ADR.
7. **Start your first feature with `/new-feature`** in the hub, scope FE+BE, verify commits land in the right repos.

Expect the first 1-2 features to surface friction. Adjust your hub's `/start-coding` command and dev-plan template based on what you learn.

---

## Further Reading

- `WORKFLOW-GUIDE.md` — the default single-repo walkthrough (read this first if you haven't)
- `WORKFLOW-OPTIONS.md` — when to use Features vs Services vs SubModules
- `ENTITY-CLASSIFICATION.md` — how to classify work at different scales
- `.claude/knowledge/decisions.md` ADR-003 — tier-aware command behavior (relevant across all variants)
