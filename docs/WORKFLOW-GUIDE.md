# Workflow Guide

Practical walkthrough of the feature development workflow.

---

## Choosing Your Workflow

Not every task needs the full feature workflow. Pick the right tool:

| Task size | Command | Creates docs? |
|-----------|---------|---------------|
| **Quick fix** (5-15 min, <5 files) | `/quick [task]` | No |
| **Debug an error** | `/debug [error]` | No |
| **Generate boilerplate** | `/scaffold [type] [name]` | No |
| **New capability** (API + UI + DB) | `/new-feature [name]` | Yes (full workflow) |
| **New domain area** | `/new-module [name]` | Yes (module spec) |
| **Backend-only process** | `/new-service [name]` | Yes (service spec) |
| **Production emergency** | `/hotfix` | Yes (hotfix docs) |

**Default:** Start with `/new-feature`. Use `/quick` for small fixes. Use `/scaffold` for boilerplate.

---

## The Core Principle

**Work on FEATURES, not entities directly.**

A feature is a user-facing capability ("Add Google OAuth", "Export to PDF").
Entities (modules, services, processors) are architectural components created *by* features.

For most work, start with `/new-feature`, and during the discussion phase
Claude identifies which entities to create or modify. Use `/new-module` only when setting up
domain structure before building features.

---

## The 6 Phases (5 Claude + 1 GitHub)

### Phase 1: Idea (you write this)

```bash
/new-feature google-oauth
```

Creates: `docs/features/active/F001-google-oauth/1-idea.md`

Fill in:
- What does this feature do for the user?
- Why do we need it?
- Any constraints or requirements?
- Success criteria (how do we know it's done?)

---

### Phase 2: Discussion (Claude leads)

```bash
/discuss-feature google-oauth
```

Claude will:
- Read your idea document
- Ask clarifying questions (one at a time)
- Identify which entities to create or modify
- Propose 2–3 implementation approaches
- Wait for you to choose

Creates: `docs/features/active/F001-google-oauth/2-discussion.md`

**Do not rush this phase.** Decisions made here shape the entire implementation.
Claude will verify: "Ready to generate spec. Run `/plan-feature google-oauth`."

---

### Phase 3: Spec + Dev Plan (Claude generates)

```bash
/plan-feature google-oauth
```

Claude assesses complexity (XS/S/M/L) and generates:

- `3-spec.md` — Schema, API endpoints, frontend components, testing plan
- `4-dev-plan.md` — Atomic steps (2–12 depending on size), each with:
  - Files to read / write
  - Estimated token budget
  - Done criteria
  - Commit message
- `STATUS.md` — Progress tracking cursor
- `CONTEXT.md` — 1-page quick-load for session resumption

**Also:** Claude creates the feature branch for you (or reminds you to):
```bash
git checkout -b feature/F001-google-oauth
```

---

### Phase 4: Implementation

**Step-by-step (safer, you stay in control):**
```bash
/start-coding google-oauth 1
# Review, approve, commit
/start-coding google-oauth 2
# Review, approve, commit
# ...
```

**Autopilot (faster, less control):**
```bash
/start-coding google-oauth all
# Claude implements all remaining steps, auto-commits between each
# Stops and reports if any step fails
```

**After each step:**
```bash
git add [specific files]
git commit -m "feat(auth): add Google OAuth provider (F001 step 1/5)"
git push origin feature/F001-google-oauth
```

---

### Phase 5: Completion & PR Creation

```bash
/complete-feature google-oauth
```

Claude will:
- Verify all steps are done
- Run final validation (`test`, `lint`, `build`)
- Archive feature docs to `docs/features/completed/`
- Bump version + update CHANGELOG
- Prepare the feature for PR creation

Then:
```bash
/create-pr
```

**Result:**
- GitHub PR created with auto-generated description
- Feature branch pushed (if not already)
- PR URL printed (e.g., `https://github.com/org/repo/pull/42`)

---

### Phase 6: GitHub (Review & Merge)

After `/create-pr`, the feature moves to GitHub for review and merge.

**For team members reviewing:**
```bash
gh pr view 42          # See PR details
gh pr checks 42        # Check CI status
gh pr review 42 --approve   # Approve it
```

**For maintainers merging:**
```bash
gh pr merge 42 --delete-branch   # Merge + auto-delete feature branch
```

**Result:**
- Feature merged to `main`
- Feature branch deleted
- Release created + tagged (if auto-release configured)

See **[GitHub Workflow](./GITHUB-WORKFLOW.md)** for complete GitHub operations guide.

---

## Step-by-Step Example

```
You: /new-feature user-invitations
Claude: Created docs/features/active/F002-user-invitations/1-idea.md
        Fill in the idea document, then run /discuss-feature user-invitations

You: [fills in idea.md]

You: /discuss-feature user-invitations
Claude: [reads idea, asks questions]
        "Should invitations expire? [yes/no and how long]"
        "Should invited users have a different onboarding flow?"
        ...

You: [answers questions]
Claude: [creates 2-discussion.md]
        "Entities: UserInvitation model (new), InvitationService (new SubModule in users domain),
         SendInvitationEmail template (new). Ready to plan. Run /plan-feature user-invitations"

You: /plan-feature user-invitations
Claude: [assesses: M complexity, 6 steps]
        [creates 3-spec.md, 4-dev-plan.md, STATUS.md, CONTEXT.md]
        "Feature branch: git checkout -b feature/F002-user-invitations"

You: git checkout -b feature/F002-user-invitations

You: /start-coding user-invitations 1
Claude: [implements Step 1: Prisma schema + migration]
        [writes tests, verifies they pass]
        "Step 1 complete. Commit: feat(users): add UserInvitation model (F002 step 1/6)"

You: git add ... && git commit -m "..." && git push
     /start-coding user-invitations 2
...

You: [after all steps implemented]
     /update-status user-invitations    # MANDATORY before switching tasks
     /complete-feature user-invitations
Claude: [validates all steps, runs tests, updates version/CHANGELOG]
        "Feature complete. Run /create-pr to create GitHub PR"

You: /create-pr
Claude: [creates GitHub PR with auto-generated description]
        "PR created: https://github.com/org/repo/pull/42"

[Team review on GitHub]
You: gh pr view 42
     gh pr checks 42
     [teammate approves]

[Merge to main]
You: gh pr merge 42 --delete-branch
Result: Feature merged to main, branch deleted, release created (v1.2.0)
```

---

## Resuming After a Break

```bash
/resume-feature user-invitations
```

Claude loads CONTEXT.md + STATUS.md (~15–20k tokens) and picks up exactly where you left off.

---

## Context Window Management

When Claude says "Context is getting full (~70%)":

1. Finish the current step
2. Commit + push
3. Run `/update-status [name]`
4. Start a fresh Claude session
5. Run `/resume-feature [name]`

---

## Multi-Session Tracking

At the **end of every session**, run:
```bash
/update-status [name]
```

This updates STATUS.md with:
- Steps completed
- Steps remaining
- Decisions made
- Blockers
- Next session goal

**Never skip this.** It's what makes multi-session features work.

---

## Error Recovery — When Things Go Wrong

### Step fails mid-implementation

```bash
# 1. Don't panic. Check what changed:
git status
git diff

# 2. If the code is partially working, commit what works:
git add [working-files]
git commit -m "wip(scope): partial step N (F[XXX])"

# 3. If the code is broken, revert uncommitted changes:
git checkout -- [broken-files]

# 4. Update STATUS.md with what happened:
/update-status [name]
# Note the blocker in your status update

# 5. Resume in a fresh session:
/resume-feature [name]
# Claude will see the blocker and help resolve it
```

### Tests fail after implementation

```bash
# 1. Run the debug workflow:
/debug [error message from test output]

# 2. If it's a known gotcha, the fix is usually quick
# 3. If it's a new issue, /debug will document it in stack-gotchas.md
```

### Merge conflicts on feature branch

```bash
# 1. Update your branch from main:
git fetch origin
git rebase origin/main

# 2. Resolve conflicts file by file
# 3. Continue the rebase:
git add [resolved-files]
git rebase --continue

# 4. Force push your branch (safe — it's YOUR feature branch):
git push -f origin feature/F[XXX]-[name]
```

### Context window is full

```bash
# 1. Commit current work
git add [files] && git commit -m "wip: save progress"

# 2. Save your status
/update-status [name]

# 3. Start a fresh Claude session
# 4. Resume with full context loaded cleanly:
/resume-feature [name]
```

### Need to abandon a feature

```bash
# 1. Update status with the reason:
/update-status [name]
# Mark as "abandoned" with explanation

# 2. Switch back to main:
git switch main

# 3. Optionally delete the feature branch:
git branch -d feature/F[XXX]-[name]
```

---

## Pre-PR Review

Before creating a PR, run a self-review:

```bash
/review
```

This checks for: import violations, duplicate code, missing tests, hardcoded values, security issues, and unused code. Fix any issues before sharing with teammates.

---

## Git Workflow Summary

```bash
# Planning phases (idea, discussion, spec, plan) — stay on main
git checkout main

# Before implementation
git checkout -b feature/F[XXX]-[name]

# After each step
git add [specific-files]
git commit -m "feat(scope): description (F[XXX] step N/Total)"
git push origin feature/F[XXX]-[name]

# When complete
/complete-feature [name]
/create-pr
# ↓ Creates GitHub PR with auto-generated description
# ↓ Share the PR URL with your team

# Team reviews on GitHub
gh pr view 42
gh pr checks 42

# Merge when approved
gh pr merge 42 --squash --delete-branch
```

**Always commit specific files** (`git add path/to/file.ts`) — not `git add -A`. This avoids
accidentally staging `.env` files, large binaries, or unrelated changes.

**After merge:** Version bump + CHANGELOG are automatically updated by `/complete-feature`.
Releases are created automatically if your project has auto-release configured.

---

## Feature Directory Structure

```
docs/features/
├── active/
│   └── F001-google-oauth/
│       ├── 1-idea.md          ← you write this
│       ├── 2-discussion.md    ← Claude fills during /discuss-feature
│       ├── 3-spec.md          ← Claude generates during /plan-feature
│       ├── 4-dev-plan.md      ← Claude generates during /plan-feature
│       ├── STATUS.md          ← updated by /update-status (the "cursor")
│       └── CONTEXT.md         ← 1-page quick-load for /resume-feature
├── completed/
│   └── F001-google-oauth/     ← archived by /complete-feature
└── backlog/
    └── F002-idea.md           ← optional: capture future ideas here
```

---

## Quick Command Reference

### Feature Workflow Commands

| Command | When |
|---------|------|
| `/new-feature [name]` | Starting a new feature |
| `/discuss-feature [name]` | After filling in 1-idea.md |
| `/plan-feature [name]` | After discussion is complete |
| `/start-coding [name] N` | Implement step N |
| `/start-coding [name] all` | Autopilot all remaining steps |
| `/resume-feature [name]` | Start of any session working on this feature |
| `/update-status [name]` | End of every session (MANDATORY) |
| `/complete-feature [name]` | When all steps done and validated |
| `/create-pr` | After /complete-feature (creates GitHub PR) |
| `/review` | Pre-PR self-review (run before /create-pr) |
| `/view-features` | See all features at a glance |
| `/trim-context` | When always-loaded files are getting bloated |
| `/setup-project` | First time only — configure the template |

### Quick Action Commands

| Command | When |
|---------|------|
| `/quick [task]` | Small fix (5-15 min, no feature docs) |
| `/debug [error]` | Systematic debugging workflow |
| `/scaffold [type] [name]` | Generate boilerplate (endpoint, page, hook, service, domain-lib) |
| `/new-module [name]` | Create a top-level domain module |
| `/new-submodule [parent] [name]` | Add SubModule to a Module |

### GitHub CLI Commands (After `/create-pr`)

| Command | Purpose |
|---------|---------|
| `gh pr view 42` | See PR details and status |
| `gh pr checks 42` | Check CI/CD test results |
| `gh pr review 42 --approve` | Approve the PR |
| `gh pr merge 42 --delete-branch` | Merge PR and delete feature branch |
| `gh release view v1.2.0` | See release details |

**Full reference:** See [`GITHUB-CLI-REFERENCE.md`](./GITHUB-CLI-REFERENCE.md) for complete `gh` command list
