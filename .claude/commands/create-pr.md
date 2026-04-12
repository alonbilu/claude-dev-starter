---
description: Create a GitHub pull request for a completed feature
---

Create PR for: {{FEATURE_NAME}}

> **User-invoked only.** Never run this command automatically — e.g., don't chain into it from `/complete-feature`. The user reviews the diff + commits on the feature branch first, then invokes `/create-pr` manually. Opening a PR is a public-facing action that affects reviewers' notifications and CI budgets; it needs explicit user intent.

## Steps

### 1. Validate

Check `docs/features/active/F[XXX]-{{FEATURE_NAME}}/` or `docs/features/completed/F[XXX]-{{FEATURE_NAME}}/`.

Read `STATUS.md` (or `COMPLETION-REPORT.md`), `3-spec.md`.

Verify:
- Feature exists
- Current branch is a feature branch (not main)
- All changes are committed

Warn if not all steps are complete, but don't block — user may be creating a draft PR.

### 2. Check Branch & Push

```bash
git branch --show-current
git push -u origin $(git branch --show-current)
```

### 3. Ask for Target Branch

```
Target branch? [main]:
```

### 4. Generate PR

**Title format:** `feat(F[XXX]): {Feature Title}`

**Body — include based on what changed:**

```markdown
## Summary

{1–2 paragraph description from spec Executive Summary}

## What's New

{List key user-facing changes}

## Technical Changes

**API changes:** {new endpoints, or "None"}
**Database changes:** {schema changes, or "None"}
**UI changes:** {new pages/components, or "None"}

## Testing

| Type | Count | Status |
|------|-------|--------|
| Unit | N | ✅ |
| Integration | N | ✅ |

## Deployment

**Migration required:** Yes / No
{If yes: `pnpm nx run database:migrate:deploy`}

**New env vars:** Yes / No
{If yes: list them, reference `.env.example`}

## Checklist

- [ ] Tests passing
- [ ] No console.log / debug code
- [ ] Database migrations safe
- [ ] Env vars documented in `.env.example`

---
Feature docs: `docs/features/{active|completed}/F[XXX]-{{FEATURE_NAME}}/`
```

### 5. Create via gh CLI

```bash
gh pr create \
  --base {target} \
  --title "{title}" \
  --body "{body}"
```

If `gh` not available, print the PR URL and body for manual copy-paste:
```
https://github.com/{owner}/{repo}/compare/{target}...{branch}
```

### 6. Update STATUS.md with PR URL

Add PR link to STATUS.md and commit.

Usage:
/create-pr google-oauth
/create-pr invoice-generation
