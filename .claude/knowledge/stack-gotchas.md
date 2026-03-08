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

### Run Prisma commands from the database lib directory, not workspace root
Prisma CLI looks for `schema.prisma` relative to CWD. Use Nx to ensure correct CWD:

```bash
# ✅ Correct — Nx applies the right cwd automatically
pnpm nx run database:migrate:dev --name my_migration
pnpm nx run database:generate
pnpm nx run database:seed

# ❌ Wrong — wrong CWD, schema not found
prisma migrate dev --name my_migration
```

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
