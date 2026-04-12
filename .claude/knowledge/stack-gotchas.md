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

### Prisma 7.x migrations: run from project root, NEVER via Nx targets

Battle-tested on a real project. Prisma 7.2+ removes `url = env(...)` from the datasource block and reads `DATABASE_URL` from `.env` in CWD. This looks clean but **breaks Nx-wrapped migration commands** — Nx changes the working directory before invoking Prisma, so `.env` lookup fails and you get:

```
Error: datasource.url property is required
```

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

### NEVER use Vitest for NestJS projects
Vitest's esbuild/SWC does NOT preserve `emitDecoratorMetadata`. Services will be `undefined` in controllers and guards.

**Use Jest with ts-jest for everything.**

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

## Git

### Planning phases belong on main — implementation on a feature branch
- `idea → discussion → spec → dev plan` — just markdown files, safe to commit to main
- `step 1+` of implementation — always on `feature/F[XXX]-[name]` branch
- Commit after EACH step. Batch commits make PRs unreadable and rollback painful.
