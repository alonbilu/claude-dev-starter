---
description: PR-ready small fix — creates a dedicated branch + docs/quickbranches/ entry logging the request & work done (5-30 min). For a throwaway same-branch fix with no docs, use /quick instead.
---

Quick branched task: $ARGUMENTS

Like `/quick`, but creates a short-lived branch and logs the request + outcome under `docs/quickbranches/`. Use this when a fix is small but you want a clean branch + PR-able history.

## /quick vs /quickbranch vs /hotfix vs /new-feature

| | `/quick` | `/quickbranch` | `/hotfix` | `/new-feature` |
|---|---|---|---|---|
| Branch | current | new `fix/…` / `chore/…` | new `hotfix/HF###-…` | new `feature/F###-…` |
| Docs | none | `docs/quickbranches/{date}-{slug}.md` | `docs/hotfixes/active/HF###-…/` | `docs/features/active/F###-…/` |
| Registry | no | no | yes (`HF###`) | yes (`F###`) |
| Time box | 5-15 min | 5-30 min | urgent | open-ended |
| Use when | tiny throwaway fix | small but reviewable | critical prod bug | planned work |

## Rules

- No feature-level tracking (no `F###`, no registry entry, no spec, no dev-plan)
- Must create a new branch (never work on `main`)
- Must create a doc entry before implementing (captures the user's original request verbatim)
- Must update the doc entry with the actual work done before committing
- Search before creating (always applies)
- If task grows beyond ~30 min, spans multiple services/modules, or needs a schema change, stop and suggest `/new-feature`
- If it's a critical production bug, suggest `/hotfix` instead

## Steps

### 1. Understand
Parse `$ARGUMENTS`. Confirm scope. If it smells like any of:
- schema change / new DB table
- new API endpoint + frontend page together
- >5 files across multiple modules
- cross-service coordination

...stop and recommend `/new-feature`. If it's a critical prod bug, recommend `/hotfix`.

### 2. Derive branch + doc slug
- Slug = kebab-case of the task (≤40 chars, alphanumeric + `-`). Example: "fix hebrew paths not excluding sticky filter bar" → `fix-hebrew-paths-not-excluding-sticky-filter-bar`
- Branch prefix: `fix/` for bug fixes, `chore/` for cleanups/refactors, `feat/` for tiny additive changes
- Full branch: `{prefix}/{slug}` (e.g. `fix/hebrew-paths-not-excluding-sticky-filter-bar`)
- Doc filename: `docs/quickbranches/{YYYY-MM-DD}-{slug}.md`

### 3. Create branch
```bash
git switch main && git pull --ff-only
git switch -c {branch}
```
If the working tree is dirty, stop and ask the user whether to stash or commit first. Never `git stash drop` or `git reset --hard` without explicit approval.

### 4. Create doc entry (before implementing)
If `docs/quickbranches/` doesn't exist yet, create it with a `README.md` (see the starter's template).

Write `docs/quickbranches/{YYYY-MM-DD}-{slug}.md`:
```markdown
---
date: {YYYY-MM-DD}
branch: {branch}
status: in-progress
---

# {Short title derived from the task}

## Request
{Verbatim user ask — copy $ARGUMENTS as-is so the original phrasing is preserved}

## Plan
{1-3 bullets — what you intend to change and why}

## Work done
_(filled in after implementation)_

## Commits
_(filled in after commit)_
```

### 5. Search before creating
```bash
grep -r "relevant_term" libs/ apps/
```

### 6. Load rules
Based on task type:
- Database changes → `.claude/rules/database.md`
- API changes → `.claude/rules/api.md`
- Frontend changes → `.claude/rules/frontend.md`
- Test changes → `.claude/rules/testing.md`

### 7. Implement
Make the change. Keep it minimal. No speculative refactoring.

### 8. Validate
```bash
pnpm nx affected -t lint
pnpm nx affected -t test
```
Fix any new errors. Pre-existing errors in untouched files are not your problem (note them in the doc if relevant).

### 9. Update doc entry
Fill in the `## Work done` section:
- What actually changed (files + one-line summary each)
- Any deviation from the original Plan, with reason
- Validation output (lint/test status)

Set `status: done` in frontmatter.

### 10. Commit
Two logical commits (or one if tightly coupled):
```bash
git add {code files}
git commit -m "fix(scope): description"

git add docs/quickbranches/{YYYY-MM-DD}-{slug}.md
git commit -m "docs(quickbranch): {slug}"
```

Fill in the `## Commits` section of the doc with the SHAs (amend the docs commit if needed — this is pre-push, safe).

### 11. Offer next step
Prompt the user with `[y/N]` for one of:
- `git push -u origin {branch}` — push the branch
- `/create-pr` — push + open a PR

Do NOT auto-push or auto-open a PR.

## Usage
```
/quickbranch fix Hebrew category paths not excluding sticky filter bar
/quickbranch chore remove unused imports from billing module
/quickbranch feat add tooltip to baggage icon
```

## When NOT to use
- Multi-step / cross-module work → `/new-feature`
- Schema change → `/new-feature` (needs proper planning + migration review)
- Critical production bug → `/hotfix`
- Discovery / unclear requirements → `/discuss-feature`
- No-branch throwaway fix → `/quick`
