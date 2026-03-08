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

Recommended approach:
  1. Reproduce the bug first (confirm broken state)
  2. Write a failing test
  3. Implement the minimal fix
  4. Verify the test passes
  5. Run full test suite

Describe the fix and I'll help implement it, or just go ahead and let me know when done.
```

As the fix is implemented:
- Fill `1-hotfix.md` → Root Cause, Approach, Files Changed
- Update `CONTEXT.md` → Root Cause, The Fix, Key Files

---

## Step 5 — Validate

Once fix is implemented, run:
```bash
pnpm nx affected -t lint
pnpm nx affected -t test
pnpm nx affected -t build
```

Walk through the validation checklist in `1-hotfix.md`. Diagnose and fix any failures before proceeding.

---

## Step 6 — Commit & Update Status

```bash
git add .
git commit -m "fix(HF[XXX]): {{HOTFIX_NAME}} — [one-line description of fix]"
```

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
