---
description: Complete a feature — archive, version bump, changelog, git tag
---

Complete feature: {{FEATURE_NAME}}

> **User-invoked only.** Never run this command automatically — e.g., don't chain into it from `/start-coding all`. The user reviews the actual work first, then invokes `/complete-feature` manually. This is an irreversible-ish action (archives docs, bumps version, updates CHANGELOG) and needs a human check on the output.

## Prerequisites

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Read `STATUS.md` and `4-dev-plan.md`
3. Verify ALL steps are checked complete in STATUS.md
4. Verify tests are passing
5. No active blockers
6. All acceptance criteria met

If NOT ready → STOP, explain what's missing, do not proceed.

---

## Steps

### 1. Determine Version Bump

Read current version from `package.json`.

Ask user:
```
Feature "{{FEATURE_NAME}}" is complete!

Current version: X.Y.Z
Suggested version: X.Y+1.Z (minor — new feature, backward-compatible)

Correct? [y] Or enter version manually:
```

Rules:
- Major (X.0.0): breaking changes
- Minor (x.Y.0): new features, backward-compatible
- Patch (x.y.Z): bug fixes, minor improvements

### 2. Update package.json + CHANGELOG.md

Update version in `package.json`.

Add entry to `CHANGELOG.md`:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- **{Feature Title}** (F{XXX}) — {description}
  - {Key change 1}
  - {Key change 2}
```

### 3. Move Feature to Completed

```bash
mv docs/features/active/F[XXX]-{{FEATURE_NAME}} docs/features/completed/
```

Update `docs/features/.registry.json` — mark feature status as "completed".

### 4. Update docs/FEATURE-STATUS.md

- Move from Active → Completed table
- Update overall metrics

### 5. Completion Commit + Tag

```bash
git add -A
git commit -m "feat: complete F[XXX] - {{FEATURE_NAME}} (v{new_version})"
git tag -a "v{new_version}" -m "Release {new_version}: {{FEATURE_NAME}}"
git push origin {branch}
git push origin v{new_version}
```

### 6. Celebrate 🎉

Print a summary:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 FEATURE COMPLETE: {{FEATURE_NAME}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: {old} → {new}
Steps:   {N}/{N} ✅
Tagged:  v{new_version}

Next: /create-pr {{FEATURE_NAME}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After archiving + version bump, ask the user:
```
Feature complete and tagged. Ready to open a pull request now?
I can run /create-pr {{FEATURE_NAME}} for you, or you can run it yourself later.

Open PR now? [y/N]
```

- **If the user says yes** → proceed to `/create-pr {{FEATURE_NAME}}` in the same turn. The user's invocation of `/complete-feature` already signals "I've reviewed the work," so offering and running `/create-pr` on confirmation is fine.
- **If the user says no or declines** → stop cleanly. They'll invoke `/create-pr` manually when they're ready.
- **Do NOT skip the question.** The user should have the option to pause here, not just be auto-forwarded.

Usage:
/complete-feature google-oauth
/complete-feature invoice-generation
