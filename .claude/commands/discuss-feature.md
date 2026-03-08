---
description: Start discussion phase for a feature idea
---

Discuss Feature: {{FEATURE_NAME}}

## Prerequisites (MUST CHECK FIRST)

1. Find `docs/features/active/F[XXX]-{{FEATURE_NAME}}/`
   - NOT FOUND → STOP. Tell user to run `/new-feature {{FEATURE_NAME}}` first.
2. Read `1-idea.md` — verify it has actual content (not just template placeholders):
   - Has "What I Want to Build" with real content
   - Has at least one user story
   - Has at least one success criterion
   - Still template → STOP. Tell user to fill out `1-idea.md` first.

---

## Steps

1. Read `1-idea.md`
2. Copy `docs/templates/feature/2-discussion.md` to feature directory
3. Fill in "Claude's Understanding" section based on idea
4. Generate clarifying questions

Your role:
- **Understand deeply** — paraphrase what the user wants
- **Ask questions** — one group at a time, don't dump a wall
- **Identify entities** — which existing modules/services need changing? What new ones are needed?
- **Propose approaches** — suggest 2–3 implementation options with pros/cons
- **Assess risks** — flag potential challenges early

Key sections to complete in `2-discussion.md`:
1. **Claude's Understanding** — paraphrase back in your own words
2. **Clarifying Questions** — Q&A to resolve ambiguities
3. **Entity Analysis** — ALL entities created/modified (missing one = rework later)
4. **Alternative Approaches** — 2–3 ways to implement
5. **Risk Assessment** — what could go wrong

When discussion is complete:
- User has answered all questions
- User has chosen an approach
- Update `2-discussion.md` status to "Discussion Complete"
- Tell user: "Run `/generate-spec {{FEATURE_NAME}}` to create the formal specification"

Usage:
/discuss-feature google-oauth
/discuss-feature invoice-generation
