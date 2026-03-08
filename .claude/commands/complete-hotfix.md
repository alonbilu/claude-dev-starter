---
description: Complete a hotfix — patch version bump, changelog, archive, suggest PR
---

Complete hotfix: {{HOTFIX_NAME}}

## Prerequisites

1. Find `docs/hotfixes/active/HF[XXX]-{{HOTFIX_NAME}}/`
   - NOT FOUND → list available active hotfixes, stop
2. Read `STATUS.md` — verify checklist is complete (all boxes checked)
3. Verify all tests pass: `pnpm nx affected -t test`
4. Verify no uncommitted changes: `git status`

If NOT ready → STOP, explain what's missing.

---

## Step 1 — Version Bump (Patch)

Read current version from `package.json`.

Hotfixes always get a **patch** bump: `1.5.2 → 1.5.3`

Confirm with user:
```
Version bump: X.Y.Z → X.Y.Z+1

Correct? [y] Or enter version manually:
```

Update `package.json` version.

---

## Step 2 — Update CHANGELOG.md

Add entry at the top:
```markdown
## [X.Y.Z+1] - YYYY-MM-DD

### Fixed
- **HF[XXX]:** [Title] — [one-line description of what was fixed]
  - Root cause: [brief]
  - Impact: [who/what was affected]
```

---

## Step 3 — Update STATUS.md

Mark hotfix as complete:
- All checklist items checked
- Final session log entry: "Completed — merged/archived YYYY-MM-DD"
- Status: Complete

---

## Step 4 — Move to Completed

```bash
mv docs/hotfixes/active/HF[XXX]-{{HOTFIX_NAME}} docs/hotfixes/completed/
```

Update `docs/hotfixes/.registry.json` — set status to "completed" for this entry.

---

## Step 5 — Commit + Tag

```bash
git add -A
git commit -m "fix: complete HF[XXX]-{{HOTFIX_NAME}} (v{new_version})"
git tag -a "v{new_version}" -m "Hotfix {new_version}: {{HOTFIX_NAME}}"
git push origin hotfix/HF[XXX]-{{HOTFIX_NAME}}
git push origin v{new_version}
```

---

## Step 6 — Done

Print summary:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ HOTFIX COMPLETE: HF[XXX]-{{HOTFIX_NAME}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: {old} → {new}
Tagged:  v{new_version}
Branch:  hotfix/HF[XXX]-{{HOTFIX_NAME}}

Ready to open a PR:
  /create-pr {{HOTFIX_NAME}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask: "Create a pull request now? [y/N]" → if yes, run `/create-pr {{HOTFIX_NAME}}`

Usage:
/complete-hotfix fix-auth-timeout
/complete-hotfix payment-webhook-500
