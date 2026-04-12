---
description: Generate atomic development plan from spec
---

Generate Development Plan for: {{FEATURE_NAME}}

## Prerequisites (MUST CHECK FIRST)

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Verify `3-spec.md` exists — NOT FOUND → run `/generate-spec` first
3. Verify spec is complete: has Requirements, Database Changes (or "None"), API Specification (or "None"), Frontend Specification (or "None"), no `[TBD]` markers in critical sections
4. Verify `1-idea.md` and `2-discussion.md` exist

---

## Steps

1. Read `3-spec.md`
2. Copy `docs/templates/feature/4-dev-plan.md` to feature directory
3. Create `STATUS.md` from `docs/templates/feature/STATUS.md`

## How to Size the Plan

Choose step count based on complexity:

| Size | Steps | When |
|------|-------|------|
| XS   | 2–3   | Tiny change — 1 file, no new entities |
| S    | 3–5   | Small feature — 1–2 new files, minor API |
| M    | 5–8   | Medium feature — new service + API + UI |
| L    | 8–12  | Large feature — new domain + full stack |

## Step Ordering (adapt to active layers)

Bottom-up, cross-functional:
1. Database schema & migrations
2. Zod schemas (source of truth)
3. Domain service (business logic)
4. Unit tests for service
5. API layer (controllers & DTOs)
6. API integration tests
7. Frontend data hooks (TanStack Query)
8. Forms with validation
9. Pages & components
10. E2E tests (critical path)
11. Polish & edge cases
12. Documentation

Skip steps that don't apply (e.g. no frontend → skip 7–9).

## For Each Step, Specify

- **Goal:** One sentence
- **Entities affected:** Which modules/services/files
- **What to build:** Exact deliverables (be specific)
- **Commands to run:** Exact bash
- **Validation checklist:** How to verify it works
- **Expected files changed:** List paths

## After Generating Plan

- Identify natural session break points (where to stop between sessions)
- Create `STATUS.md` with step checklist

**STOP here for user review.** Do NOT auto-chain into `/start-coding`. The dev plan is where implementation choices live — step ordering, token budgets per step, per-step commit messages, validation criteria. Worth reading before committing to it.

Tell the user:

```
🗺️ Dev plan written to 4-dev-plan.md (N steps, complexity M).
    STATUS.md created for session tracking.

Please review it yourself:
  - Is the step count reasonable for the complexity?
  - Does the step ORDER make sense (bottom-up: DB → schemas → services → API → UI → tests)?
  - Are natural session break points in the right places?
  - Are "Done when" criteria measurable per step?
  - Any step too ambitious? Too trivial?

Update anything in 4-dev-plan.md directly, or tell me what to revise.

Before coding, create the feature branch:
  git switch -c feature/F[XXX]-{{FEATURE_NAME}}

When plan + branch are ready, run:
  /start-coding {{FEATURE_NAME}} 1
```

Usage:
/plan-execution google-oauth
/plan-execution invoice-generation
