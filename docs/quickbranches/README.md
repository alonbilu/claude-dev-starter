# Quickbranches

Small, PR-ready fixes that don't warrant the full feature-tracking flow. Created by the `/quickbranch` command.

## Purpose

Each file here captures:
- **Request** — the user's original ask, verbatim (phrasing preserved so context doesn't drift)
- **Plan** — what the assistant intended to change and why
- **Work done** — what actually changed (files + summary + any deviation from plan)
- **Commits** — SHAs for the code + docs commits

This gives a lightweight paper trail for small fixes without the overhead of `docs/features/`.

## Where it sits

```
/quick         → no branch, no docs                    (tiny throwaway)
/quickbranch   → new branch + single dated doc         (small PR-ready)
/hotfix        → new branch + HF### registry + docs    (critical prod bug)
/new-feature   → new branch + F### registry + docs     (planned feature)
```

## File naming

`{YYYY-MM-DD}-{kebab-slug}.md`

Examples:
- `2026-04-14-exclude-global-filters-bar-on-hebrew-paths.md`
- `2026-04-20-remove-unused-imports-from-billing-module.md`

## Frontmatter

```yaml
---
date: 2026-04-14
branch: fix/exclude-global-filters-bar-on-hebrew-paths
status: in-progress | done
---
```

`status: in-progress` while implementing, flipped to `done` before the commit.

## Lifecycle

1. `/quickbranch <task>` creates the branch + this doc entry with `status: in-progress`
2. Implementation happens on the branch
3. Doc gets filled in (`## Work done`, `## Commits`) and `status: done`
4. Two commits land: one code, one docs
5. User either pushes manually or via `/create-pr`

## Not for

- Multi-step features → `docs/features/active/` (`/new-feature`)
- Cross-repo / cross-module changes → `docs/features/active/`
- Critical production bugs → `docs/hotfixes/active/` (`/hotfix`)
- Pure discovery → `/discuss-feature`
- Throwaway same-branch tweaks → `/quick` (no doc created)
