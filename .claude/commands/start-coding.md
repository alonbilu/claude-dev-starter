---
description: Start implementing a specific step of the dev plan
---

Start Coding Step {{STEP_NUMBER}} for feature: {{FEATURE_NAME}}

## Prerequisites (MUST CHECK FIRST)

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Verify `4-dev-plan.md` exists — NOT FOUND → run `/plan-execution` first
3. Verify `STATUS.md` exists — NOT FOUND → run `/plan-execution` first
4. Verify Step {{STEP_NUMBER}} exists in `4-dev-plan.md`
5. Check step order via `STATUS.md`:
   - If Step {{STEP_NUMBER}} > 1 AND previous step not complete → WARN, ask to confirm
   - If more than 1 step behind → STOP, tell user to complete in order

---

## Branch Setup (Auto-Create if Needed)

Before implementing:

1. **Check if feature branch exists:**
   ```bash
   git branch | grep -q "feature/F[XXX]-{{FEATURE_NAME}}"
   ```

2. **If branch does NOT exist, offer to create it:**
   ```
   The feature branch doesn't exist yet. Create it?

   git switch -c feature/F[XXX]-{{FEATURE_NAME}}

   [Yes/No]:
   ```

   **If Yes:** Create branch, switch to it, confirm

   **If No:** Ask: "Continue on `{{CURRENT_BRANCH}}`? (not recommended)"

3. **If branch exists but not checked out:**
   Ask to switch:
   ```
   Switch to feature/F[XXX]-{{FEATURE_NAME}}?

   git switch feature/F[XXX]-{{FEATURE_NAME}}
   ```

This ensures all step commits go to the feature branch, not main.

---

## Execution

1. Read `4-dev-plan.md` → find Step {{STEP_NUMBER}}
2. Load relevant rules based on step:
   - DB steps → `.claude/rules/database.md`
   - API steps → `.claude/rules/api.md`
   - Frontend steps → `.claude/rules/frontend.md`
   - Test steps → `.claude/rules/testing.md`
3. Read `.claude/brain.md` for any relevant gotchas
4. Show user what you're about to do — confirm before starting
5. Implement exactly as specified in the dev plan
6. Run validation checklist as you go
7. After completing:
   - Run `pnpm nx affected -t lint`
   - Run `pnpm nx affected -t test` (if tests were added/modified)
   - Update `STATUS.md`: check off step, update progress %, add session log entry
   - Show summary of changes made
8. Ask: "Step {{STEP_NUMBER}} complete. Continue to Step {{STEP_NUMBER + 1}}?"

**If `{{STEP_NUMBER}}` is `all`:**
- Execute all remaining uncompleted steps in sequence
- **After the last step completes, STOP.** Do NOT auto-chain into `/complete-feature` or `/create-pr`. Report "all N steps complete, ready for your review → run `/complete-feature` when you've reviewed the work." The user must invoke `/complete-feature` and `/create-pr` manually after reviewing the actual code output.
- After each step: run lint + test, update STATUS.md
- Commit after each step: `git add . && git commit -m "feat(F[XXX]): step N — [description]"`
- Stop and ask if any step fails

## Rules

- Follow the dev plan exactly — no improvised "improvements"
- Ask before deciding if the plan is ambiguous
- Never skip the STATUS.md update
- Write tests in the same step as the code (not after)

Usage:
/start-coding google-oauth 1
/start-coding google-oauth 5
/start-coding google-oauth all
