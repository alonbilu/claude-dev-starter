# Workflow Guide

Practical walkthrough of the feature development workflow.

---

## The Core Principle

**Work on FEATURES, not entities directly.**

A feature is a user-facing capability ("Add Google OAuth", "Export to PDF").
Entities (modules, services, processors) are architectural components created *by* features.

You never start with `/new-module`. You start with `/new-feature`, and during the discussion phase
Claude identifies which entities to create or modify.

---

## The 5 Phases

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
/start-step google-oauth 1
# Review, approve, commit
/start-step google-oauth 2
# Review, approve, commit
# ...
```

**Autopilot (faster, less control):**
```bash
/start-step google-oauth all
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

### Phase 5: Completion

```bash
/complete-feature google-oauth
```

Claude will:
- Verify all steps are done
- Run final validation (`test`, `lint`, `build`)
- Archive feature docs to `docs/features/completed/`
- Bump version + update CHANGELOG

Then:
```bash
/create-pr
```

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

You: /start-step user-invitations 1
Claude: [implements Step 1: Prisma schema + migration]
        [writes tests, verifies they pass]
        "Step 1 complete. Commit: feat(users): add UserInvitation model (F002 step 1/6)"

You: git add ... && git commit -m "..." && git push
     /start-step user-invitations 2
...
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
/create-pr
```

**Always commit specific files** (`git add path/to/file.ts`) — not `git add -A`. This avoids
accidentally staging `.env` files, large binaries, or unrelated changes.

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

| Command | When |
|---------|------|
| `/new-feature [name]` | Starting a new feature |
| `/discuss-feature [name]` | After filling in 1-idea.md |
| `/plan-feature [name]` | After discussion is complete |
| `/start-step [name] N` | Implement step N |
| `/start-step [name] all` | Autopilot all remaining steps |
| `/resume-feature [name]` | Start of any session working on this feature |
| `/update-status [name]` | End of every session (MANDATORY) |
| `/complete-feature [name]` | When all steps done and validated |
| `/create-pr` | After /complete-feature |
| `/view-features` | See all features at a glance |
| `/trim-context` | When always-loaded files are getting bloated |
| `/setup-project` | First time only — configure the template |
