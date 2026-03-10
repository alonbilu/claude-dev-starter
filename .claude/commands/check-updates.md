---
description: Check for major version upgrades to stack dependencies (run weekly)
---

# Stack Version Check

You are checking whether any core stack dependencies have major new releases worth upgrading to.
Only recommend upgrades that provide **major improvements** or **important security fixes** — not every minor bump.

## What to check

Search the web for the latest stable versions of these core dependencies (read PROJECT.md to see which are active):

| Dependency | Current default | Check for |
|-----------|----------------|-----------|
| React | 19 | Major release (e.g., React 20) |
| Vite | 6 | Major release |
| Tailwind CSS | v4 | Major release |
| Shadcn/ui | latest | Breaking changes or major redesign |
| TanStack Query | v5 | Major release (v6+) |
| NestJS | 11 | Major release (v12+) |
| Prisma | 7.4 | Major release (v8+) or important minor (security) |
| PostgreSQL | 17 | Major release (18+) — only if stable and LTS-equivalent |
| Better Auth | 1.5 | Major release (2.0+) or important security patch |
| Biome | 2 | Major release (3+) |
| pnpm | 10 | Major release (11+) |
| Zod | 3 | Major release (4+) |
| Jest | 29 | Major release (30+) |
| Nx | 20 | Major release (21+) |

## How to check

For each dependency:
1. Search: `[dependency] latest stable version [current year]`
2. Only flag if there's a **new major version** that is stable (not RC/beta)
3. Check if the upgrade has **security implications** (CVEs, supply chain fixes)

## What to report

**Only report upgrades that meet ONE of these criteria:**
- New major version that's been stable for 1+ months
- Security vulnerability in current version (CVE)
- End-of-life / end-of-support for current version
- Major performance improvement (>2x) or critical bug fix

**Do NOT report:**
- Patch releases (7.4.2 → 7.4.3)
- Minor releases without significant features (unless security)
- Release candidates or beta versions
- Upgrades that would break the template without clear migration path

## Output format

```
Stack Version Check — [date]

🔄 Upgrades available:
  [dependency] [current] → [new version]
  Why: [1-2 sentence explanation — what's the major improvement or security fix]
  Breaking: [yes/no — does it require migration work?]
  Effort: [low/medium/high]
  Recommendation: [upgrade now / wait / skip]

✅ Up to date:
  [list dependencies with no major upgrades available]

⚠️ End of life warnings:
  [any dependencies approaching or past EOL]
```

If nothing needs upgrading:
```
Stack Version Check — [date]

✅ All dependencies are up to date. No major upgrades or security issues found.

Next check: [date + 1 week]
```

## Update the check timestamp

After completing the check, update the timestamp so the weekly reminder resets:
```bash
date +%s > .claude/.last-update-check
```

Add `.claude/.last-update-check` to `.gitignore` if not already there (it's machine-local state).

## After reporting

If upgrades are recommended, ask:
```
Would you like to upgrade any of these? I'll update all version references
across the template (README, rules, docker-compose, CI, etc.) and explain
any migration steps needed.
```

Do NOT automatically upgrade — always let the user decide.
