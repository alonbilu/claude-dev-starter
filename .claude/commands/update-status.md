---
description: Update feature status after session (REQUIRED after every session)
---

Update status for: {{FEATURE_NAME}}

**This is mandatory after every development session.**

## Steps

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
2. Read `STATUS.md`
3. Auto-detect from git: files changed this session, commits made
4. Ask user:
   - What was accomplished this session?
   - Any blockers?
   - Session duration?
   - Any important decisions made?
   - Goals for next session?

5. Update `STATUS.md`:
   - Add session log entry (goals, accomplished, decisions, files changed, next)
   - Check off completed steps
   - Update progress % and current step
   - Update last-updated date
   - Record any blockers

6. Update `docs/FEATURE-STATUS.md`:
   - Update active features table row for this feature

7. Commit:
   ```bash
   git add docs/features/active/F[XXX]-{{FEATURE_NAME}}/STATUS.md docs/FEATURE-STATUS.md
   git commit -m "chore: update status F[XXX]-{{FEATURE_NAME}}"
   ```

8. Show summary:
   ```
   ✅ Status updated for F[XXX] - {{FEATURE_NAME}}
   Progress: X% → Y%
   Current step: N
   Next session: [goal]
   ```

Usage:
/update-status google-oauth
/update-status invoice-generation
