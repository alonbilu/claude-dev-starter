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

## Pre-Flight Model Check (x5 only)

Before implementation, read `PROJECT.md` → `claude.max_plan`. If `x5` AND currently on Opus (model ID contains `opus`), **suggest switching to Sonnet BEFORE running the step** — not after:

**Especially important if `{{STEP_NUMBER}}` is `all`** — autopilot multiplies the savings per step.

```
⚠️  You're on Opus with max_plan: x5 about to run `/start-coding {{FEATURE_NAME}} {{STEP_NUMBER}}`.

   Implementation is pattern-following — Sonnet handles it fine at ~5x lower cost.
   On autopilot (`all`) the savings compound across every step.

   Recommended BEFORE coding:
     /update-status {{FEATURE_NAME}}
     /clear
     /model sonnet
     (turn thinking OFF if per-phase mode)
     /resume-feature {{FEATURE_NAME}}
     /start-coding {{FEATURE_NAME}} {{STEP_NUMBER}}

   Continue on Opus anyway? [y/N]
```

- **Yes** → proceed on Opus (user acknowledged the cost)
- **No or no answer** → stop; user will switch and re-invoke

Skip this check if `max_plan: x20` (Opus is the point) or `legacy` (no Opus access), or if user is already on Sonnet.

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
7. **After completing the step (MANDATORY, in this order):**
   - Run `pnpm nx affected -t lint`
   - Run `pnpm nx affected -t test` (if tests were added/modified)
   - **Update `STATUS.md` — ALWAYS, every step, no exceptions:**
     - Check off the step in the progress table
     - Update the "Completed" counter (`N / Total`) and progress %
     - Update `Current step` to the next step
     - Append a session-log entry: what was done, files changed, commit hash, time
     - Update `Last Updated` date
   - Commit: `git add . && git commit -m "feat(F[XXX]): step N — [description]"`
   - Show summary of changes made
8. Ask: "Step {{STEP_NUMBER}} complete. Continue to Step {{STEP_NUMBER + 1}}?"

**STATUS.md is the session-resumption anchor.** Failing to update it after a step means the next session's `/resume-feature` will load a stale state and Claude won't know what was done. Treat the update as part of the step — not as cleanup after.

**If `{{STEP_NUMBER}}` is `all`:**
- Execute all remaining uncompleted steps in sequence
- **After EACH step (same mandatory order as above):** lint → test → update `STATUS.md` → commit. Never skip the STATUS.md update even in autopilot — it's what makes resumption possible.
- Stop and ask if any step fails
- **After the last step completes, STOP.** Do NOT auto-chain into `/complete-feature` or `/create-pr`. Report "all N steps complete, ready for your review → run `/complete-feature` when you've reviewed the work." The user must invoke `/complete-feature` and `/create-pr` manually after reviewing the actual code output.

## Rules

- Follow the dev plan exactly — no improvised "improvements"
- Ask before deciding if the plan is ambiguous
- **Never skip the STATUS.md update.** It's part of the step, not cleanup — a step that completes without a STATUS.md update is an incomplete step.
- Write tests in the same step as the code (not after)

Usage:
/start-coding google-oauth 1
/start-coding google-oauth 5
/start-coding google-oauth all
