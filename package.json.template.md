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
  "packageManager": "pnpm@10.x.x",
  "scripts": {
    "check": "biome check .",
    "check:fix": "biome check --write .",
    "format": "biome format --write .",
    "format:check": "biome format .",
    "prepare": "husky"
  },
  "devDependencies": {
    "@biomejs/biome": "^2.4.0",
    "@nx/esbuild": "20.x.x",
    "@nx/js": "20.x.x",
    "@nx/nest": "20.x.x",
    "@nx/react": "20.x.x",
    "@nx/vite": "20.x.x",
    "@types/jest": "^29.x.x",
    "@types/node": "^20.x.x",
    "husky": "^9.x.x",
    "jest": "^29.x.x",
    "lint-staged": "^15.x.x",
    "nx": "20.x.x",
    "ts-jest": "^29.x.x",
    "typescript": "~5.6.x"
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
