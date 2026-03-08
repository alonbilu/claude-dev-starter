---
description: View current development status across all features
---

Display feature development dashboard.

## Steps

1. Read `docs/FEATURE-STATUS.md`
2. Scan all `docs/features/active/*/STATUS.md` files
3. Display:

```
📊 Feature Dashboard

🎯 Active:
- F001 - google-oauth: Step 5/8 (60%) — last session: 2 days ago
- F002 - invoice-generation: Step 2/5 (40%) — last session: today

⏸️  Blocked:
- (none)

📋 Backlog:
- F003 - dashboard-analytics (planned)

✅ Completed:
- (none yet)

📈 Overall: 2 active features
```

4. For each active feature, show:
```
F001 - google-oauth (60%)
├─ Current: Step 5/8
├─ Last session: 2 days ago
├─ Blockers: None
└─ Next: Complete API integration tests
```

5. Suggest next actions:
   - Which feature to resume (based on priority + progress)
   - Quick commands: `/resume-feature [name]`, `/new-feature [name]`, `/update-status [name]`

Usage:
/view-features
