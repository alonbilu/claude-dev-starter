# GitHub Workflow — From Feature Complete to Merged

This guide covers the **GitHub portion** of the feature development workflow — from creating a PR through merge and release.

---

## The Complete Flow (All 7 Phases)

```
Phase 1: Idea         (main branch)   /new-feature
Phase 2: Discussion   (main branch)   /discuss-feature
Phase 3: Spec + Plan  (main branch)   /plan-feature
Phase 4: Implement    (feature branch) /start-coding ... all
Phase 5: Complete     (feature branch) /complete-feature
Phase 6: GitHub PR    (feature branch) /create-pr → GitHub
Phase 7: Release      (main branch)   GitHub merge → auto-release (optional)
```

---

## Phase 6: GitHub PR (`/create-pr`)

### What `/create-pr` Does

```bash
/create-pr
```

Claude will:
1. Review all commits on your feature branch
2. Read the spec and dev plan
3. Generate a comprehensive PR description with:
   - **Summary:** What the feature does
   - **Test plan:** How to verify it works
   - **Checklist:** Breaking changes, dependencies, migration notes
4. Create the PR via `gh pr create` with:
   - Title: `[F[XXX]] Feature Name`
   - Body: Auto-generated description
   - Base: `main`
   - Head: `feature/F[XXX]-[name]`

**Output:** GitHub PR URL (e.g., `https://github.com/user/repo/pull/42`)

---

## Phase 7: Code Review & Merge (Your Team)

### Review Process

**Reviewer:**
```bash
# Check PR details
gh pr view 42

# See all commits in this PR
gh pr view 42 --json commits

# View CI/CD checks
gh pr checks 42

# Add a review comment (optional)
gh pr review 42 --body "Looks good! One question on line 45..."

# Approve
gh pr review 42 --approve
```

**Maintainer:**
```bash
# Merge to main
gh pr merge 42                           # interactive
gh pr merge 42 --squash                  # squash commits
gh pr merge 42 --delete-branch           # auto-delete feature branch
```

---

## Automated Release (Optional)

If your project is configured to auto-release on main branch push:

```bash
# After merge, GitHub Actions automatically:
# 1. Detect version bump in package.json (from /complete-feature)
# 2. Create GitHub release with CHANGELOG excerpt
# 3. Tag the commit (e.g., v1.2.0)
# 4. Deploy (if CD pipeline configured)

# You can verify it happened:
gh release view v1.2.0
```

---

## GitHub CLI Commands Reference

### View & Inspect

| Command | Purpose |
|---------|---------|
| `gh pr view [number]` | See PR details, status, reviews |
| `gh pr checks [number]` | View CI/CD test results |
| `gh pr list` | List all open PRs |
| `gh pr view [number] --json commits` | See all commits in PR |
| `gh pr view [number] --json reviews` | See review comments |

### Review & Merge

| Command | Purpose |
|---------|---------|
| `gh pr review [number] --approve` | Approve the PR |
| `gh pr review [number] --request-changes` | Request changes |
| `gh pr review [number] -b "message"` | Add review comment |
| `gh pr comment [number] -b "message"` | Comment on PR |
| `gh pr merge [number]` | Merge PR (interactive) |
| `gh pr merge [number] --squash` | Squash & merge |
| `gh pr merge [number] --delete-branch` | Delete feature branch after merge |

### Releases

| Command | Purpose |
|---------|---------|
| `gh release view [tag]` | See release details |
| `gh release list` | List all releases |
| `gh release create [tag]` | Create a manual release |

---

## Example: Complete Feature to Release

```bash
# Session 1: Build feature
/new-feature user-profiles
/discuss-feature user-profiles
/plan-feature user-profiles
/start-coding user-profiles all

# Session 1 End
/complete-feature user-profiles
/create-pr

# GitHub message:
# Created PR #42: [F001] User Profiles
# URL: https://github.com/myorg/myrepo/pull/42
# Ready for review. Teammate please: gh pr view 42

# Session 2: Review (Teammate)
gh pr view 42
gh pr checks 42                    # Check CI status
gh pr review 42 --approve          # Approve

# Session 2: Merge (Maintainer)
gh pr merge 42 --delete-branch

# Result:
# ✓ Feature merged to main
# ✓ Feature branch deleted
# ✓ Release created (v1.2.0) with CHANGELOG
# ✓ Tagged on GitHub
```

---

## Branch Protection Rules (Recommended)

Protect your `main` branch to enforce:

```bash
# Via GitHub web UI:
# Settings → Branches → Add rule
# Pattern: main
#
# ✓ Require pull request reviews before merging (1 approver minimum)
# ✓ Require status checks to pass (CI tests, lint, build)
# ✓ Require branches to be up to date before merging
# ✓ Include administrators in restrictions
```

This ensures:
- No direct pushes to `main` (only via PR)
- All PRs must pass tests before merge
- All PRs must be reviewed
- Admins can't bypass (prevents accidents)

---

## Troubleshooting

### "PR checks are failing"

```bash
# See which checks failed
gh pr checks 42

# Common issues:
# 1. Tests failing → run pnpm nx test locally
# 2. Lint failing → run pnpm check:fix
# 3. Build failing → run pnpm nx build

# After fixing, commit and push to feature branch
git add .
git commit -m "fix: resolve failing tests"
git push origin feature/F001-...

# Checks re-run automatically
```

### "I need to update my PR after review comments"

```bash
# Make changes locally
# Commit to feature branch
git commit -m "refactor: address review feedback"
git push origin feature/F001-...

# PR updates automatically (don't create a new one)
```

### "Feature branch is behind main"

```bash
# Update feature branch
git fetch origin
git rebase origin/main

# Force push if needed (you're the owner of this branch)
git push -f origin feature/F001-...
```

---

## PR Naming Convention

Use consistent naming for searchability:

```
Title format:
  [F[XXX]] Feature Name

Examples:
  [F001] User Profiles
  [F002] Email Verification
  [F003] OAuth Integration

Benefits:
- Easy to find by feature number
- Searchable in GitHub (PR #'s + feature codes)
- Links back to feature docs
```

---

## When NOT to Use `/create-pr`

Do NOT use `/create-pr` if:
- ❌ You haven't run `/complete-feature` yet
- ❌ Tests are failing
- ❌ Code is still being implemented
- ❌ You're working on a draft (use GitHub draft PRs instead)

**Safe checklist before `/create-pr`:**
- [ ] All steps implemented
- [ ] `pnpm nx test [project]` passes
- [ ] `pnpm check:fix` passes
- [ ] `pnpm nx build [project]` succeeds
- [ ] `/complete-feature [name]` ran and validated
- [ ] Ready for team review

---

## Setup Once: Configure `gh` for Your Repo

First time using `gh` in a new repo:

```bash
# Authenticate (one-time)
gh auth login

# Verify it works
gh repo view

# Set default branch (if needed)
gh repo edit --default-branch main
```

That's it. All `gh` commands after that work automatically.

---

## Next Steps

- **For reviewers:** Use `gh pr view [number]` to see details before reviewing
- **For maintainers:** Use `gh pr merge [number]` to merge (no GitHub web UI needed)
- **For automations:** Set up GitHub Actions to auto-release on main push
- **For safety:** Protect `main` branch with the rules listed above
