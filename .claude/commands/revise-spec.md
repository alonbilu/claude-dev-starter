---
description: Revise specification mid-feature when requirements change
---

Revise Specification for: {{FEATURE_NAME}}

## When to Use This Command

Use `/revise-spec` when:
- You're mid-implementation and realize the spec needs changes
- New requirements emerge during development
- Technical discoveries invalidate original assumptions
- User feedback requires scope changes

Do NOT use this command for:
- Minor typo fixes (just edit the file)
- Adding implementation notes (use STATUS.md)
- First-time spec creation (use `/generate-spec`)

---

## Prerequisites (MUST CHECK FIRST)

1. **Find feature directory:** Look for `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
   - If NOT FOUND: STOP. This feature doesn't exist yet.

2. **Check 3-spec.md exists:** The spec must already exist
   - If NOT FOUND: STOP. Use `/generate-spec {{FEATURE_NAME}}` first.

3. **Check 4-dev-plan.md exists:** Feature should be in execution phase
   - If NOT FOUND: Just regenerate the spec normally with `/generate-spec`.

---

## Revision Process

### Step 1: Understand the Change

Ask user:
- What needs to change in the specification?
- Why is this change needed?
- Which sections of the spec are affected?
- Are we adding scope, removing scope, or changing approach?

### Step 2: Assess Impact

Read current `3-spec.md` and `4-dev-plan.md`, then determine:

**Impact Level:**

| Level | Description | Action |
|-------|-------------|--------|
| **Minor** | Cosmetic, no code impact | Update spec only |
| **Moderate** | Affects 1-3 steps of dev plan | Update spec + affected steps |
| **Major** | Affects 4+ steps or core architecture | Update spec + regenerate dev plan |
| **Critical** | Invalidates entire approach | Consider restarting feature |

Tell user the impact level and ask for confirmation before proceeding.

### Step 3: Update Specification

1. **Add revision header to 3-spec.md:**
   ```markdown
   ---

   ## Revision History

   ### Revision 1: YYYY-MM-DD
   **Reason:** [Why the change was needed]
   **Impact Level:** [Minor/Moderate/Major/Critical]
   **Sections Changed:**
   - [Section 1]: [What changed]
   - [Section 2]: [What changed]
   **Steps Affected:** [List step numbers from dev plan]

   ---
   ```

2. **Update the affected sections:**
   - Mark what changed with `[REVISED]` tag
   - Keep old content as strikethrough if helpful for context
   - Update all related sections (DB → API → Frontend cascade)

3. **Update dependencies:**
   - If new dependencies added, update `1-idea.md` dependencies section
   - If scope changed, update success criteria

### Step 4: Update Development Plan (if needed)

For **Moderate/Major/Critical** impacts:

1. **Read current STATUS.md:** What steps are complete?

2. **Identify affected steps:**
   - Which completed steps need rework?
   - Which pending steps need modification?

3. **Update 4-dev-plan.md:**
   - Add `[REVISED]` tag to changed steps
   - If step already complete and needs rework, add:
     ```markdown
     **⚠️ REWORK REQUIRED:** [Describe what needs to change]
     ```

4. **Update STATUS.md:**
   - Add session log entry for revision
   - Note any completed steps that need rework
   - Update "What's not working yet" section

### Step 5: Summarize Changes

Tell user:
- What sections were updated
- What steps are affected
- If any completed work needs rework
- Next recommended action

---

## Example Revision Session

```
User: /revise-spec google-oauth

Claude: I'll help revise the Google OAuth specification. First, some questions:

1. What needs to change in the specification?
2. Why is this change needed?
3. Which sections are affected?

User: We need to add support for Apple Sign-In as well, not just Google.

Claude: I see. Let me assess the impact:

**Impact Level: Major**

This affects:
- Database schema (add apple-specific fields)
- API endpoints (add Apple callback)
- Frontend (add Apple button)
- Multiple dev plan steps (1, 3, 5, 7, 9)

You've completed Steps 1-4. Steps 1-3 will need partial rework to add Apple support.

Do you want to proceed with this revision? [Yes/No]

User: Yes

Claude: Updating specification...
[Updates 3-spec.md with revision history and new Apple sections]
[Updates 4-dev-plan.md with revised steps]
[Updates STATUS.md with revision log]

Done! Summary:
- Added Revision 1 to spec
- Steps 1, 3, 5, 7, 9 updated in dev plan
- Steps 1-3 marked for rework
- Estimated additional time: +4 hours

Next action: `/start-step google-oauth 1` to begin rework.
```

---

## Post-Revision Checklist

- [ ] Revision history added to 3-spec.md
- [ ] All affected sections updated
- [ ] 4-dev-plan.md updated (if Moderate/Major/Critical)
- [ ] STATUS.md updated with revision log
- [ ] 1-idea.md dependencies updated (if applicable)
- [ ] User understands rework requirements

---

Usage:
/revise-spec google-oauth
/revise-spec invoice-generation
