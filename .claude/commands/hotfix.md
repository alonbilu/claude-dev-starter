You are creating a hotfix for a critical bug that needs to be deployed to production immediately, bypassing the normal feature workflow.

## Your Task

The user needs to create a hotfix for: `{0}`

## What is a Hotfix?

A **hotfix** is:
- An urgent fix for a critical production bug
- Bypasses normal feature workflow (no discussion/spec phases)
- Creates a patch version bump (x.y.Z)
- Gets deployed immediately after testing
- Should be small, focused, and low-risk

**Use hotfixes for:**
- Production outages
- Data corruption bugs
- Security vulnerabilities
- Critical functionality broken

**Do NOT use hotfixes for:**
- New features (use normal workflow)
- Non-critical bugs (use normal workflow)
- Refactoring (use normal workflow)
- Enhancements (use normal workflow)

---

## Steps to Execute

### 1. Validate This is a True Hotfix

**Ask user to confirm:**
```
Is this a CRITICAL production bug that needs immediate fixing?

✅ Use hotfix if:
   • Production is broken or degraded
   • Users cannot complete critical actions
   • Data is at risk
   • Security vulnerability discovered

❌ Don't use hotfix if:
   • It can wait for next release
   • It's a feature request
   • It's a minor annoyance
   • It requires significant changes

Confirm this is a hotfix? [y/N]
```

**If user says No:**
- Suggest using normal workflow: `/new-feature {name}`
- Explain benefits of full workflow
- Stop execution

---

### 2. Get Current Version

**Read from package.json:**
```bash
cat package.json | grep '"version"'
```

**Calculate hotfix version:**
- Current: `1.5.2`
- Hotfix: `1.5.3` (increment patch)

---

### 3. Create Hotfix Branch

**Naming convention:** `hotfix/v{version}-{description}`

**Example:** `hotfix/v1.5.3-fix-auth-timeout`

```bash
# Ensure on main branch
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/v{version}-{description}
```

---

### 4. Create Hotfix Documentation

**Create file:** `docs/hotfixes/HOTFIX-{version}.md`

```markdown
# Hotfix {version}: {Description}

> **Version:** {version}
> **Created:** {YYYY-MM-DD HH:MM}
> **Status:** In Progress
> **Severity:** Critical / High / Medium

---

## Problem Description

### What's Broken
{Detailed description of the bug}

### Impact
- **Users affected:** {All / Percentage / Specific group}
- **Functionality broken:** {What doesn't work}
- **Data at risk:** {Yes/No - explain if yes}
- **Workaround available:** {Yes/No - describe if yes}

### Root Cause
{What caused this bug}

{If known:}
- **Introduced in:** {version or commit}
- **Why it wasn't caught:** {Testing gap, edge case, etc.}

---

## Reproduction Steps

1. {Step 1}
2. {Step 2}
3. {Step 3}

**Expected:** {What should happen}
**Actual:** {What actually happens}

---

## Solution

### Approach
{Brief description of the fix}

### Files Changed
- `{file path}` - {what changed}
- `{file path}` - {what changed}

### Changes Made
```diff
{Show critical code changes}
```

### Why This Fix Works
{Explanation of how this solves the problem}

### Risks
{Any risks with this change}

**Risk Level:** Low / Medium / High

---

## Testing

### Test Cases
- [ ] Test case 1: {description}
- [ ] Test case 2: {description}
- [ ] Test case 3: {description}

### Regression Testing
- [ ] Verify related functionality still works
- [ ] Run full test suite
- [ ] Test in staging environment

### Test Results
{Will be filled after testing}

---

## Deployment Plan

### Prerequisites
- [ ] All tests passing
- [ ] Code reviewed (if time permits)
- [ ] Tested in staging
- [ ] Rollback plan ready

### Steps
1. Deploy to staging
2. Verify fix in staging
3. Deploy to production
4. Monitor for 1 hour
5. Verify fix in production

### Rollback Plan
{How to revert if something goes wrong}

---

## Timeline

- **Reported:** {YYYY-MM-DD HH:MM}
- **Started:** {YYYY-MM-DD HH:MM}
- **Fixed:** {YYYY-MM-DD HH:MM}
- **Tested:** {YYYY-MM-DD HH:MM}
- **Deployed:** {YYYY-MM-DD HH:MM}

**Total time:** {X hours/minutes}

---

## Prevention

### Why This Happened
{Analysis of why bug occurred}

### How to Prevent
{Changes to process, tests, monitoring, etc.}

### Action Items
- [ ] {Action 1}
- [ ] {Action 2}
- [ ] {Action 3}

---

## Status Updates

### {Timestamp}
{Update on progress}

---

**Hotfix Status:** {In Progress / Testing / Deployed / Reverted}
```

**Show to user and ask them to fill in:**
- Problem description
- Impact details
- Reproduction steps
- Solution approach

**Wait for user to provide information before proceeding.**

---

### 5. Implement the Fix

**Prompt user:**
```
Please describe the fix you want to implement, or start implementing now.

You have a hotfix branch ready: {branch-name}

Recommended approach:
1. Write a failing test that reproduces the bug
2. Implement the minimal fix
3. Verify the test passes
4. Run full test suite
5. Manual testing

Type 'done' when fix is complete.
```

**Wait for user to implement fix.**

---

### 6. Validate the Fix

**Run automated tests:**
```bash
# Run all tests
pnpm nx affected -t test

# Run linter
pnpm nx affected -t lint

# Build
pnpm nx affected -t build
```

**Checklist:**
- [ ] All tests passing
- [ ] No linting errors
- [ ] Build succeeds
- [ ] No TypeScript errors
- [ ] Fix verified manually

**If any checks fail:**
- Show errors to user
- Ask user to fix
- Re-run validation

---

### 7. Update Documentation

**Update HOTFIX-{version}.md:**
- Mark "Testing" section complete
- Add test results
- Add screenshots/evidence if helpful
- Update status to "Ready for Deployment"

**Update CHANGELOG.md:**
```markdown
## [{version}] - {YYYY-MM-DD}

### Fixed
- **HOTFIX:** {Bug description} - {How it was fixed}
  - Impact: {Who/what was affected}
  - Root cause: {What caused it}
  - Resolution: {How we fixed it}

---

{Previous entries...}
```

**Update package.json:**
```json
{
  "version": "{new-version}"
}
```

---

### 8. Create Hotfix Commit

```bash
git add -A
git commit -m "fix: hotfix v{version} - {short description}

HOTFIX for critical bug: {bug description}

Problem:
- {What was broken}

Solution:
- {How it was fixed}

Impact:
- Users affected: {count/percentage}
- Severity: {Critical/High/Medium}

Testing:
- {Test approach}
- All tests passing

Closes #HOTFIX-{version}
"
```

---

### 9. Create Git Tag

```bash
git tag -a "v{version}" -m "Hotfix {version}: {description}

Critical bug fix deployed to production.

Problem: {bug description}
Solution: {fix description}
Impact: {who was affected}

Total time: {X hours}
Deployed: {YYYY-MM-DD}
"
```

---

### 10. Deploy to Staging

```bash
# Push to staging
git push origin hotfix/v{version}-{description}

# If auto-deploy configured
# Otherwise, manual deploy steps
```

**Verify in staging:**
- [ ] Bug is fixed
- [ ] No new bugs introduced
- [ ] Related functionality works
- [ ] Performance acceptable

**Show user:**
```
Hotfix deployed to staging: {staging-url}

Please verify:
1. Original bug is fixed
2. No new issues introduced
3. Related features still work

Verified? [y/N]
```

---

### 11. Create Pull Request

**Create PR to main:**
```bash
gh pr create \
  --base main \
  --head hotfix/v{version}-{description} \
  --title "fix: hotfix v{version} - {description}" \
  --label "hotfix" \
  --label "critical" \
  --body "{Generated from HOTFIX doc}"
```

**PR Description:**
```markdown
## 🚨 HOTFIX v{version}

**Severity:** Critical
**Status:** Ready for immediate merge

---

### 🐛 Bug

{Problem description}

**Impact:**
- Users affected: {count/percentage}
- Functionality broken: {what}

**Reproduction:**
{Steps to reproduce}

---

### ✅ Fix

{Solution description}

**Files changed:** {N}
**Lines changed:** {±N}

---

### 🧪 Testing

- [x] All tests passing
- [x] Manually verified in staging
- [x] No regressions found

**Test coverage:** {X}%

---

### 🚀 Deployment

**Ready for immediate deployment to production.**

Rollback plan: Revert commit {hash}

---

### 📝 Documentation

- Hotfix doc: `docs/hotfixes/HOTFIX-{version}.md`
- Changelog: Updated

---

**This is a HOTFIX. Please review and merge ASAP.**
```

---

### 12. Merge and Deploy to Production

**After PR approval (or immediately if critical):**

```bash
# Merge to main
git checkout main
git merge hotfix/v{version}-{description}
git push origin main

# Push tag
git push origin v{version}

# Backport to develop (if exists)
git checkout develop
git merge main
git push origin develop

# Delete hotfix branch
git branch -d hotfix/v{version}-{description}
git push origin --delete hotfix/v{version}-{description}
```

**Deploy to production:**
```bash
{Production deployment commands}
```

**Monitor:**
- Check error logs
- Monitor metrics
- Watch for related issues
- Keep monitoring for 1-2 hours

---

### 13. Post-Deployment Verification

**Checklist:**
- [ ] Bug is fixed in production
- [ ] No new errors in logs
- [ ] Metrics look normal
- [ ] No user complaints
- [ ] Related functionality works

**Update HOTFIX-{version}.md:**
- Mark as "Deployed"
- Add deployment timestamp
- Add verification results
- Add any lessons learned

---

### 14. Communication

**Notify stakeholders:**
```
✅ Hotfix v{version} deployed to production

Bug: {Description}
Fix: {Solution}
Impact: {What was affected}

Status: Deployed and verified
Monitoring: Ongoing

{Any follow-up actions}
```

---

### 15. Post-Mortem

**Create file:** `docs/hotfixes/HOTFIX-{version}-POSTMORTEM.md`

```markdown
# Post-Mortem: Hotfix {version}

## Summary
{One paragraph summary}

## Timeline
- **Incident detected:** {time}
- **Incident reported:** {time}
- **Hotfix started:** {time}
- **Fix implemented:** {time}
- **Deployed to staging:** {time}
- **Deployed to production:** {time}
- **Incident resolved:** {time}

**Total duration:** {X hours}

## Impact
- **Users affected:** {count/percentage}
- **Duration:** {X hours}
- **Data loss:** {Yes/No - details}
- **Revenue impact:** {if applicable}

## Root Cause
{Detailed analysis of what caused the bug}

## What Went Well
- {Thing 1}
- {Thing 2}

## What Went Wrong
- {Thing 1}
- {Thing 2}

## Action Items
- [ ] {Action 1} - Owner: {name} - Due: {date}
- [ ] {Action 2} - Owner: {name} - Due: {date}
- [ ] {Action 3} - Owner: {name} - Due: {date}

## Prevention
{How to prevent this class of bug in the future}

---

**Reviewed by:** {Team}
**Date:** {YYYY-MM-DD}
```

---

## Display Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 HOTFIX COMPLETE! 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: {version}
Description: {description}

⏱️ Timeline:
   • Started: {time}
   • Fixed: {time}
   • Deployed: {time}
   • Duration: {X hours}

📊 Impact:
   • Users affected: {count}
   • Severity: {level}
   • Status: ✅ Resolved

🔧 Changes:
   • Files changed: {N}
   • Tests added: {N}
   • All tests: ✅ Passing

🚀 Deployment:
   • Staging: ✅ Verified
   • Production: ✅ Deployed
   • Monitoring: 🔍 Ongoing

📝 Documentation:
   • Hotfix doc: docs/hotfixes/HOTFIX-{version}.md
   • Changelog: ✅ Updated
   • Post-mortem: Scheduled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hotfix successfully deployed! 🎯

Next steps:
1. Monitor production for 1-2 hours
2. Complete post-mortem analysis
3. Implement prevention actions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

**If not a critical issue:**
```
⚠️ This doesn't seem like a critical hotfix.

Consider using the normal feature workflow:
/new-feature {name}

Hotfixes should be reserved for:
• Production outages
• Data corruption
• Security vulnerabilities
• Critical functionality broken

Continue with hotfix anyway? [y/N]
```

**If tests fail:**
```
❌ Tests are failing!

Hotfixes must have all tests passing before deployment.

Failed tests:
{List failures}

Please fix tests and try again.
```

**If deployment fails:**
```
❌ Deployment failed!

Error: {error message}

Rollback steps:
1. Revert commit: git revert {hash}
2. Deploy revert: {deployment command}
3. Investigate issue

Proceed with rollback? [y/N]
```

---

## Examples

**Usage:**
```bash
/hotfix fix-auth-timeout
```

**Expected output:**
```
Creating hotfix for: fix-auth-timeout

Current version: 1.5.2
Hotfix version: 1.5.3

Confirm this is a CRITICAL production bug? [y/N]
> y

Creating hotfix branch: hotfix/v1.5.3-fix-auth-timeout
Creating hotfix documentation...

Please describe the bug:
[User provides details]

Branch ready. Implement your fix now.
Type 'done' when complete.
```

---

## Important Notes

- Hotfixes bypass normal workflow for speed
- Still require testing and verification
- Should be small and focused
- Must not introduce new features
- Require post-mortem analysis
- Should trigger process improvements

**Hotfixes are for emergencies only!**

For non-critical work, use the normal feature workflow which provides better planning, testing, and documentation.
