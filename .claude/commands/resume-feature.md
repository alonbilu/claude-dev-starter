---
description: Resume work on a feature from a previous session
---

Resume feature: {{FEATURE_NAME}}

## Steps

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Read `STATUS.md` (the session cursor)
3. Read `4-dev-plan.md` for full context
4. Check recent git log for this feature branch
5. Load relevant rules based on current step

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

📝 Last session notes:
[Key decisions / context from STATUS.md]

🚧 Blockers: [None / list]
```

Then ask: "Ready to continue? I'll pick up with Step [N]." → when confirmed, proceed as per `/start-step`.

## Rules

- Don't redo completed work
- Pick up exactly where STATUS.md says
- Update STATUS.md with a new session entry when starting

Usage:
/resume-feature google-oauth
/resume-feature invoice-generation
