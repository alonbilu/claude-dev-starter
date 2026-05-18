# Stack Gotchas

Critical pitfalls discovered across sessions. Read this before touching any of these areas.

---

## NestJS / Dependency Injection

### NEVER use `import type` for injectable services
`import type` is erased at compile time. NestJS DI needs the class at runtime.

```typescript
// ❌ BAD — service will be undefined at runtime
import type { UserService } from '@app/users';
constructor(private userService: UserService) {}

// ✅ GOOD
import { UserService } from '@app/users';
constructor(private userService: UserService) {}
```

**Error symptom:** `Nest can't resolve dependencies of the ClassName (?, ...)`

### esbuild strips decorator metadata inconsistently
The `@anatine/esbuild-decorators` plugin **does not reliably** emit `design:paramtypes` for all files.
NestJS DI silently injects `undefined` when metadata is missing.

**Fix:** Always add explicit `@Inject(Service)` to ALL constructor params in NestJS injectables:

```typescript
import { Injectable, Inject } from '@nestjs/common';
import { UserService } from '@app/users';
import { EmailService } from '@app/backend-email';

@Injectable()
export class MyService {
  constructor(
    @Inject(UserService) private userService: UserService,
    @Inject(EmailService) private emailService: EmailService,
  ) {}
}
```

**Verify a compiled file has metadata:**
```bash
grep -c "design:paramtypes" dist/apps/api/path/to/file.js
# Should be > 0. If 0, the service will break silently.
```

### reflect-metadata must be imported in entry point AND jest.setup.ts
```typescript
// apps/api/src/main.ts — first line
import 'reflect-metadata';

// jest.setup.ts — first line
import 'reflect-metadata';
```

### `@nestjs/config` does NOT populate `process.env` — `dotenv/config` is required

Battle-tested gotcha. `ConfigModule.forRoot()` parses your `.env` file but **only makes values available via `ConfigService.get()`** — it does NOT write to `process.env`. Any code reading `process.env.FOO` directly will get `undefined` in production, even though the key is in `.env`. PM2 also doesn't source `.env` automatically.

**Fix:** add `import 'dotenv/config'` as the **first import** in `apps/api/src/main.ts`:

```typescript
// apps/api/src/main.ts — FIRST import, before anything else
import 'dotenv/config';
import 'reflect-metadata';
// ... rest of imports
```

This loads `.env` into `process.env` globally, making both `ConfigService` AND direct `process.env` access work.

**Also:** use bracket notation `process.env['VAR_NAME']` — not dot notation. esbuild replaces `process.env.VAR_NAME` patterns at build time (dead-code elimination of unused envs), but leaves `process.env['VAR_NAME']` alone:

```ts
// ❌ Dot notation — esbuild may replace/strip at build time
const key = process.env.MY_API_KEY;

// ✅ Bracket notation — always works at runtime
const key = process.env['MY_API_KEY'];
// biome-ignore lint/complexity/useLiteralKeys: esbuild env access
```

Add the Biome ignore comment on bracket-notation lines; Biome's `useLiteralKeys` rule wants dot notation but that's what we're avoiding.

**Symptom:** env var is defined in `.env`, works locally via `npm run start:dev`, but is `undefined` in the service method at runtime on staging. Almost always this bug.

**Deploy note:** `pm2 restart --update-env` propagates new env vars on re-deploy — `pm2 restart` alone does NOT pick up `.env` changes.

---

### Body parser MUST be disabled for Better Auth
```typescript
const app = await NestFactory.create(AppModule, { bodyParser: false });
```

### CORS must include credentials for cookie-based auth
```typescript
app.enableCors({
  origin: process.env.CLIENT_URL,
  credentials: true,   // ← required
});
```

---

## Prisma

### Prisma 7.x datasource block: NO `url = env(...)`
Prisma 7+ reads `DATABASE_URL` automatically. The datasource block should only have `provider` and (if needed) `extensions`.

```prisma
// ✅ Correct (Prisma 7.x)
datasource db {
  provider   = "postgresql"
  extensions = [vector]   // only needed if rag integration is enabled
}

// ❌ Wrong — causes "Unknown argument" error in Prisma 7
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

### PrismaPg 7.x adapter: pass a config object, NOT a `pg.Pool`

In Prisma 7, the `PrismaPg` constructor takes a **config object** — not a `pg.Pool` instance.
Passing a Pool crashes at runtime with a cryptic `ERR_INVALID_ARG_TYPE` from pg-protocol's
serializer. The stack trace points at pg-protocol, not your code, making it hard to diagnose.

```typescript
// ❌ V6 form — crashes on Prisma 7
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
const pool = new Pool({ connectionString: process.env['DATABASE_URL'] });
const adapter = new PrismaPg(pool);          // ← passes a Pool, crashes
const prisma = new PrismaClient({ adapter });
await pool.end();

// ✅ V7 form — the adapter owns the pool internally
import { PrismaPg } from '@prisma/adapter-pg';
const adapter = new PrismaPg({ connectionString: process.env['DATABASE_URL'] });
const prisma = new PrismaClient({ adapter });
await prisma.$disconnect();   // tears down the pool — pool.end() is wrong
```

Custom pool options go inside the same config object (same keys as `pg.Pool`):

```typescript
new PrismaPg({
  connectionString: process.env['DATABASE_URL'],
  connectionTimeoutMillis: 5_000,
  idleTimeoutMillis: 300_000,
  ssl: { rejectUnauthorized: false },
});
```

**Diagnostic clues** — any one of these means this bug: `Writer.addCString` in the stack
trace, `pg-protocol/.../serializer.ts`, `ERR_INVALID_ARG_TYPE`, `"Received an instance of
Object"` from `Buffer.byteLength`, or an integration test hanging forever in `beforeAll`.

**Applies to every site that instantiates `PrismaPg`** — `prisma.service.ts`, `seed.ts`,
integration-test helpers, and data-migration scripts.

### Prisma 7 standalone scripts need a driver adapter — no bare `PrismaClient`

In Prisma 7, standalone scripts (seed, data-migration scripts, test helpers) **cannot** use
`new PrismaClient()` alone — they need the driver-adapter pattern. Plain instantiation throws:

```
PrismaClientInitializationError: PrismaClient needs to be constructed with a
non-empty, valid PrismaClientOptions
```

```typescript
// ✅ Correct for standalone scripts in Prisma 7
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const adapter = new PrismaPg({ connectionString: process.env['DATABASE_URL'] });
const prisma = new PrismaClient({ adapter });
// ... use prisma
await prisma.$disconnect();
```

### Hand-craft migration SQL for non-additive schema changes

Prisma auto-generates **lossy** migrations for column renames, `NOT NULL` constraints on
populated tables, and partial unique indexes — it drops + recreates, destroying data.

**Trigger:** the generated migration contains `DROP COLUMN`, `DROP TABLE`, or recreates
something that already holds live data.

```bash
# 1. Create the migration stub WITHOUT applying it
npx prisma migrate dev --create-only --name my_migration \
  --schema=libs/domain/database/prisma/schema.prisma

# 2. Inspect the generated SQL; rewrite the lossy parts:
#    RENAME:   ALTER TABLE "Foo" RENAME COLUMN "oldName" TO "newName";
#    BACKFILL: UPDATE "Foo" SET "col" = (subquery) WHERE "col" IS NULL;
#              ALTER TABLE "Foo" ALTER COLUMN "col" SET NOT NULL;
#    PARTIAL:  CREATE UNIQUE INDEX "Foo_col_idx" ON "Foo"("col") WHERE (condition);

# 3. Apply
npx prisma migrate dev --schema=libs/domain/database/prisma/schema.prisma
```

### Prisma 7.8 migrations: pass `--url=...` explicitly (the `.env` auto-read no longer works for `migrate dev`)

**Verified live on Prisma 7.8 + PostgreSQL 18 (May 2026).** Prisma 7.8 changed the rules
again: the datasource block STILL doesn't carry `url = env(...)`, but `prisma migrate dev` /
`migrate deploy` no longer auto-reads `DATABASE_URL` from `.env`. Instead the CLI expects a
`prisma.config.ts` file at the workspace root, OR a `--url=...` flag on every command.

Without one of those, you get:

```
Error: The datasource.url property is required in your Prisma config file when using prisma migrate dev.
```

**The simplest working pattern** (verified end-to-end against Postgres 18):

```bash
# DATABASE_URL still goes in .env for runtime (the PrismaClient + PrismaPg adapter reads it),
# but the migrate CLI needs --url= explicitly:

source .env   # or: export DATABASE_URL=$(grep ^DATABASE_URL .env | cut -d= -f2 | tr -d '"')

npx prisma migrate dev --name add_users \
  --schema=libs/domain/database/prisma/schema.prisma \
  --url="$DATABASE_URL"

npx prisma generate \
  --schema=libs/domain/database/prisma/schema.prisma
```

**Alternative — a `prisma.config.ts` at workspace root** so the URL doesn't need to be on
every CLI invocation:

```typescript
// prisma.config.ts (workspace root)
import path from 'node:path';
import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: path.join(import.meta.dirname, 'libs/domain/database/prisma/schema.prisma'),
  migrations: {
    path: path.join(import.meta.dirname, 'libs/domain/database/prisma/migrations'),
  },
});
```

Pick one approach and stick with it across the project.

**Nx is still wrong for migrations** for the same original reason (it changes CWD, which
breaks the `dotenv/config` import inside `prisma.config.ts`). Run migrations as raw Prisma
from the workspace root. `pnpm nx run database:generate` / `seed` / `studio` are still fine.

**pnpm 11 + Prisma postinstall:** pnpm 11 blocks Prisma's postinstall by default
(`ERR_PNPM_IGNORED_BUILDS` for `@prisma/engines`, `esbuild`, `prisma`). Either run
`pnpm approve-builds` once to allow them, or just run `prisma generate` explicitly after
install — which the kit's `prisma-generate.sh` hook does on schema edits anyway.

The correct workflow is raw Prisma CLI **from the workspace root**, with an explicit `--schema` flag pointing at your schema:

```bash
# 1. Kill idle DB connections first (avoids advisory-lock timeouts from stale
#    Prisma Studio windows, crashed dev servers, etc.)
docker exec <pg-container> psql -U postgres -d <db_name> -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity \
   WHERE datname = '<db_name>' AND pid <> pg_backend_pid() AND state = 'idle';"

# 2. Run migration from WORKSPACE ROOT with explicit --schema
npx prisma migrate dev --name add_users --schema=libs/domain/database/prisma/schema.prisma

# 3. Regenerate Prisma Client
npx prisma generate --schema=libs/domain/database/prisma/schema.prisma

# 4. Sync test DB schema (separate DB on port 5443, no migration history needed)
npx prisma db push --url="postgresql://postgres:postgres@localhost:5443/<db>_test" \
  --accept-data-loss --schema=libs/domain/database/prisma/schema.prisma
```

**Commands that FAIL (do not use):**

```bash
pnpm nx run database:migrate:dev --name ...          # ❌ Nx cwd change → .env lookup fails
cd libs/domain/database && npx prisma migrate dev    # ❌ no .env in subdirectory
DATABASE_URL=... pnpm nx run database:migrate:dev    # ❌ still fails — Prisma 7.2 config issue
```

Nx targets for `generate` and `seed` may still work (they don't need `DATABASE_URL` from env), but **migrations require it and must run from root**.

**`db push` vs `migrate deploy`:** test DBs use `db push --url=...` because Prisma 7.2's `migrate deploy` requires `url` in the datasource block (which we deliberately don't have). `db push` accepts `--url` explicitly, bypassing the `.env` requirement.

**Why idle connections matter:** Prisma Studio, crashed dev servers, and forgotten `psql` sessions hold advisory locks. Migrations hang forever waiting for the lock. Always terminate idle connections before migrating.

A PostToolUse hook (`.claude/hooks/prisma-generate.sh`) auto-regenerates the client after `schema.prisma` edits during a Claude session. Edits made outside a hooked session still need manual regeneration.

### Prisma custom output path — regenerate after EVERY schema change
If your schema uses a custom `output` in the `generator` block:
```bash
pnpm nx run database:generate   # Always run this after schema changes
```

### PostgreSQL column names: camelCase (no @map = camelCase columns)
Fields without `@map()` → columns are **camelCase** in PostgreSQL.
Raw SQL must use quoted camelCase:

```sql
-- ✅ Correct
SELECT "userId", "createdAt" FROM "User"

-- ❌ Wrong — those columns don't exist
SELECT user_id, created_at FROM user
```

Use `@@map("snake_case_table")` for table names if you prefer snake_case tables with camelCase fields.

---

## Testing

### NEVER use Vitest for the NestJS backend
Vitest's esbuild/SWC does NOT preserve `emitDecoratorMetadata`. Services will be `undefined` in controllers and guards.

**Use Jest with ts-jest for the NestJS backend** (`apps/api` + backend/domain libs). The React
frontend (`apps/client` + frontend libs) uses **Vitest** — it has no decorator-metadata
dependency, so the bug doesn't apply there. Split by app; never cross the runners over.

### `tsconfig.spec.json` must have these exact settings
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true
  }
}
```

### Integration tests need the test database running
```bash
docker compose up -d postgres-test
```
Set `DATABASE_URL` to `DATABASE_URL_TEST` in test files — not the dev database.

### Cross-project tests need explicit `moduleNameMapper` entries

The Nx Jest preset does NOT resolve every `@app/*` alias automatically. When a test in lib A
imports from lib B, add an explicit entry to the consumer's `jest.config.ts`:

```typescript
moduleNameMapper: {
  '^@app/advisor$': '<rootDir>/../../domain/advisor/src/index.ts',
  // ...one line per cross-lib dependency used in tests
}
```

**Symptom:** `Cannot find module '@app/foo'` in tests, even though TypeScript compiles fine.
**Why:** the TS compiler resolves aliases from `tsconfig.base.json`; Jest's resolver does not
inherit them unless the preset propagates them — and it doesn't for every case.

---

## Biome / lint-staged

### Failed lint-staged hook stashes ALL working changes
When `lint-staged` pre-commit hook fails, it stashes uncommitted changes. If `git stash pop` also fails
(e.g., `.nx/` conflicts), the stash is kept but may be hard to recover.

**NEVER run `git stash drop` after a failed commit** — it destroys your work.

**Safe recovery:**
```bash
git show stash@{0}                        # inspect what's in the stash
git checkout -- .nx/                      # clear the conflict source
git stash pop                             # retry popping
```

**Better: fix Biome errors BEFORE committing:**
```bash
npx biome check --write <staged-files>
```

### Common Biome false-alarm patterns
- `suppressions/unused`: Remove `biome-ignore` when the violation no longer exists
- `noUnusedTemplateLiteral`: Use single quotes for strings without `${}`
- `noExplicitAny`: Use `Record<string, unknown>` for generic objects

---

## Better Auth

### Cookie cache should be disabled in development
```typescript
betterAuth({
  session: {
    cookieCache: {
      enabled: false,  // ← keeps session fresh in dev
    },
  },
})
```

### OAuth testing requires a public URL (not localhost)
OAuth providers reject `localhost` redirect URIs. Use ngrok or similar:
```bash
bash scripts/start-ngrok.sh
```
Then set `BETTER_AUTH_URL` to the ngrok URL.

---

## React Query (TanStack Query v5)

### Update cache immediately on mutation — don't rely on invalidateQueries alone
If a DB field seeds component state on mount, the cache must be updated alongside the DB.
`invalidateQueries` triggers a refetch that may not complete before unmount.

```typescript
// ✅ Correct — update cache AND invalidate
onSuccess: (result) => {
  queryClient.setQueryData(['resource', id], result);
  queryClient.invalidateQueries({ queryKey: ['resources'] });
}
```

**Symptom of stale cache:** Feature works on page REFRESH but not on SPA navigation.

### `useMutation` objects in a `useEffect` dependency array cause infinite loops

Putting a `useMutation` result in a `useEffect` dependency array triggers infinite re-runs:
calling `.mutate()` changes the mutation's internal state (`isPending`), which produces a new
object reference, which re-fires the effect while the trigger condition is still true.

**Fix — `useRef` guard:**

```typescript
const completingRef = useRef(false);
const mutationRef = useRef(myMutation);
mutationRef.current = myMutation;   // keep the ref current WITHOUT adding it to deps

useEffect(() => {
  if (!operationId || completingRef.current) return;
  if (statusData?.status === 'COMPLETED') {
    completingRef.current = true;
    mutationRef.current.mutate(
      { operationId },
      {
        onSuccess: () => { completingRef.current = false; setOperationId(null); },
        onError: () => { completingRef.current = false; setOperationId(null); },
      },
    );
  }
}, [statusData?.status, operationId]);   // ← minimal deps, NO mutation objects
```

Move mutation objects and callbacks into refs (updated by assignment, not via deps), add a
boolean re-entry guard, and keep the dependency array to only the values that should re-trigger.

---

## Zod

### z.preprocess() goes at item level, not field level
When you need cross-field normalization, apply `z.preprocess()` at the object level:

```typescript
// ❌ Wrong — field-level preprocess can't access sibling fields
const Schema = z.object({ name: z.preprocess(trim, z.string()) });

// ✅ Correct — item-level preprocess runs before field validation
const Schema = z.preprocess(
  (raw) => {
    if (typeof raw !== 'object' || !raw) return raw;
    const obj = raw as Record<string, unknown>;
    return { ...obj, name: String(obj.name ?? '').trim() };
  },
  z.object({ name: z.string().min(1) })
);
```

---

## TypeScript Strict Mode

### process.env requires bracket notation
With `strict: true` or `noPropertyAccessFromIndexSignature: true`:

```typescript
// ❌ Error in strict mode
const key = process.env.MY_API_KEY;

// ✅ Always works
const key = process.env['MY_API_KEY'];
```

### Import Prisma namespace from the workspace database lib, not @prisma/client
```typescript
// ❌ Bypasses Nx boundaries
import { Prisma } from '@prisma/client';

// ✅ Import from your database lib (ensure it re-exports the Prisma namespace)
import { Prisma } from '@app/database';
```

---

## Bundle Size

### Dynamic imports for heavy libraries
Large libs (PPTX, DOCX, PDF generators) should never be in the main bundle:

```typescript
// ❌ Bloats bundle for all users
import PptxGenJs from 'pptxgenjs';

// ✅ Loaded only when needed
async function exportToPptx(data: SlideData[]) {
  const { default: PptxGenJs } = await import('pptxgenjs');
  const pptx = new PptxGenJs();
}
```

---

## Nx Workspace

### After generating a domain lib: remove the `build` target from project.json
Domain libs are consumed directly — they don't need separate builds. The build target causes
confusion and errors when running `pnpm nx affected -t build`.

```bash
# After generating:
pnpm nx g @nx/js:library my-feature --directory=libs/domain/my-feature

# Remove from libs/domain/my-feature/project.json:
# "build": { ... }   ← delete this entire target
```

---

## Scaffolding & Tooling

Battle-tested gotchas from a real `scripts/init-workspace.sh` run by a downstream user.
**Every script that touches a project's filesystem should start with these guards.**

### Always anchor scripts to the project root with a cwd guard

If a user (or another script) runs your scaffolding script from a subdirectory — or worse,
from inside `node_modules/.pnpm/.../*/` (which happens when shells get stuck in weird cwds) —
every `pnpm nx g` and `pnpm add` will write into the wrong place. Symptom from a real run:
**11 corrupted `project.json` files** with `sourceRoot` paths like
`node_modules/.pnpm/unrs-resolver@1.11.1/.../apps/api/src` baked in.

```bash
# Standard preamble for any scaffolding/install script:
set -euo pipefail
cd "$(dirname "$0")/.."
# Sanity check — confirm we landed at the actual project root:
[ -f PROJECT.md ] || { echo "✗ Not at project root (no PROJECT.md)"; exit 1; }
```

### Idempotency — every step needs a "skip if already done" guard

Re-running a partial scaffolding script otherwise blows up:
- `pnpm init` fails with `package.json already exists`
- `pnpm nx g @nx/react:application client` fails with `project already exists`
- `pnpm add` of already-installed deps is wasted time

Wrap each step:

```bash
[ -f package.json ]               || pnpm init
[ -d apps/client ]                || pnpm nx g @nx/react:application --name=client ...
[ -d libs/shared/types ]          || pnpm nx g @nx/js:library --name=types --directory=libs/shared/types ...
```

### pnpm 11 blocks postinstall scripts beyond Prisma

The Prisma gotcha (`ERR_PNPM_IGNORED_BUILDS` for `@prisma/engines` / `esbuild` / `prisma`) is
documented above, but the SAME block hits a wide net of other packages: **`unrs-resolver`**
(which `nx init` pulls in), **`@swc/core`**, **`puppeteer`**, etc. Symptom: `pnpm dlx nx@latest
init` reports a non-zero exit even though the install itself succeeded — `nx init`'s wrapper
sees the postinstall warning's non-zero exit and propagates it.

### CRITICAL: `pnpm-workspace.yaml` `allowBuilds:` is the REAL approval mechanism (not `.npmrc`)

**Battle-tested by a downstream user who burned 90 minutes on this.** Symptoms:

- `pnpm install` / `pnpm nx build` fails with `[ERR_PNPM_IGNORED_BUILDS]` exit 1
- Setting `dangerously-allow-all-builds=true` in `.npmrc` — **ignored**
- Setting `strict-builds=false`, `enable-pre-post-scripts=true` — **ignored**
- Adding every blocked package to `package.json` `pnpm.onlyBuiltDependencies` — **ignored**
- `pnpm rebuild`, `pnpm install --force`, regenerating lockfile — **no effect**

**Root cause:** `nx init` writes a `pnpm-workspace.yaml` with this:

```yaml
allowBuilds:
  '@nestjs/core': set this to true or false
  '@parcel/watcher': set this to true or false
  esbuild: set this to true or false
  ...
  nx: true
```

Only `nx: true` is approved. The other entries contain the **literal placeholder string**
`set this to true or false`, which pnpm interprets as "not true" → still blocked. This file
is where `pnpm approve-builds` writes its answers, and it's the source of truth in pnpm 11
— **`.npmrc` and `package.json` configs are ignored when this file has entries.**

**Fix:** after `nx init`, rewrite `pnpm-workspace.yaml`'s `allowBuilds:` to set every entry
to `true`. The kit's `scripts/init-workspace.sh` does this automatically; if you write your
own scaffold, this is the snippet:

```bash
node -e "
const fs = require('fs');
const builds = ['@biomejs/biome','@nestjs/core','@parcel/watcher','@prisma/client',
  '@prisma/engines','@scarf/scarf','@sentry/cli','@swc/core','esbuild','husky','less',
  'msgpackr-extract','nx','prisma','sharp','unrs-resolver'];
const block = 'allowBuilds:\n' +
  builds.map(k => \"  '\" + k + \"': true\").join('\n') +
  '\nignoredBuiltDependencies: []\n';
let c = fs.existsSync('pnpm-workspace.yaml') ? fs.readFileSync('pnpm-workspace.yaml','utf8') : '';
// strip existing allowBuilds / ignoredBuiltDependencies blocks
let skip = false;
c = c.split('\n').filter(l => {
  if (l.match(/^(allowBuilds|ignoredBuiltDependencies):/)) { skip = true; return false; }
  if (skip && (l.match(/^\s+\S/) || l === '')) return false;
  skip = false; return true;
}).join('\n').replace(/\n+\$/,'\n');
fs.writeFileSync('pnpm-workspace.yaml', c + block);
"
```

`.npmrc` and `package.json.pnpm.onlyBuiltDependencies` STILL serve as documentation of what
the project considers approved; they just aren't the runtime gate in pnpm 11.

### pnpm 11.0.x: `pnpm add -D` doesn't always land in `package.json` devDependencies

Known pnpm 11.0.x bug — `pnpm add -D X` lands the entry in `pnpm-lock.yaml` but skips
writing it to `package.json` `devDependencies`. Fixed in **pnpm 11.5+**. Upgrade with
`npm i -g pnpm@latest`. The kit's scaffold scripts now pin `packageManager: pnpm@11.5.0` in
`package.json` to prevent this.

Defensive preamble for your own scripts — write **before** the first `pnpm install`:

```bash
# package.json — explicit allow-list (this is documentation; allowBuilds in pnpm-workspace.yaml is the runtime gate)
node -e "
  const fs = require('fs');
  const p = JSON.parse(fs.readFileSync('package.json','utf8'));
  p.pnpm = p.pnpm || {};
  p.pnpm.onlyBuiltDependencies = ['@prisma/engines','esbuild','prisma','unrs-resolver','@swc/core'];
  fs.writeFileSync('package.json', JSON.stringify(p,null,2) + '\n');
"

# After installing everything, force any blocked postinstalls to run:
pnpm rebuild
```

### `prepare: "husky"` ordering footgun

If `package.json` has `"scripts": { "prepare": "husky" }` BEFORE `husky` itself is installed,
**every subsequent `pnpm install` fails** with `sh: husky: not found` — including the
`pnpm install` that `pnpm dlx nx init` runs internally. Cascade failure: the whole
scaffolding aborts.

```json
// Order matters in scaffold scripts:
//   1. pnpm add -D husky
//   2. THEN add "prepare": "husky" to package.json
//
// Defensive alternative if you must add it before the install (templates etc):
{
  "scripts": {
    "prepare": "husky || true"
  }
}
```

`scripts/install-pre-commit.sh` does the right thing — adds the script ONLY after
husky is in `node_modules`.

### Nx 22+ generator schemas reject positional args — always pass `--name=`

Nx 22.7+ tightened the generator schemas. Calling
`pnpm nx g @nx/nest:application api ...` fails with:

> Schema does not support positional arguments. Argument 'api' found.

The React generator's schema (`@nx/react:application`) still accepts the positional name in
22.7, but **don't bet on it**. Use the explicit flag for every generator:

```bash
# ✅ Always works on Nx 22+
pnpm nx g @nx/nest:application --name=api --directory=apps/api ...
pnpm nx g @nx/react:application --name=client --directory=apps/client ...
pnpm nx g @nx/js:library --name=types --directory=libs/shared/types ...

# ❌ Schema rejects (intermittent — depends on generator version)
pnpm nx g @nx/nest:application api ...
```

### `npm ls X` doesn't work under pnpm — use a PM-aware dep check

pnpm's strict-flat `node_modules/.pnpm/` layout doesn't expose top-level symlinks the way
npm does, so `npm ls some-package` returns non-zero under pnpm even when the dep IS
installed. Scripts that gate on `npm ls X` (like the kit's original `install-pre-commit.sh`)
bail incorrectly.

**Fix** — check `package.json` directly, which works for any PM:

```bash
dep_present() {
  node -e "
    const p = JSON.parse(require('fs').readFileSync('package.json','utf8'));
    const has = (p.dependencies && p.dependencies['$1']) ||
                (p.devDependencies && p.devDependencies['$1']);
    process.exit(has ? 0 : 1);
  " 2>/dev/null
}
dep_present "@biomejs/biome" || pnpm add -D @biomejs/biome
```

### After generating a domain/shared lib, REMOVE the `build` target

Documented in architecture.md but not scripted anywhere. Without removing it, every
`pnpm nx affected -t build` rebuilds every domain lib that has no consumable artifact, wasting
CI minutes. Bake it into your scaffold script:

```bash
for lib in libs/shared/types libs/shared/utils libs/shared/config libs/domain/database; do
  [ -f "$lib/project.json" ] && node -e "
    const fs=require('fs'), f='$lib/project.json';
    const j=JSON.parse(fs.readFileSync(f,'utf8'));
    if (j.targets) delete j.targets.build;
    fs.writeFileSync(f, JSON.stringify(j,null,2) + '\n');
  "
done
```

### `docker compose up -d` doesn't wait for healthy — your migrate step races it

`docker compose up -d` returns as soon as containers START, not when they're ready. If your
script then runs `prisma migrate dev` or `pnpm nx build api`, it may race a Postgres that's
still in initdb. Always wait for healthy state:

```bash
docker compose up -d
echo "Waiting for postgres to become healthy..."
timeout 60 bash -c '
  until docker compose ps --format json \
    | jq -e ".[] | select(.Service==\"postgres\") | .Health == \"healthy\"" >/dev/null; do
    sleep 2
  done
'
```

### Final scaffold verification: `nx show projects` should print all expected names

Catches every flavour of "the generator silently ran in the wrong cwd / under the wrong
preset / with a stale plugin cache." Add at the very end:

```bash
pnpm nx reset                          # clear stale plugin discovery cache
pnpm rebuild                           # run any postinstalls that were blocked
EXPECTED="api client core database types ui utils config"
ACTUAL=$(pnpm nx show projects 2>/dev/null | sort | tr '\n' ' ')
for name in $EXPECTED; do
  echo "$ACTUAL" | grep -qw "$name" || { echo "✗ Missing project: $name"; exit 1; }
done
echo "✓ All expected projects discovered."
```

### PostgreSQL 18: confirm container reaches healthy state before proceeding

PG 18's `initdb` on a fresh volume occasionally takes longer than the kit's default
`pg_isready` check accommodates, especially on slow disks. If `docker compose up -d` looks
fine but subsequent migrations or queries error with `the database system is starting up`,
extend the healthcheck `retries` in `docker-compose.yml` or add an explicit wait loop
(see "doesn't wait for healthy" above).

### PostgreSQL 18 changed the data-directory mount path

**Verified live.** PG 17 and earlier stored data under `/var/lib/postgresql/data` inside the
official Docker image. **PG 18 changed this** — the data lives in `/var/lib/postgresql/`
itself (compatible with `pg_ctlcluster`), and the old `/data` path is reported as "unused
mount/volume" with the container exiting on boot:

```
Error: in 18+, these Docker images are configured to store database data in a format which
is compatible with "pg_ctlcluster"… data in: /var/lib/postgresql/data (unused mount/volume)
```

**Fix:** change `docker-compose.yml` volume mounts:

```yaml
# ❌ PG <= 17 path — fails silently on PG 18
volumes:
  - postgres_data:/var/lib/postgresql/data

# ✅ PG 18+ path
volumes:
  - postgres_data:/var/lib/postgresql
```

The kit's `docker-compose.yml` template uses the PG 18+ path as of v1.5.1.

### `cd` in a Claude Code Bash tool call PERSISTS across subsequent invocations

When the `/setup-project` wizard runs, it makes many separate Bash tool calls. **The Bash
tool's working directory is preserved between calls.** If any call does
`cd node_modules/.pnpm/.../unrs-resolver && npm run postinstall` (for instance, to manually
re-run a blocked postinstall), the next call's cwd is **also** that directory — and every
subsequent `pnpm nx g` writes `apps/`, `libs/`, and their generated `project.json` /
`tsconfig.json` / `webpack.config.js` files INSIDE the wrong path.

A downstream user hit this in a real /setup-project run — **11 corrupted `project.json`
files**, every one with `sourceRoot` paths baked in like
`node_modules/.pnpm/unrs-resolver@1.11.1/node_modules/unrs-resolver/apps/api/src`.

**Three defenses, layered:**

1. **NEVER `cd` into `node_modules/` in a Bash tool call.** If you must execute something
   inside a transitive dependency, scope the `cd` to a subshell so it doesn't leak:
   `( cd node_modules/.pnpm/.../pkg && some-command )`. The parent shell's cwd is preserved.

2. **Re-anchor at the top of every multi-step Bash invocation:**
   `cd "$PROJECT_ROOT"` as the first line of each call. The kit's
   `scripts/init-workspace.sh` does this once at the script top because it runs as a SINGLE
   bash process (child processes can't change parent's cwd) — but standalone wizard Bash
   calls can each be a separate process, so re-anchor in each.

3. **Assert before every generator:** `[ -f PROJECT.md ] || { echo "wrong cwd"; exit 1; }`
   confirms you're at the project root.

The cwd-persistence is a feature of the Bash tool (it makes multi-step shell flows
ergonomic), but in a scaffolding context it's the worst kind of footgun — silent
corruption with no error until you `cat libs/shared/types/project.json` and see the
buried path.

---

## Debugging

### After an upgrade, a cryptic library error → read the upgrade guide FIRST

When a low-level library (pg-protocol, esbuild, etc.) throws a cryptic error right after you
upgraded a higher-level package (Prisma, Nx, etc.), the instinct is to chase peer-dependency
version mismatches. That instinct is almost always wrong when all the packages are from the
same release line.

**Better heuristic:** read the upgrade guide for the package you bumped BEFORE auditing
peer-dep versions. Breaking API changes are documented there; version-mismatch chasing is
expensive when the real cause is a caller-side API change.

**Example:** `ERR_INVALID_ARG_TYPE` from `pg-protocol/serializer.ts` after a Prisma 6 → 7
bump looked like a `pg` / `pg-protocol` / `adapter-pg` version conflict. It was actually the
`PrismaPg` constructor signature change documented in the Prisma 7 upgrade guide.

---

## Git

### Planning phases belong on main — implementation on a feature branch
- `idea → discussion → spec → dev plan` — just markdown files, safe to commit to main
- `step 1+` of implementation — always on `feature/F[XXX]-[name]` branch
- Commit after EACH step. Batch commits make PRs unreadable and rollback painful.
