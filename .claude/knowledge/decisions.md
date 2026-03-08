# Architecture Decisions Log

Record significant architectural decisions here. Format: context → decision → rationale → consequences.

---

## Template

```markdown
## ADR-[N]: [Decision Title]
**Date:** YYYY-MM-DD
**Status:** accepted | superseded | deprecated

### Context
What situation led to this decision?

### Decision
What was decided?

### Rationale
Why this option over alternatives?

### Consequences
What changes as a result? Any trade-offs?
```

---

## ADR-001: Example — Use Zod as single source of truth for types
**Date:** (fill in)
**Status:** accepted

### Context
Need shared types between frontend, backend, and database layer without duplication.

### Decision
All types defined as Zod schemas in `libs/shared/types`. TypeScript types inferred with `z.infer<>`.
Same schema used for: API validation, form validation, DB seeding.

### Rationale
- One schema change propagates everywhere at compile time
- Runtime validation at API boundary for free
- No manual interface maintenance

### Consequences
- Must update types in one session when schema changes (never defer)
- Prisma types are NOT used directly — always re-mapped through Zod schemas
- Heavier `libs/shared/types` but simpler everything else
