## Summary

<!-- What does this PR do? 1-3 bullet points. -->

-

## Changes

<!-- What was changed and why? Group by area if helpful. -->

### Database
<!-- Schema changes, migrations, new tables/columns. Remove if N/A. -->

### API
<!-- New/modified endpoints, DTOs, services. Remove if N/A. -->

### Frontend
<!-- New/modified pages, components, hooks. Remove if N/A. -->

## Test Plan

<!-- How was this tested? What should reviewers verify? -->

- [ ] Unit tests pass (`pnpm nx test [project]`)
- [ ] Lint passes (`pnpm nx affected -t lint`)
- [ ] Build succeeds (`pnpm nx affected -t build`)
- [ ] Manual testing: _describe what you tested_

## Checklist

- [ ] No duplicate code introduced (searched before creating)
- [ ] Types imported from `@app/types` (not defined locally)
- [ ] No `import type` for injectable services
- [ ] Zod schema changes propagated to all 8 targets
- [ ] No `.env` files or secrets committed
- [ ] Migration included if schema changed (descriptive name)

## Related

<!-- Link to feature docs, issues, or other PRs. -->

<!-- Feature: docs/features/active/F[XXX]-[name]/ -->
<!-- Issue: #123 -->
