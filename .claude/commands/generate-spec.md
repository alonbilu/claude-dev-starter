---
description: Generate formal specification from discussion
---

Generate Specification for: {{FEATURE_NAME}}

## Prerequisites (MUST CHECK FIRST)

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Verify `1-idea.md` exists
3. Verify `2-discussion.md` exists — NOT FOUND → run `/discuss-feature` first
4. Verify discussion is complete: has "Chosen Approach" (not TBD), answered questions, entity analysis
   - Incomplete → STOP, list what's missing

---

## Steps

1. Read both `1-idea.md` and `2-discussion.md`
2. Copy `docs/templates/feature/3-spec.md` to feature directory
3. Generate comprehensive technical specification

Cover these sections (adapt based on active layers in `PROJECT.md`):

**1. Executive Summary** — what this feature does, which entities affected, scope

**2. Requirements** — functional + non-functional (performance, security, scalability)

**3. Database Changes** — new tables (full Prisma schema), modified tables, indexes, migration strategy. Write "None" if no DB changes.

**4. Backend Specification** — new services (interface + responsibilities), modified services, error handling strategy

**5. API Specification** — every endpoint: method, path, auth required, request body, response shape, validation rules. Write "None" if no API changes.

**6. Frontend Specification** — new pages (route, components, user flow), new components (props, state), forms (fields, Zod schema, validation). Write "None" if no frontend.

**7. Validation & Error Handling** — Zod schemas (source of truth), error scenarios table (scenario → HTTP status → response)

**8. Testing Strategy** — what unit tests, what integration tests, what E2E flows

**9. Security** — auth/authorization requirements, sensitive data handling

**10. Acceptance Criteria** — functional, non-functional, security — must be measurable

Be specific:
- ✅ "Add `oauthProvider: String?` and `oauthId: String?` fields to User, index on `oauthId`"
- ❌ "Update user model for OAuth"

**STOP here for user review.** Do NOT auto-chain into `/plan-execution`. The whole reason for splitting the spec and the dev plan is to give you a review checkpoint between design and execution — don't skip it.

Tell the user:

```
📋 Spec written to 3-spec.md.

Please review it yourself:
  - Are the requirements correct and complete?
  - Is the DB/API/FE breakdown aligned with your intent?
  - Are any sections marked [TBD] or too vague?
  - Are the acceptance criteria measurable?

Update anything in 3-spec.md directly, or tell me what to revise.

When the spec is solid, run:
  /plan-execution {{FEATURE_NAME}}
```

If the user notices major scope issues, they can run `/revise-spec {{FEATURE_NAME}}` instead of proceeding.

Usage:
/generate-spec google-oauth
/generate-spec invoice-generation
