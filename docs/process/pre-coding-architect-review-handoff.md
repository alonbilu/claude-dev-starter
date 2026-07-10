# Pre-Coding Architect Review Gate

> Origin: Connected Trips workflow (standard since F002, June 2026); imported into the starter
> 2026-07-10. Evidence from two projects: the CT F002 review found ~half the spec's
> "already-shipped" assumptions had drifted; the first Blinders run (F076+F079) caught 2 BLOCKERS
> + 14 MAJORS before any code (data-corrupting migration, phantom API scoping, missed intake
> paths, contradicting schemas).

---

## 1. What it is — one paragraph

After a feature's specification and development plan are finished, but **before** implementing
step 1, Claude spawns an independent **read-only architect subagent** that reviews all planning
artifacts, verifies every "this already exists" assumption against the *actual shipped code*,
and checks conformance with the project's house rules. The agent reports in a fixed structured
format. Findings are presented to the human, who decides fix vs. defer. **Critical findings block
coding** until resolved or explicitly acknowledged.

## 2. Why — the failure mode it kills

Specs are written against **remembered** code, not real code. The codebase drifts between
planning and coding; the spec inherits phantom APIs; implementation "succeeds" against fictional
shapes; the bug surfaces expensively at integration time. Evidence in THIS repo (2026-07-10 run):
`openAdvisorWithMessage` had no scoping param the spec assumed; a migration would have converted
"React"/"GDPR" blueprint items into product features; 2 of 7 feature-creation paths were unknown
to the plan; a staleness edge was remapped to data its consumer never reads.

## 3. When it triggers

| Situation | Review? |
|---|---|
| `/start-coding` or `/start-step` **step 1** of a formal feature | ✅ Fire automatically (unless STATUS.md shows "Architect Review Gate: DONE" for the current plan) |
| Dev plan revised after a spec change, before resuming | ✅ Fire again on changed sections |
| Steps 2..N, plan unchanged | ❌ Skip |
| `/quick`, `/quickbranch`, `/hotfix`, `/scaffold` | ❌ Skip |
| Work outside the formal feature track | ❌ Skip |

The trigger is convention-enforced: this instruction lives in the `/start-coding` + `/start-step`
commands and in persistent memory. Claude fires it without being asked; the user only sees results.

## 4. The subagent

- Use the read-only **`Plan`** agent type (Read/Grep/Glob/Bash, no Edit/Write). If unavailable,
  use a general agent explicitly instructed: *review only, do not modify any file*.
- **One agent, one comprehensive brief** — cross-document consistency checking requires a single
  context that has read everything.

## 5. What the agent must review

1. **All planning docs, in full:** `docs/features/active/F[XXX]-[name]/` — `1-idea.md`,
   `2-discussion.md`, `3-spec.md`, `4-dev-plan.md`, `STATUS.md`, plus any epic architecture /
   prompt-contract / notes files the feature references.
2. **Spot-check every "already exists" claim against shipped code** (highest-value part):
   services, method signatures, types/fields, env vars, DB tables/columns, endpoints, import
   paths, queue/Redis shapes. Cite `file:line`; mark each VERIFIED or DRIFTED.
3. **House rules:** `.claude/rules/*.md` (architecture layering, import boundaries, Jest-only,
   Biome-only, Zod-as-truth, api/database conventions) + `.claude/brain.md` gotchas.
4. **Plan quality:** step sizing/ordering, missing steps (migration? seed? tests? docs?),
   dependency order.
5. **Design soundness + security:** authz/scoping, failure modes, idempotency, migration safety.

## 6. Required report format

```
## Verdict            — one-line go/no-go + confidence
## Critical issues    — blockers
## High-confidence improvements
## Discussion-worthy  — judgment calls for the human
## Spot-check results — table: claim → VERIFIED/DRIFTED → file:line → actual state
## What's good (don't change)
```

## 7. Gate rules

1. Present full findings to the user before touching step 1 (keep the spot-check table).
2. **The user decides** fix vs. defer — never silently apply suggestions to the spec/plan.
3. **Critical issues hard-block** until resolved or explicitly acknowledged by the user.
4. Record the outcome: write `review-findings.md` (findings + resolutions; ERRATA semantics —
   it WINS over spec/plan on conflict), add an ERRATA banner to `3-spec.md`/`4-dev-plan.md`,
   and mark `STATUS.md` with "Architect Review Gate: DONE <date>" so step 1 doesn't re-fire it.
5. Substantial rewrite of spec/plan → quick re-review of the changed sections.

## 8. Briefing prompt template

Fill `[...]` and pass as the agent's prompt:

```
You are an independent software architect performing a pre-implementation review. You have
read-only access — do NOT modify any file. Your job is to find where this feature's plan
diverges from reality BEFORE any code is written.

FEATURE: F[XXX] [name]
FEATURE DIR: docs/features/active/F[XXX]-[name]/

1. READ IN FULL (no skimming): 1-idea.md, 2-discussion.md, 3-spec.md, 4-dev-plan.md, STATUS.md,
   plus any epic-architecture / prompt-contract / notes docs referenced by them.
   House rules: .claude/rules/architecture.md, api.md, database.md, testing.md, frontend.md,
   code-quality.md. Institutional memory: .claude/brain.md.

2. SPOT-CHECK EVERY "ALREADY EXISTS" CLAIM against the actual code. For EACH assumed dependency
   (service, method signature, type/field, env var, DB table/column, endpoint, import path):
   grep/read the real code and record VERIFIED or DRIFTED with file:line evidence and, if
   drifted, what the code actually is.

3. EVALUATE: architecture soundness (layering, import boundaries, authz/project scoping,
   idempotency, failure modes) · plan quality (step ordering/dependencies, missing steps —
   migration/seed/tests/docs/staleness/embedder/advisor registrations) · house-rules
   conformance · security · migration data-safety.

4. REPORT BACK in exactly this format:
   ## Verdict · ## Critical issues · ## High-confidence improvements · ## Discussion-worthy ·
   ## Spot-check results (claim → VERIFIED/DRIFTED → file:line → actual) ·
   ## What's good (don't change)

Be adversarial: your default assumption is that the spec has drifted from the code. A review
that finds nothing must show the spot-check evidence proving it looked.
```

## 9. Invariants (survive any adaptation)

1. Review **all** planning artifacts, not a sample.
2. **Verify against real code with cited evidence** — a docs-only review is theater.
3. Fixed structured report format.
4. **Human gate**: findings to the user before coding; critical issues hard-block.
5. Proportionality: formal feature track only.
6. Read-only reviewer.
