# Publishing Rules — for projects that publish npm packages

If your project publishes one or more npm packages (private registry, GitHub Packages, or public npm), follow this checklist. Every gotcha here was learned the hard way — published-but-broken patches are painful.

This file is **opt-in**: ignore it if your project is an app, CLI, worker, or anything that doesn't publish a consumable library.

---

## TL;DR — minimum publishing checklist

For each package you publish:

- [ ] `tsconfig.json` has `"declaration": true` (and recommended `"declarationMap": true`)
- [ ] `package.json` has a `"types"` field pointing at the emitted `.d.ts` (`"types": "dist/index.d.ts"`)
- [ ] `.npmignore` does NOT use `*.ts` (it strips your `.d.ts` files too — see below)
- [ ] After build, `dist/` contains both `.js` and `.d.ts` files
- [ ] Before `npm publish`, run `npm pack` and inspect the tarball contents (`tar -tzf <pkg>-X.Y.Z.tgz`) to confirm `.d.ts` files are inside
- [ ] Patch-bump only for type-tightening releases (no runtime change → semver patch)

If any consumer reports `any` types after a fresh install of your latest version, you skipped one of these.

---

## The `.npmignore` trap

Common (broken) `.npmignore`:

```
node_modules
.env
*.ts        ← THIS STRIPS .d.ts FILES TOO
*.map
*.json      ← package.json is auto-included by npm despite this
*.prisma
```

Why it breaks: `.d.ts` files end in `.ts` and match the `*.ts` pattern. Your `tsconfig.json` happily emits them to `dist/` during build, but `npm publish` filters them out of the tarball. Consumers install your package, see no types, and silently get `any` everywhere.

Recommended replacement:

```
node_modules
.env
src/                # exclude source files explicitly (NOT *.ts)
*.tsbuildinfo
prisma/migrations
.git
```

Or use the modern alternative — drop `.npmignore` entirely and use `package.json` `files` array:

```json
{
  "files": ["dist", "README.md", "CHANGELOG.md"]
}
```

The `files` array is **allow-list**, not deny-list — only listed paths ship. Less surprising.

See `.npmignore.template.md` at the workspace root for a copy-pasteable template.

---

## `tsconfig.json` — emit declarations

Make sure these are uncommented in your package's `tsconfig.json`:

```json
{
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true,
    "outDir": "./dist"
  }
}
```

Without `declaration: true`, `tsc` emits only `.js` files. Even if your `package.json` has `"types": "dist/index.d.ts"`, that file won't exist after build — consumers fall back to implicit `any`.

`declarationMap: true` adds `.d.ts.map` files so consumers can "Go to Definition" into your source. Optional but recommended.

---

## `package.json` fields that matter for consumers

```json
{
  "name": "@scope/package-name",
  "version": "0.0.1",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": ["dist", "README.md"],
  "publishConfig": {
    "registry": "https://npm.pkg.github.com/"
  },
  "scripts": {
    "build": "tsc",
    "prepare": "npm run build"
  }
}
```

Notes:
- `"types"` and `"main"` should both point inside `dist/` if that's your output dir
- `"prepare"` runs automatically on `npm publish` — guarantees a fresh build before publish
- `"publishConfig.registry"` pins where this package goes (avoids accidentally publishing private code to public npm)

---

## Pre-publish verification (always do this)

```bash
# 1. Clean build
rm -rf dist && npm run build

# 2. Inspect what would be published — DOES NOT publish
npm pack --dry-run

# 3. Or actually create the tarball locally and inspect
npm pack
tar -tzf @scope-package-name-0.0.1.tgz | grep '\.d\.ts$'
# Should print: package/dist/index.d.ts (and any submodule .d.ts files)

# 4. If happy, publish for real
npm publish

# 5. Always tag the release
git tag "@scope/package-name@0.0.1"
git push origin --tags
```

If step 3 prints nothing, **stop**. Your `.npmignore` or `tsconfig` is broken. Fix before publishing.

---

## Patch vs minor vs major for type-only changes

When you tighten types without changing runtime behavior:

- **Patch (0.0.X → 0.0.X+1)** — default. Old call sites that worked at runtime will compile if your new types accept their existing inputs. From a semver standpoint, types getting stricter IS technically a breaking change for TS consumers, but the npm/JS convention is that types ride patch versions as long as runtime behavior is preserved.
- **Minor** — if you ADD new methods or new exported types but keep all existing ones working.
- **Major** — if you remove or rename public symbols, or tighten types in a way that no caller could plausibly satisfy without changes.

Concretely: if you go from `func(x: any)` → `func(x: number)` and one consumer was passing strings, that's a TS breakage but typically still patched. Document the change in CHANGELOG so consumers know to expect TS errors after the bump.

---

## Cross-consumer audit before publish

If your package has multiple consumer repos, audit them BEFORE publishing:

```bash
# Build locally
npm run build

# For each consumer repo:
cp -r dist/* /path/to/consumer/node_modules/@scope/pkg/dist/
cp package.json /path/to/consumer/node_modules/@scope/pkg/package.json
cd /path/to/consumer && npx tsc --noEmit
```

Catalog the new TS errors per consumer. Decide which are real bugs (fix in consumer) vs over-tight upstream types (fix in your package). Publish only after this loop is clean.

This catches problems pre-publish, when fixing means editing your unpublished code — much cheaper than publishing, then publishing a hotfix patch on top.

---

## Coordinating multi-repo bumps

If you publish a package and have N consumer repos that need to bump:

1. Publish package + git tag
2. Open a feature branch in each consumer: `feature/bump-<pkg>-<version>`
3. Bump version, `npm install`, fix surfaced TS errors
4. PR each consumer separately — each repo's owner reviews their changes
5. Merge order: usually consumers can merge independently (no coordination needed once the package is published) UNLESS there's a runtime contract change

Consumers that aren't ready to bump can pin to the previous version. Don't force-push to the package or unpublish — just leave the old version available.

---

## Common errors and what they mean

| Error in consumer | Likely cause |
|---|---|
| `Cannot find module '@scope/X' or its corresponding type declarations` | Package shipped without `.d.ts` files (`.npmignore` strip) |
| `Property 'foo' does not exist on type '...'` after bump | Your new types are correct; consumer was using a field that doesn't exist (latent bug) |
| `Argument of type 'Decimal' is not assignable to parameter of type 'number'` | Consumer passes Prisma `Decimal` to a `number` param. Wrap with `Number(...)` at call site. |
| `Module '"@scope/X"' has no exported member 'Y'` | Either `Y` was renamed (your fault — should be major bump) or never exported (add to `index.ts` re-exports) |
| Consumer compiles but runtime errors | Types were too loose, or you changed a method body in addition to the signature (don't do that for patch bumps) |

---

## After publishing — confirm the consumer actually gets types

```bash
# In the consumer repo, after npm install
ls node_modules/@scope/pkg/dist/*.d.ts
# Should print: index.d.ts (and any others)

# If empty — your tarball didn't include them. Stop. Republish a patch.
```

Don't trust npm's "✓ published" message — verify the artifact is correct.
