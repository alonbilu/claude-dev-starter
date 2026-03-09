# F[XXX] Context — [Feature Name]

> **Quick-load file for session resumption** — read this at the start of any session.
> Keep it ≤1 page (max 500 words). Update it as you learn more.

---

## What We're Building (1 sentence)

[One clear sentence describing what users can now do]

Example: "Users can sign in with Google OAuth instead of email."

---

## Spec & Plan

- **Spec:** `3-spec.md` — Full technical specification
- **Plan:** `4-dev-plan.md` — [N] steps, [Complexity: XS/S/M/L]
- **Current Progress:** Step [X] of [N] complete

---

## Key Decisions Made

- **Database:** [Schema change decision and why]
- **API approach:** [Endpoint design decision and why]
- **Frontend:** [Component/state management decision and why]

---

## Most Important Files

- `libs/domain/[feature]/src/lib/[service].ts` — [why it matters]
- `apps/api/src/app/[feature]/` — [why it matters]
- `apps/client/src/pages/[page].tsx` — [why it matters]

---

## Current State

**Last session:** [YYYY-MM-DD]

**Currently on:** Step [X] — [Step title and what it involves]

**What just happened:**
- [One concrete thing that was built]
- [One decision that was made]

**Where I left off:**
[Exactly 1–2 sentences explaining what you were doing when you stopped.
Enough detail to resume in 30 seconds without re-reading STATUS.md.]

Example: "Just finished the API endpoints for creating invoices. About to write frontend form component."

---

## Next Action (Most Important)

[Single, crystal-clear next thing to do. One sentence.]

Example: "Implement InvoiceForm component with TanStack Query mutation."

---

## Gotchas & Lessons

- **[Gotcha 1]** → How we handle it
- **[Gotcha 2]** → How we handle it

Example:
- **Zod schema timing** → Must update schema before generating migration, otherwise types drift
- **Test DB isolation** → Reset test data between test runs to avoid flakiness

---

## Acceptance Criteria

From spec:

- [ ] [Functional requirement 1]
- [ ] [Functional requirement 2]
- [ ] [Non-functional requirement]
- [ ] [Security requirement]
- [ ] [Tests pass, lint clean, coverage OK]

---

## Quick Links

- **Branch:** `feature/F[XXX]-[name]`
- **Tickets:** [Link to issue/ticket if applicable]
- **API docs:** `/api/v1/[endpoint]` — see spec section 5
- **Database:** See schema in spec section 3
