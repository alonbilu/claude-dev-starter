# Future Roadmap

Features intentionally **deferred** from the current release. Each entry explains: what it is, when it'd help, why it's not shipped yet, and how a downstream project can implement it early if the need is urgent.

This document is the honest list of "things we thought about but want real data before committing to defaults."

Status legend:
- **Proposed** — design is sketched; no implementation.
- **Prototype elsewhere** — implemented in one downstream project; not yet ready for starter promotion.
- **Under evaluation** — active investigation; may promote to a release soon.

---

## #6 — `/briefing <scope>` Command (Proposed / Prototype elsewhere)

### What it would do

An on-demand **deep-load** of all code relevant to a named subsystem. Think "pre-load the whole payments flow before I start refactoring it" — so Claude doesn't grep-and-read one file at a time for the next 40 minutes.

Scope is project-defined: a subsystem has FE files + BE files + maybe related archived features + known gotchas tagged with the scope.

### Tier-aware by design

- **Opus 1M** — read all matching file contents across every relevant location
- **Sonnet 200k** — read the file tree + exported-symbol signatures only; leave contents for on-demand opens

### When it would help

- Starting a feature that touches unfamiliar parts of the codebase
- Debugging across a whole flow (checkout, reservation, auth)
- Reviewing an architecture area before proposing changes

### Why deferred

1. **The scope vocabulary is project-specific.** `/briefing payments-flow` makes sense only after the project has decided what "payments-flow" means — which files it includes, whether it includes the archived specs that touched it, what related gotchas count. Hard to ship a meaningful default list in a starter kit.
2. **Data needed.** We want to see which scopes actual users ask for most often before burning default slots on them.
3. **Tier-aware behavior is proven elsewhere, but the UX of "what scopes exist" isn't yet.** Users shouldn't need to read a doc to know `/briefing` accepts `payments-flow` but not `payments`.

### How to implement early (if your project needs it)

Add `.claude/commands/briefing.md` with a simple scope table:

```markdown
---
description: On-demand deep-load of all code relevant to a subsystem (tier-aware)
---

Briefing: $ARGUMENTS

## Tier-Aware Behavior

- Opus 1M: load file contents across both FE + BE (+ related archived feature specs)
- Sonnet 200k: load file tree + exported symbols only

## Scope Vocabulary

| Scope | FE paths | BE paths |
|-------|----------|----------|
| `auth` | `src/features/auth/**`, `src/contexts/auth-context.tsx` | `src/auth/**` |
| `payments-flow` | `src/pages/checkout/**`, `src/features/payments/**` | `src/payment/**` |
| ...   | ...      | ...      |

If $ARGUMENTS doesn't match a known scope, ask the user to clarify.

## Steps

1. Parse $ARGUMENTS → identify scope
2. Read per tier (above)
3. Check `.claude/knowledge/stack-gotchas.md` for gotchas tagged with this scope
4. Summarize what's loaded and ask the user what they want to do
```

Keep the scope list as a living map in that file. Add new scopes when you find yourself briefing the same files twice.

### How we'll know it's ready for the starter

When we see multiple downstream projects converging on a similar scope taxonomy and command shape, or when Anthropic publishes a convention for this. Until then, it's opt-in.

---

## #7 — Multi-Feature Mode (Proposed)

### What it would do

Allow a session to have **2–3 active features loaded simultaneously** — e.g., you're wrapping up F041 while starting F043 because they touch adjacent code. Today the starter assumes one mission per session. Multi-feature mode would:

- Let `/resume-feature` load two features' CONTEXT.md + STATUS.md at once
- Let `/start-coding` ambiguate: "which feature?" if multiple are active in this session
- Let `/update-status` update the right one (via explicit arg)

### Viable only on Opus 1M

Loading 2–3 features' docs costs 2–3x what loading one costs. On Sonnet 200k that eats most of the baseline budget. On Opus 1M it's absorbable.

### When it would help

- Two features naturally interleave — both touch the same file, so finishing one without the other creates a merge conflict
- Short cross-feature refactor — "while I'm here, fix the related issue in F042"
- Parallel reviews of two in-flight features

### Why deferred

1. **Attention quality.** Anthropic's own research on long context shows that needle-in-haystack retrieval works at 1M, but reasoning quality softens as context fills with genuinely relevant material. Loading 3 features' worth of specs might still fit the budget but could make Claude's decisions worse on each individual feature.
2. **The "one mission" norm is actually healthy.** It forces clean commits per feature. Multi-feature mode might enable bad habits (mixing commits across features, deferring one to work on another).
3. **No real user ask yet.** If nobody's asking for this, shipping it adds command complexity for zero value.

### How to implement early (if your project needs it)

Two changes:

1. **Update `/resume-feature`** to accept multiple feature names:
   ```
   /resume-feature feat-a feat-b
   ```
   Load both CONTEXTs + STATUSes. Stay on Opus 1M; refuse on Sonnet with a clear message.

2. **Update `/start-coding` and `/update-status`** to require the feature name explicitly when more than one is active. Claude should NOT guess from context.

3. **Keep a session-level disambiguator.** A short comment at the start of each turn: "Currently working on: F042". Makes commit messages and decisions traceable.

Even with this, discipline matters. The first sign that multi-feature mode is hurting you: commits that span two feature IDs, or STATUS.md lines for the wrong feature.

### How we'll know it's ready for the starter

When multiple downstream projects report that single-feature mode is a bottleneck AND Claude 4.7+ or equivalent shows improved cross-context reasoning. Until then, this stays a workaround for specific cases, not a default.

---

## Other Ideas Noted

Small things considered, decided "not yet":

- **Consolidated rules files** (8 → 3-4) — tried in one downstream project; works fine, but the starter's 8-file split has its own clarity benefits. Letting downstream projects choose either way is fine.
- **Audible notification hooks on session events** — tried; too environment-dependent (works in native terminal, flaky in VSCode Remote SSH, impossible on headless servers). Not a good default.
- **`/sync-repos` as a built-in command** — only useful for the multi-repo hub variant (see `MULTI-REPO-HUB.md`). Left to copy-paste from the variant doc rather than shipped in the default install.
- **Tier-aware `/briefing`** (see #6) — would build on the tier-aware work already in the kit; blocked on #6 being ready first.

If you need any of these right now in your own project, the entries above have enough detail to implement early. We'll promote them to the starter when we have data supporting the defaults.

---

## Contributing

If you implement any of these in a downstream project and feel good about the result, open an issue or PR on the starter repo with:

- The final command/doc shape you settled on
- What worked and what didn't
- How big the project was (files, features shipped, sessions per week)

That's the data we need to promote a deferred item to the next release.
