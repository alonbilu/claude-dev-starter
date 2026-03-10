---
description: Resume work on a feature from a previous session
---

Resume feature: {{FEATURE_NAME}}

## Steps

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Read `STATUS.md` (the session cursor)
3. Read `4-dev-plan.md` for full context
4. Check recent git log for this feature branch
5. Show branch diff from main:
   ```bash
   git diff main...HEAD --stat
   ```
6. Run quick health check:
   ```bash
   pnpm nx affected -t lint 2>&1 | tail -5
   pnpm nx affected -t test --no-coverage 2>&1 | tail -10
   ```
7. If lint or tests fail, warn prominently before continuing
8. Load relevant rules based on current step

## Output

Tell the user exactly where you left off:

```
📍 F[XXX] - {{FEATURE_NAME}}

Progress: X/N steps (XX%)
Last session: [date] ([duration])

✅ Completed steps: 1, 2, 3
🔄 Current step: 4 — [Step Name]
   In progress: [what was done]
   Remaining: [what's left]

⏳ Remaining steps: 5, 6, 7 ...

🔀 Branch diff from main: [N files changed, +X/-Y lines]

🏥 Health check:
   Lint: ✅ pass (or ⚠️ [N] issues)
   Tests: ✅ pass (or ⚠️ [N] failing)

📝 Last session notes:
[Key decisions / context from STATUS.md]

🚧 Blockers: [None / list]
```

If health check shows failures, say: "⚠️ There are [lint/test] issues from the previous session. Want to fix these first before continuing with Step [N]?"

Then ask: "Ready to continue? I'll pick up with Step [N]." → when confirmed, proceed as per `/start-coding`.

## Rules

- Don't redo completed work
- Pick up exactly where STATUS.md says
- Update STATUS.md with a new session entry when starting
- Address health check failures before new work (prevents accumulation)

Usage:
/resume-feature google-oauth
/resume-feature invoice-generation
