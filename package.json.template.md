# package.json Reference

This file documents the scripts and lint-staged config to add to your root `package.json`.
Copy the relevant sections when initializing a new workspace.

---

## Scripts

```json
{
  "scripts": {
    "check": "biome check .",
    "check:fix": "biome check --write .",
    "format": "biome format --write .",
    "format:check": "biome format .",
    "prepare": "husky"
  }
}
```

## lint-staged (Wires Biome to Pre-Commit Hook)

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "biome check --write --no-errors-on-unmatched --files-ignore-unknown=true"
    ]
  }
}
```

---

## Full Nx Workspace package.json Template

```json
{
  "name": "your-app-name",
  "version": "0.1.0",
  "private": true,
  "packageManager": "pnpm@11.x.x",
  "scripts": {
    "check": "biome check .",
    "check:fix": "biome check --write .",
    "format": "biome format --write .",
    "format:check": "biome format .",
    "prepare": "husky"
  },
  "devDependencies": {
    "@biomejs/biome": "^2.4.0",
    "@nx/esbuild": "22.x.x",
    "@nx/js": "22.x.x",
    "@nx/nest": "22.x.x",
    "@nx/react": "22.x.x",
    "@nx/vite": "22.x.x",
    "@testing-library/jest-dom": "^6.x.x",
    "@testing-library/react": "^16.x.x",
    "@types/jest": "^30.x.x",
    "@types/node": "^22.x.x",
    "@vitejs/plugin-react": "^5.x.x",
    "husky": "^9.x.x",
    "jest": "^30.x.x",
    "jsdom": "^26.x.x",
    "lint-staged": "^16.x.x",
    "nx": "22.x.x",
    "ts-jest": "^29.x.x",
    "typescript": "~5.9.x",
    "vitest": "^3.x.x"
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "biome check --write --no-errors-on-unmatched --files-ignore-unknown=true"
    ]
  }
}
```

---

## Notes

- Nx version should match across all `@nx/*` packages
- Use `pnpm add -D -w [package]` to add workspace-level dev dependencies
- Domain lib dependencies go in the lib's own `package.json` — not the root
- Run `pnpm install` after updating to sync the lockfile
- **Test runners:** Jest (`jest`, `ts-jest`, `@types/jest`) for the NestJS backend; Vitest
  (`vitest`, `@vitejs/plugin-react`, `jsdom`, `@testing-library/*`) for the React frontend.
  Never run NestJS tests under Vitest — see `.claude/rules/testing.md`.

### Database lib (`libs/domain/database/package.json`)

The Prisma driver-adapter setup needs matching versions across three packages:

```json
{
  "dependencies": {
    "@prisma/adapter-pg": "^7.8.0",
    "@prisma/client": "^7.8.0"
  },
  "devDependencies": {
    "prisma": "^7.8.0"
  }
}
```

`PrismaPg` in v7 takes a **config object** — not a `pg.Pool`. See
`.claude/knowledge/stack-gotchas.md` → "PrismaPg 7.x adapter" for the constructor signature.

### API contract — `apps/api/package.json`

The NestJS API needs `@nestjs/swagger` for its OpenAPI document, plus the security middleware
referenced in `.claude/rules/api.md`:

```json
{
  "dependencies": {
    "@nestjs/swagger": "^11.x.x",
    "@nestjs/throttler": "^7.x.x",
    "helmet": "^8.x.x"
  }
}
```

`helmet` and `@nestjs/throttler` are required by `apps/api/src/main.ts` for security headers
and rate limiting (see api.md → "Security Middleware"). The OpenAPI doc is served at
`/api/docs` and exported to `docs/openapi.json` on contract changes.
