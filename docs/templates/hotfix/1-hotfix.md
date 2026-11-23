# Hotfix: [Title]

> **ID:** HF[XXX]
> **Branch:** `hotfix/HF[XXX]-[name]`
> **Severity:** Critical / High
> **Created:** YYYY-MM-DD
> **Status:** In Progress

---

## Problem

### What's Broken
[Clear description of the bug]

### Impact
- **Users affected:** All / [percentage] / [specific group]
- **Functionality broken:** [what doesn't work]
- **Data at risk:** Yes / No
- **Workaround available:** Yes / No — [describe if yes]

### Reproduction Steps
1. [Step 1]
2. [Step 2]
3. Expected: [what should happen]
4. Actual: [what actually happens]

### Root Cause
[What caused this — fill in as you investigate]

### Regression test
- **Test:** `[path/to/file.spec.ts]` — `[test name]`
- **Red before the fix:** [paste the failing assertion / error from running it WITHOUT the fix]
- **Green after the fix:** Yes / No
- [If no automated test is possible: why, and how the fix was verified instead]

---

## Fix

### Approach
[Brief description of the fix]

### Files Changed
- `[file path]` — [what changed and why]
- `[file path]` — [what changed and why]

### Why This Fix Works
[Explanation of how the change resolves the root cause]

### Risk
[Any risk introduced by this change — Low / Medium / High]

---

## Validation

- [ ] Reproduces original bug (confirm broken state first)
- [ ] Regression test written and seen to FAIL before the fix
- [ ] Same test PASSES with the fix
- [ ] No regression in related functionality
- [ ] `pnpm verify` is green
- [ ] Tested manually in dev environment

---

## Deployment Notes

**Migration required:** Yes / No
**New env vars:** Yes / No
**Rollback plan:** [How to revert if this causes issues in production]
