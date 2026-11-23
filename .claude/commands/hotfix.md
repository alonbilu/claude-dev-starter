---
description: Start a hotfix for a critical production bug
---

Start hotfix: {{HOTFIX_NAME}}

## What is a Hotfix?

A hotfix is an urgent fix for a **critical production bug** that bypasses the normal feature workflow.
Use it for: production outages, data corruption, security vulnerabilities, critical functionality broken.

**Do NOT use for:** new features, non-critical bugs, refactoring, enhancements — use `/new-feature` instead.

---

## Step 0 — Confirm Severity

Ask the user:
```
Is this a CRITICAL production bug?

✅ Use hotfix for:
   - Production is broken or severely degraded
   - Users cannot complete critical actions
   - Data is at risk
   - Security vulnerability

❌ Use /new-feature for:
   - Non-urgent bugs
   - Feature requests
   - Anything that can wait for normal workflow

Confirm this is a hotfix? [y/N]
```

If no → stop, suggest `/new-feature`.

---

## Step 1 — Auto-Increment Hotfix ID

**Registry:** `docs/hotfixes/.registry.json`

- If NOT FOUND: create `{"nextId": 1, "hotfixes": [], "lastUpdated": "YYYY-MM-DD"}`
- Get next ID, format as 3-digit: HF001, HF002, etc.
- After creating: increment `nextId`, add entry `{"id": "HF[XXX]", "name": "{{HOTFIX_NAME}}", "created": "YYYY-MM-DD"}`, update `lastUpdated`

---

## Step 2 — Create Documentation

Create directory: `docs/hotfixes/active/HF[XXX]-{{HOTFIX_NAME}}/`

Copy and fill templates:
- `docs/templates/hotfix/1-hotfix.md` → fill ID, name, branch name (`hotfix/HF[XXX]-{{HOTFIX_NAME}}`), today's date
- `docs/templates/hotfix/STATUS.md` → fill ID, name, started date
- `docs/templates/hotfix/CONTEXT.md` → fill ID, name

Then ask:
```
Briefly describe the bug (1–2 sentences):
```

Fill "What's Broken" and "Impact" in `1-hotfix.md` from their answer.

Commit: `git add docs/hotfixes/ && git commit -m "fix: start HF[XXX]-{{HOTFIX_NAME}}"`

---

## Step 3 — Create Branch

Tell the user:
```
Create your hotfix branch now:

  git checkout main && git pull origin main
  git checkout -b hotfix/HF[XXX]-{{HOTFIX_NAME}}

On an existing branch already? Confirm its name.
```

Wait for confirmation. Update STATUS.md — check off "Branch created".

---

## Step 4 — Implement the Fix

Tell the user:
```
Ready. Implement your fix on branch hotfix/HF[XXX]-{{HOTFIX_NAME}}.

Required order — regression test FIRST, even under time pressure:
  1. Reproduce the bug (confirm the broken state)
  2. Write a test that reproduces it and RUN it — it must FAIL, for the reason in the bug report
  3. Implement the minimal fix
  4. Run the same test — it must now PASS
  5. pnpm verify

Describe the fix and I'll help implement it, or just go ahead and let me know when done.
```

### Regression test first (MANDATORY)

Do not touch production code until a test reproduces the bug:

1. **Write the test** at the lowest level that shows the bug (service/unit test if possible,
   integration test if it only appears through the HTTP layer or the database).
2. **Run it and watch it fail.** Paste the failing assertion into `1-hotfix.md` →
   "Regression test". The failure must be the bug itself — not a typo, a missing import, or
   a fixture that never reaches the faulty code.
3. **Fix**, then run the same test again and watch it pass.
4. **Falsify once more:** if in any doubt, revert the fix (`git stash` the production change
   only), confirm the test goes red again, restore the fix.

A test that was never red proves nothing: it may pass because it never exercised the bug. The
only acceptable reason to skip this is that the bug genuinely cannot be reached by an
automated test (e.g. infrastructure misconfiguration) — say so explicitly in `1-hotfix.md`
and describe how the fix was verified instead.

As the fix is implemented:
- Fill `1-hotfix.md` → Root Cause, Approach, Files Changed
- Update `CONTEXT.md` → Root Cause, The Fix, Key Files

---

## Step 5 — Validate

Once fix is implemented, run:
```bash
pnpm verify
```

Must exit 0 (lint, import boundaries, typecheck, test + coverage minimums, build), and the
regression test from Step 4 must be part of the diff.

Walk through the validation checklist in `1-hotfix.md`. Diagnose and fix any failures before proceeding.

---

## Step 6 — Commit & Update Status

```bash
git status --short
git add <the fix> <the regression test> docs/hotfixes/active/HF[XXX]-{{HOTFIX_NAME}}/
git commit -m "fix(HF[XXX]): {{HOTFIX_NAME}} — [one-line description of fix]"
```
Stage by path — never `git add .` (it sweeps unrelated work into an emergency fix).

Update `STATUS.md`:
- Check off completed checklist items
- Add session log entry with what was done, files changed, commits
- Update "Last Updated"

Update `CONTEXT.md` with current state (useful if more sessions are needed).

---

## Step 7 — Done

Tell the user:
```
Hotfix HF[XXX]-{{HOTFIX_NAME}} is implemented and documented.

When ready to ship:
  /complete-hotfix {{HOTFIX_NAME}}   → version bump + changelog + archive
  /create-pr {{HOTFIX_NAME}}         → open GitHub PR
```

Usage:
/hotfix fix-auth-timeout
/hotfix payment-webhook-500
/hotfix missing-user-permissions
