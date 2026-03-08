---
description: Start a new feature by creating the idea document
---

Create Feature: {{FEATURE_NAME}}

## Auto-Increment Feature ID

**Registry file:** `docs/features/.registry.json`

Steps:
1. **Read registry:** Read `docs/features/.registry.json`
   - If NOT FOUND: Create it with `{"nextId": 1, "features": [], "lastUpdated": "YYYY-MM-DD"}`

2. **Get next ID:** Use `nextId` value from registry
   - Format as 3-digit: F001, F002, F003, etc.

3. **Create directory:** `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`

4. **Copy template:** Copy `docs/templates/feature/1-idea.md` to the new directory

5. **Fill in metadata in 1-idea.md:**
   - Feature ID: F[XXX]
   - Created: Today's date
   - Status: Idea

6. **Update registry:**
   - Increment `nextId` by 1
   - Add feature to `features` array: `{"id": "F[XXX]", "name": "{{FEATURE_NAME}}", "created": "YYYY-MM-DD"}`
   - Update `lastUpdated`

7. **Commit:** `git add docs/features/ && git commit -m "feat: start F[XXX]-{{FEATURE_NAME}} (idea)"`

---

## After Creation

Tell the user:
- This is phase 1 of the feature workflow
- Fill out `1-idea.md` with:
  - What you want to build (problem + solution)
  - User stories
  - Success criteria
  - Initial technical thoughts
  - Open questions
  - What's out of scope
  - Priority and complexity estimate

Next steps:
- User fills out and saves `1-idea.md`
- Run `/discuss-feature {{FEATURE_NAME}}` to start discussion phase

Usage:
/new-feature google-oauth
/new-feature invoice-generation
/new-feature dashboard-analytics
