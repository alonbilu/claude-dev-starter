---
description: Scaffold a new Architecture Decision Record (ADR) in .claude/knowledge/decisions.md
---

# /new-adr [title]

You are creating a new Architecture Decision Record (ADR) entry in
`.claude/knowledge/decisions.md`.

## What is an ADR?

An **Architecture Decision Record** is a short document capturing a significant technical
choice the team has made, **why** it was made, and what changes as a result. ADRs are how
future contributors (and future-you) understand *why* the codebase looks the way it does —
without having to reconstruct it from git history or guess at the original tradeoffs.

A good ADR:

- Is **scoped to one decision** — not a feature spec, not a code design doc
- Captures the **alternatives that were ruled out** and the reason
- Is **dated**, **numbered** (ADR-001, ADR-002, …), and has a **status**
  (proposed / accepted / superseded / deprecated)
- Is **immutable** once accepted — if the decision changes, add a new ADR that
  **supersedes** the old one rather than rewriting history

ADRs answer questions like: "Why are we using Prisma instead of Drizzle?" "Why did we split
testing between Vitest and Jest?" "Why is auth pluggable?" — and they answer them in 100-300
words, not a 30-minute Slack archaeology session.

If you're tempted to write a long PR description explaining a stack choice — that PR
description is an ADR. Put it in `decisions.md` instead, and link to it from the PR.

## Inputs

- `title` — the decision in 3-8 words (e.g. "Adopt TanStack Router for the frontend")

## What to do

1. Read `.claude/knowledge/decisions.md` and find the highest existing ADR number (e.g.
   ADR-007). Increment by 1 for the new ADR.
2. Use today's date in `YYYY-MM-DD` form.
3. Append a new ADR section at the end of `decisions.md` using this template:

```markdown
---

## ADR-[N]: [title]

**Date:** [YYYY-MM-DD]
**Status:** proposed

### Context

[1-3 sentences. What situation led to this decision? Quote the constraint or pain point
that triggered it.]

### Decision

[1-3 sentences. What was decided?]

### Rationale

[Bulleted list. Why this option over alternatives? What did you rule out and why?]

### Consequences

[Bulleted list. What changes as a result? What new constraints does this create? Any
trade-offs the future team should know about?]
```

4. Tell the user: "ADR-[N] scaffolded. Edit `.claude/knowledge/decisions.md` to fill in the
   sections. When ready, flip `Status: proposed` → `Status: accepted`."

5. **Do NOT auto-fill the sections.** The value of an ADR is the human reasoning. Stub
   headings with `[fill in]` placeholders only.

## When to invoke

- After a significant architectural choice (new lib, swap of a stack tool, new
  cross-cutting pattern)
- Mid-feature when the discussion phase surfaces a decision broader than this feature
- During `/setup-project` for the chosen stack alternatives (auth provider, logging provider,
  router) — those become ADRs future contributors can read

## NOT to invoke

- Trivial code changes (variable rename, bug fix)
- Anything covered by an existing ADR
- Decisions still in flux — wait until you're ready to commit to the choice
