# GitHub CLI Quick Reference

Fast lookup for common `gh` commands used in this workflow.

---

## Before Getting Started

```bash
# Authenticate (one-time setup)
gh auth login

# Verify it works
gh repo view
```

---

## Reviewing a PR

```bash
# See PR details
gh pr view 42

# Check if CI tests passed
gh pr checks 42

# See all commits in the PR
gh pr view 42 --json commits

# See review comments
gh pr view 42 --json reviews

# See file changes
gh pr view 42 --json files

# List all open PRs
gh pr list
```

---

## Leaving Reviews

```bash
# Approve the PR
gh pr review 42 --approve

# Request changes
gh pr review 42 --request-changes -b "Please fix the validation logic"

# Add a comment
gh pr review 42 --comment -b "Great improvement on error handling!"

# Add a comment to the PR (not a review)
gh pr comment 42 -b "This is ready for merge once CI passes"
```

---

## Merging a PR

```bash
# Merge with merge commit (interactive, asks how to merge)
gh pr merge 42

# Merge with squash (all commits become one)
gh pr merge 42 --squash

# Delete feature branch after merge
gh pr merge 42 --delete-branch

# Combine: squash + auto-delete
gh pr merge 42 --squash --delete-branch

# Merge without deleting (keep branch)
gh pr merge 42 --no-delete-branch
```

---

## Creating a PR (Rarely needed — use `/create-pr`)

```bash
# Manual PR creation (normally `/create-pr` does this)
gh pr create --title "Feature title" --body "Description" --base main

# Create as draft
gh pr create --title "WIP: Feature" --draft --base main
```

---

## Releases

```bash
# See a specific release
gh release view v1.2.0

# List all releases
gh release list

# Create a release (if auto-release didn't happen)
gh release create v1.2.0 --title "Version 1.2.0" --notes "Release notes here"

# See release with full changelog
gh release view v1.2.0 --json body
```

---

## Repository Info

```bash
# See repo details (name, description, URL)
gh repo view

# List branches
gh repo view --web                 # open repo in browser

# Set default branch
gh repo edit --default-branch main

# See collaborators
gh repo view --json owner,collaborators
```

---

## Issues

```bash
# List open issues
gh issue list

# View specific issue
gh issue view 15

# Close an issue
gh issue close 15

# Comment on issue
gh issue comment 15 -b "This has been fixed in PR #42"
```

---

## Cheat Sheet — By Use Case

### "I need to review a PR"
```bash
gh pr view 42
gh pr checks 42
gh pr review 42 --approve
```

### "I need to merge a PR"
```bash
gh pr view 42                        # check status one more time
gh pr merge 42 --squash --delete-branch
```

### "CI is failing, what went wrong?"
```bash
gh pr checks 42                      # see which checks failed
# Go to GitHub web UI to see detailed logs, OR:
gh pr view 42 --json statusCheckRollup
```

### "I need to update my PR after feedback"
```bash
# Make changes locally
git commit -m "refactor: address feedback"
git push origin feature/F001-...
# PR updates automatically on GitHub
```

### "I want to see what I just merged"
```bash
gh release list                      # see latest release
gh release view v1.2.0               # see details
```

### "I want to search for PRs"
```bash
gh pr list --search "label:bug"      # find bug PRs
gh pr list --search "author:alice"   # find Alice's PRs
gh pr list --state closed            # find closed PRs
```

---

## Common Flags

| Flag | What it does |
|------|------|
| `--base main` | Target branch for PR (default: `main`) |
| `--head feature/my-feature` | Source branch for PR |
| `--draft` | Create PR as draft (not ready for review) |
| `--squash` | Squash all commits into one when merging |
| `--rebase` | Rebase when merging (instead of merge commit) |
| `--delete-branch` | Delete source branch after merge |
| `--json` | Output raw JSON (for parsing/scripting) |
| `--web` | Open result in browser |

---

## Troubleshooting

### "gh command not found"
```bash
# Install GitHub CLI
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Windows
winget install GitHub.cli
```

### "Authentication failed"
```bash
# Re-authenticate
gh auth logout
gh auth login

# Choose: GitHub.com or GitHub Enterprise
# Choose: HTTPS or SSH
```

### "I want to see raw command output"
```bash
# Add --json to get machine-readable output
gh pr view 42 --json title,author,commits
```

---

## See Also

- Full `gh` docs: `gh help`
- Specific command help: `gh pr help view`
- GitHub workflow guide: [`GITHUB-WORKFLOW.md`](./GITHUB-WORKFLOW.md)
