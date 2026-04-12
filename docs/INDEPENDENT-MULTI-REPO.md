# Independent Multi-Repo — Workflow Variant

The default starter-kit workflow assumes a single repo (typically an Nx monorepo). If your project is split across **multiple repos** that share infrastructure (database, queues, external APIs) but NOT feature work, this guide describes the simplest adaptation: install the kit **fully independently in each repo**.

This is an OPTION, not a default. It's the **right choice** when repos are loosely coupled — coordination happens at runtime (shared DB, shared queue, shared event stream), not at the feature-planning layer.

> Alternative: if the repos cooperate tightly on user-facing features (FE + BE for the same product), see [`MULTI-REPO-HUB.md`](MULTI-REPO-HUB.md) for the hub-model variant instead.

---

## The Model

**Each repo is its own project.** Each has:

- Its own full `.claude/` (commands, rules, agents, hooks, knowledge, brain.md, settings.json)
- Its own `CLAUDE.md` + `PROJECT.md`
- Its own `docs/features/` backlog + `docs/features/.registry.json` (F-number counters are per-repo; both repos can have F001, F002, ...)
- Its own feature lifecycle, own git history, own release cadence

**Claude Code sessions are bound to a single repo root.** When you run `claude` in a terminal, the session loads THAT repo's `.claude/` and resolves all paths relative to it. There is no command that operates on both repos from one session.

> To work on a different repo → start a new session rooted at that repo's directory.

---

## Repo Layout Example

Two services sharing a PostgreSQL database + Redis, no shared features:

```
my-product/
├── admin-panel/                ← first repo (independent)
│   ├── .claude/                ← full kit — rules, commands, hooks, brain.md, settings.json
│   ├── CLAUDE.md
│   ├── PROJECT.md              ← type: api-only (for example)
│   ├── docs/
│   │   ├── features/active/    ← own F-numbered backlog
│   │   ├── features/.registry.json
│   │   └── ...
│   ├── src/                    ← NestJS admin panel code
│   ├── prisma/schema.prisma    ← one half of the shared schema
│   └── biome.json
│
├── background-worker/          ← second repo (independent)
│   ├── .claude/                ← full kit — own copy
│   ├── CLAUDE.md
│   ├── PROJECT.md              ← type: worker
│   ├── docs/
│   │   ├── features/active/    ← own F-numbered backlog (independent counter)
│   │   └── ...
│   ├── src/                    ← BullMQ worker code
│   ├── prisma/schema.prisma    ← MUST mirror the admin-panel schema
│   └── biome.json
│
└── my-product.code-workspace   ← (optional) VS Code workspace grouping both for convenience
```

No "hub" owns the feature backlog. No cross-repo dev plan. Each repo evolves on its own schedule.

---

## Shared Concerns (The One Thing To Discipline)

Independent doesn't mean isolated. The things both repos touch need to stay consistent:

| Shared concern | Where it lives | Coordination rule |
|---|---|---|
| PostgreSQL schema (Prisma) | `prisma/schema.prisma` in BOTH repos | Mirror schema changes in the **same session**. Never leave drift. |
| Redis / BullMQ queue names | Hardcoded in both | Treat queue names as a contract — renaming = cross-repo change |
| Shared npm packages (internal SDKs) | `@your-org/*` | Version pin in each repo's `package.json`; bump together on breaking changes |
| Environment variable keys (`DATABASE_URL`, `REDIS_URL`, etc.) | `.env` per repo | Keep variable names identical across repos even if values differ per env |
| External API contracts (supplier APIs, webhooks) | Call sites in each repo | Document the contract in BOTH repos' `brain.md` if it's non-trivial |

**Call these out explicitly in each repo's `.claude/rules/database.md` (or a dedicated shared-infra rules file).** Example line in `database.md`:

> ⚠️ This repo's database is the SAME database as `../admin-panel/`. When `prisma/schema.prisma` changes here, mirror the change in that repo in the SAME session — otherwise one side will fail to build or crash at runtime.

Both `admin-panel/.claude/rules/database.md` and `background-worker/.claude/rules/database.md` should carry this warning in their own voice. The duplication is deliberate — rules are loaded per-repo, so each repo needs its own copy of the shared-concern warning.

---

## Working Sessions

### One session per repo

Start Claude sessions rooted at the repo you want to work on:

```bash
# Terminal 1
cd admin-panel && claude

# Terminal 2 (separate)
cd background-worker && claude
```

Or: two VS Code windows, one per repo, so Claude Code's extension attaches to the right root in each.

### Cross-repo feature (schema change spans both)

There's no single command for this. Do it manually:

1. **Session A** (repo with the more invasive change) — use the full feature flow (`/new-feature` → `/plan-feature` → `/start-coding`), changing Prisma schema + code + tests. Commit.
2. **Session B** (the other repo) — smaller change, often just mirroring the Prisma schema + adjusting one or two call sites. Use `/quick` if it's small or start a new feature if it's larger. Commit.
3. Coordinate the merge order: schema migration first (from whichever repo owns it), then consumer deploys.

Both repos' feature docs (if created on both sides) live independently — no cross-link required, but a one-line mention in each `1-idea.md` ("related to F007 in admin-panel") is good hygiene.

### Branch naming

No rule forces parity. But for features that span both repos, **using the same branch name in each** makes PR review easier:

```bash
# Both repos, same session day:
git switch -c feature/F007-shared-schema-change  # in admin-panel
# (separate session later)
git switch -c feature/F007-shared-schema-change  # in background-worker
```

Matching branch names let reviewers pattern-match across the two PRs visually. Optional, recommended.

### PRs

Two PRs, one per repo, cross-linked in each description — same pattern as the hub variant:

```markdown
## Schema change — add user.preferences column

Cross-repo:
- admin-panel PR: https://github.com/you/admin-panel/pull/42
- background-worker PR: https://github.com/you/background-worker/pull/18

Merge order: admin-panel first (owns the migration), then background-worker.
```

---

## Statusline

Each repo's statusline (at `.claude/statusline/statusline.sh`) shows `Project: <dirname>` at the front of line 1, so a glance at the CLI tells you which repo the session is rooted at:

```
Project: admin-panel | Ctx: 120k (12%) | Cache: 87% | Branch: master | Session: 15m (38k tokens)
Model: Opus 4.6 (1M)
```

(This is the default statusline behavior since v1.2.0.)

> The VS Code extension does **not** render the custom statusline. In VS Code, rely on the window title or open each repo as a separate window so the Activity Bar's folder name is the project cue.

---

## When NOT to Use This Variant

- **Single repo / monorepo already** — use the default workflow. Nx + `apps/*` + `libs/*` covers multi-team work within one repo.
- **Repos that cooperate on user-facing features** (typical FE + BE split for ONE product) — the [hub variant](MULTI-REPO-HUB.md) is a better fit because features span both repos by design.
- **Repos that are truly strangers** (different products, different teams) — they don't need any coordination convention at all; just install the kit in each independently and don't think of them as "a system."

This variant's sweet spot: **two-to-four repos, shared infrastructure, loosely coupled features.** Think: admin panel + worker + webhook handler all talking to one DB.

---

## Setup Steps (new project, per repo)

For EACH repo in the group, from scratch:

1. `cd <repo>`
2. Follow the starter kit install flow (clone / copy `.claude/`, `docs/`, `CLAUDE.md`, `PROJECT.md`) — see [`SETUP.md`](../SETUP.md) or [`MIGRATION-FROM-EXISTING.md`](MIGRATION-FROM-EXISTING.md) depending on whether the repo is new or existing
3. Run `/setup-project` and answer per this repo's profile (the two repos can legitimately pick different `type:` values — e.g. `api-only` for the admin panel, `worker` for the background job runner)
4. In `.claude/rules/database.md` (or a new `shared-infra.md`), write a loud warning naming the other repo(s) that share this DB, queue, etc.
5. Commit + push

The two repos never talk to each other at the Claude-kit layer. They only share runtime infra and the disciplines around it.

---

## Migration from Existing Separate Repos

Already have two repos that share a DB and want to adopt this pattern? For each repo independently:

1. Install the kit per [`MIGRATION-FROM-EXISTING.md`](MIGRATION-FROM-EXISTING.md)
2. In both `database.md` files, add the shared-DB warning block (see "Shared Concerns" above)
3. Optionally seed `brain.md` in each repo with a "Sibling Repo" note naming the other repo and what's shared

No cross-repo tooling to install, no hub to designate. The lowest-friction variant.

---

## Further Reading

- [`MULTI-REPO-HUB.md`](MULTI-REPO-HUB.md) — the OTHER variant (one repo owns features for both)
- [`WORKFLOW-GUIDE.md`](WORKFLOW-GUIDE.md) — the single-repo feature workflow (applies per-repo in this variant)
- [`ENTITY-CLASSIFICATION.md`](ENTITY-CLASSIFICATION.md) — when to create a feature, module, service, etc. (applies per-repo)
