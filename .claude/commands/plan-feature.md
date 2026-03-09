---
description: Spec + dev plan (generates specification from discussion, then dev plan)
---

Plan Feature: {{FEATURE_NAME}}

## Overview

`/plan-feature` combines two steps into one convenient workflow:

1. **Generate Specification** from the discussion (create 3-spec.md)
2. **Generate Development Plan** from the spec (create 4-dev-plan.md and STATUS.md)

This is the same as running `/generate-spec [name]` followed by `/plan-execution [name]`, but in a single session.

---

## Prerequisites (MUST CHECK FIRST)

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
   - If NOT FOUND: STOP. Run `/new-feature {{FEATURE_NAME}}` first.

2. Verify `1-idea.md` exists
   - If NOT FOUND: STOP. Something is wrong with the feature setup.

3. Verify `2-discussion.md` exists and is complete
   - If NOT FOUND: STOP. Run `/discuss-feature {{FEATURE_NAME}}` first.
   - If found but incomplete (no "Chosen Approach", missing entity analysis): STOP, list what's missing, ask user to complete discussion.

4. Verify spec doesn't already exist
   - If `3-spec.md` exists: STOP. Ask: "Spec already exists. Want to revise it with `/revise-spec`, or start a new feature?"

---

## Workflow

### Part 1: Generate Specification

1. Read `1-idea.md` and `2-discussion.md`
2. Copy `docs/templates/feature/3-spec.md` template to feature directory
3. Generate comprehensive technical specification covering:
   - Executive Summary
   - Requirements (functional + non-functional)
   - Database Changes (Prisma schema, migrations)
   - Backend Specification (services, responsibilities)
   - API Specification (all endpoints)
   - Frontend Specification (pages, components, forms)
   - Validation & Error Handling (Zod schemas)
   - Testing Strategy
   - Security
   - Acceptance Criteria

**Spec Writing Guide:**
- Be specific: "Add `oauthId: String` field to User model" not "Update user model"
- Skip sections that don't apply: write "None" for layers not in PROJECT.md
- No `[TBD]` markers in critical sections before moving to dev plan
- Include exact Zod schemas, endpoint paths, database field names

### Part 2: Generate Development Plan

Once spec is written:

1. Read the completed `3-spec.md`
2. Copy `docs/templates/feature/4-dev-plan.md` to feature directory
3. Copy `docs/templates/feature/STATUS.md` to feature directory
4. Generate atomic development plan with:
   - Step count based on complexity (XS: 2–3, S: 3–5, M: 5–8, L: 8–12)
   - Each step has: Complexity, Files to read, Files to write, Done when, Commit message
   - Steps ordered bottom-up: DB → Schemas → Services → API → Frontend → Tests → Docs
   - Skip layers not in PROJECT.md

### When Complete

Tell user:
```
✅ Feature planned! Next step:

/start-step {{FEATURE_NAME}} 1    ← implement step 1
/start-step {{FEATURE_NAME}} all  ← or auto-pilot all steps
```

---

## Example

```
User: /plan-feature google-oauth

Claude: Planning feature "google-oauth"...

Reading discussion... ✓
Generating specification...
  • Database: User model + OAuth tokens
  • Backend: Auth service, OAuth controller
  • Frontend: OAuth button, callback handler
  • Tests: Unit + integration tests
✓ Spec complete

Generating development plan...
  • Complexity: S (5 steps)
  • Step 1: Database schema + migration
  • Step 2: Zod schemas + types
  • Step 3: Auth service + OAuth provider integration
  • Step 4: API endpoints
  • Step 5: Frontend UI + callback
✓ Plan complete

Next: /start-step google-oauth 1
```

---

## When to Use

✅ Use `/plan-feature`:
- After discussion is complete and ready to implement
- When you want spec + dev plan in one session
- When feature is ready to move to execution phase

❌ Don't use:
- If discussion is incomplete (use `/discuss-feature` first)
- If spec already exists (use `/revise-spec` instead)
- If you only want to generate spec (use `/generate-spec` instead)

---

Usage:
/plan-feature google-oauth
/plan-feature invoice-generation
/plan-feature email-notifications
