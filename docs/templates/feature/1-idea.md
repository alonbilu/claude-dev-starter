# Feature Idea: [Feature Name]

> **Feature ID:** F[XXX]
> **Created:** YYYY-MM-DD
> **Status:** Idea

---

## What I Want to Build

[Describe in your own words what this feature should do. Focus on the problem you're solving and what success looks like for users/business.]

---

## User Story

As a [user type], I want to [action] so that [benefit].

**Additional user stories (if any):**
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

---

## Success Criteria

How will I know this feature is complete and working?

- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

---

## Context & Motivation

**Why now?**
[Why is this important to build now?]

**Business value:**
[What business problem does this solve?]

**User impact:**
[How does this improve the user experience?]

---

## Rough Technical Thoughts

[Your initial ideas about how this might work. Don't worry about being perfect - just brain dump.]

**Entities I think might be involved:**
- Existing: [modules/services you'll modify]
- New: [modules/services you'll create]

**Data:**
- What data needs to be stored?
- Any changes to existing data models?

**Integrations:**
- External APIs (Stripe, Google, etc.)?
- Internal services?

---

## Open Questions / Uncertainties

[What are you not sure about? Where do you need Claude's input?]

1.
2.
3.

---

## Out of Scope (Important!)

[What features are you explicitly NOT including in this version?]

-
-
-

---

## Priority

- [ ] Critical (blocks other work)
- [ ] High (important for upcoming release)
- [ ] Medium (nice to have soon)
- [ ] Low (future enhancement)

---

## Feature Dependencies

> Use feature IDs (F001, F002, etc.) to track dependencies between features.
> This helps `/view-features` show dependency warnings.

**Depends on features (must be completed first):**
- [ ] None
- [ ] F[XXX] - [Feature Name] - Reason: [why this is a dependency]
- [ ] F[XXX] - [Feature Name] - Reason: [why this is a dependency]

**Blocks these features (they're waiting on this):**
- [ ] None
- [ ] F[XXX] - [Feature Name] - Reason: [what they need from this]
- [ ] F[XXX] - [Feature Name] - Reason: [what they need from this]

**Requires entities (must exist first):**
- [ ] None
- [ ] [Module/Service name] - Reason: [why required]

**Example:**
```markdown
**Depends on features:**
- [x] F001 - user-authentication - Reason: OAuth requires base auth module
- [ ] F003 - database-setup - Reason: Need User table before adding OAuth fields

**Blocks these features:**
- [ ] F005 - user-profile - Reason: Profile page needs OAuth avatar sync
```

---

## Estimated Complexity

- [ ] Small (1-2 sessions)
- [ ] Medium (3-5 sessions)
- [ ] Large (6-10 sessions)
- [ ] Very Large (10+ sessions)

---

**Next Step:** Share with Claude Code using `/discuss-feature [name]` to start discussion phase.
