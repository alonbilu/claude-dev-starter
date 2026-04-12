# /trim-context

You are performing an intelligent, **tier-aware** context window audit and trim. Your goal is to reduce the token cost of always-loaded files without losing any knowledge that is genuinely useful.

## Tier Detection

Detect the running model tier and set the target budget:

- **Opus 1M** — model ID contains `1m` (e.g. `claude-opus-4-6[1m]`). Budget: 1,000,000 tokens. Warning threshold: baseline > ~250,000 tokens (25%).
- **Sonnet 200k / Opus non-1M** — Budget: 200,000 tokens. Warning threshold: baseline > ~60,000 tokens (30%).

If model-ID detection is ambiguous, fall back to the declared default in `PROJECT.md` → `claude.max_plan`:
- `x20` → treat as Opus 1M
- `x5` or unset → treat as Sonnet 200k (lean)

**Cadence recommendation by tier:**
- Sonnet 200k: run monthly — context pressure is real.
- Opus 1M: run quarterly — the budget is wide but attention quality still benefits from curation.

---

## Step 1 — Measure Baseline

Read all always-loaded files and report total estimated token count:

```
Context Window Audit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tier: <Opus 1M (budget 1,000,000)  |  Sonnet 200k (budget 200,000)>

Always-loaded files (counted against every session):
  CLAUDE.md                      [N] lines   ~[N]k tokens
  .claude/brain.md               [N] lines   ~[N]k tokens  ← warn if >200 lines
  .claude/rules/ai-workflow.md   [N] lines   ~[N]k tokens
  .claude/rules/architecture.md  [N] lines   ~[N]k tokens
  .claude/rules/api.md           [N] lines   ~[N]k tokens
  .claude/rules/database.md      [N] lines   ~[N]k tokens
  .claude/rules/frontend.md      [N] lines   ~[N]k tokens
  .claude/rules/testing.md       [N] lines   ~[N]k tokens
  .claude/rules/code-quality.md  [N] lines   ~[N]k tokens
  .claude/rules/deployment.md    [N] lines   ~[N]k tokens
  TOTAL always-loaded:                        ~[N]k tokens

Feature docs (loaded on /resume-feature):
  [list active features with their STATUS.md line counts]

Potential savings: [summary of what could be trimmed]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 2 — Scan brain.md for Stale Content

For each section in `.claude/brain.md`, evaluate:

1. **Is this still relevant to the current codebase?**
   (Not about an archived feature, not superseded by newer code)

2. **Is this already covered by a rules/*.md file?**
   (Duplication — replace with a one-line summary + link)

3. **Is this specific to a completed/archived feature?**
   (Can be removed from brain.md — it already lives in the archived feature doc)

4. **Could this move to knowledge/ and be loaded on-demand?**
   (Long gotcha sections → stack-gotchas.md; long patterns → patterns.md)

---

## Step 3 — Scan rules/*.md for Bloat

Check each rules file for:

- **Examples that are obvious** — not edge cases, not gotchas — just noise
- **Sections that duplicate CLAUDE.md** — don't say the same thing twice
- **Rules for inactive integrations** — if payments is disabled in PROJECT.md, Stripe rules don't belong in rules/deployment.md
- **Sections that could be a one-liner** — verbose where concise would do

---

## Step 4 — Present a Trim Plan

Present exactly what you propose to remove or shorten, with before/after sizes:

```
Proposed trims:

brain.md ([current] → [projected] lines, saves ~[N]k tokens/session):
  - Section "[name]" ([N] lines) → [reason: feature archived / duplicates rules/X.md / moved to knowledge/]
  - Section "[name]" ([N] lines) → [reason]

rules/[file].md ([current] → [projected] lines, saves ~[N]k tokens/session):
  - [Section or examples] → [reason]

Projected total savings: ~[N]k tokens per session

Apply all? [yes / review each / cancel]
```

If "review each": walk through each proposed change one at a time, with a yes/no/edit prompt.

---

## Step 5 — Apply with Backup

Before trimming ANYTHING, create a dated backup:

```bash
mkdir -p .claude/context-trim-backup-YYYY-MM-DD
cp .claude/brain.md .claude/context-trim-backup-YYYY-MM-DD/
cp .claude/rules/*.md .claude/context-trim-backup-YYYY-MM-DD/
```

Apply the approved trims, then print:

```
Trimmed. Backup saved to .claude/context-trim-backup-[date]/

  brain.md:          [before] → [after] lines
  rules/ total:      [before] → [after] lines
  Total context:     ~[N]k → ~[N]k tokens ([%] reduction)

Run /trim-context again in 2–3 weeks as content accumulates.
```

---

## What NOT to Touch

- `CLAUDE.md` content (only the user should change this)
- Migration history, decision logs, completed feature archives
- Any section the user explicitly marks as "keep"
- Knowledge files (stack-gotchas.md, patterns.md) — these are already on-demand
