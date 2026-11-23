# Database Rules

## Stack

**ORM:** Prisma 7.8+ (driver-adapter mode — `@prisma/adapter-pg`)
**Database:** PostgreSQL 18
**Optional:** pgvector (enable when `rag` integration is active)
**Location:** `libs/domain/database/`

---

## ⚠️ CRITICAL: Prisma 7.x Datasource Block

**Never add `url = env("DATABASE_URL")` to the datasource block.**
Prisma 7.x reads `DATABASE_URL` automatically.

```prisma
// ✅ Correct (Prisma 7.x)
datasource db {
  provider   = "postgresql"
  // extensions = [vector]   ← add ONLY if rag integration is enabled
}

// ❌ Wrong — causes error in Prisma 7
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

---

## ⚠️ CRITICAL: Stale Prisma Client = misleading TS errors

Whenever `prisma/schema.prisma` changes (or you `npm install` against a repo where the schema is newer than the cached client), the generated `node_modules/@prisma/client` types go stale. Symptoms — your TS code starts erroring with messages like:

- `Property 'foo' does not exist on type 'PrismaClient<...>'`
- `Namespace 'Prisma' has no exported member 'Decimal'`
- `Module '"@prisma/client"' has no exported member 'flights'`

These look like real bugs in your code. They're not — the client just hasn't been regenerated against the current schema.

**Fix (always safe):**

```bash
npx prisma generate
# OR via Nx if your project structure uses it:
pnpm nx run database:generate
```

The starter's `prisma-generate.sh` PostToolUse hook regenerates automatically after edits to `prisma/schema.prisma`. **But** the hook does NOT fire after `npm install` or `git pull` — those are the moments you must run it manually. Do it as your first action when:

- Pulling a branch that touched the schema
- After `npm install` / `pnpm install` in a repo with Prisma
- Confused by "this code clearly works but TS errors" feelings

When in doubt: `npx prisma generate`. Idempotent and fast.

---

## ⚠️ CRITICAL: Run migrations from the workspace root (NOT via Nx)

Prisma 7.2+ reads `DATABASE_URL` from `.env` in the current working directory. Nx changes the
working directory before invoking Prisma, so the env lookup fails (`Error: datasource.url
property is required`). Always run **migrations** with raw Prisma from the workspace root, with
an explicit `--schema` flag.

```bash
# ✅ Correct — raw Prisma, explicit --schema, from the workspace root
npx prisma migrate dev --name add_user_email_verified \
  --schema=libs/domain/database/prisma/schema.prisma

# ✅ Generate / seed / studio — Nx is fine for these (no DATABASE_URL env lookup)
pnpm nx run database:generate
pnpm nx run database:seed
pnpm nx run database:studio

# ❌ Wrong — Nx changes CWD, .env lookup fails
pnpm nx run database:migrate:dev --name ...
```

See `.claude/knowledge/stack-gotchas.md` → Prisma for the full migration workflow, including
idle-connection cleanup and the `db push` vs `migrate deploy` distinction for test DBs.

---

## ⚠️ CRITICAL: PrismaPg adapter constructor (Prisma 7.x)

Pass a **config object** to `PrismaPg`, not a `pg.Pool` instance. Passing a Pool crashes at
runtime with a cryptic `ERR_INVALID_ARG_TYPE` from pg-protocol's serializer.

```typescript
// ✅ V7 form — the adapter owns the pool
import { PrismaPg } from '@prisma/adapter-pg';

const adapter = new PrismaPg({ connectionString: process.env['DATABASE_URL'] });
const prisma = new PrismaClient({ adapter });
// cleanup:
await prisma.$disconnect();   // do NOT call pool.end()
```

Applies everywhere Prisma is instantiated: `prisma.service.ts`, `seed.ts`, test helpers, and
standalone scripts. Prisma 7 standalone scripts also **require** this adapter — bare
`new PrismaClient()` throws `PrismaClientInitializationError`. See `stack-gotchas.md` → Prisma.

---

## Migration Workflow

```bash
# 1. Modify schema.prisma
# 2. Generate migration — raw Prisma, from workspace root, with --url= (Prisma 7.8+ no
#    longer auto-reads .env for migrate; see stack-gotchas.md for the prisma.config.ts
#    alternative). DATABASE_URL still lives in .env for runtime use.
source .env   # or: export DATABASE_URL=...
npx prisma migrate dev --name add_user_email_verification \
  --schema=libs/domain/database/prisma/schema.prisma \
  --url="$DATABASE_URL"

# 3. Regenerate the Prisma Client (pnpm 11 blocks the postinstall — run explicitly).
npx prisma generate --schema=libs/domain/database/prisma/schema.prisma

# 4. Review generated SQL in prisma/migrations/, test locally, commit migration files.

# Staging/production (non-interactive):
npx prisma migrate deploy \
  --schema=libs/domain/database/prisma/schema.prisma \
  --url="$DATABASE_URL"
```

**Migration naming:** Use descriptive, actionable names:
- ✅ `add_user_email_verification`
- ✅ `create_projects_table`
- ❌ `update_db`, `migration_1`, `fixes`

**Golden rules:**
- NEVER modify committed migrations — create new ones instead
- ALWAYS review generated SQL before applying

---

## Schema Change Protocol — ALL 8 Steps in ONE Session

When modifying a Prisma schema, follow this **exact order** and do NOT defer any step:

1. Update `schema.prisma`
2. `npx prisma migrate dev --name [descriptive_name] --schema=libs/domain/database/prisma/schema.prisma`
3. Update Zod schemas in `libs/shared/types/`
4. Update domain services
5. Update API DTOs
6. Update frontend forms/queries
7. Update seed data
8. Run the full gate: `pnpm verify`

**Never defer to "later session" — this creates type drift across the codebase.**

---

## PostgreSQL Column Naming

Prisma fields without `@map()` → columns are **camelCase** in PostgreSQL.

```sql
-- ✅ Correct raw SQL
SELECT "userId", "createdAt" FROM "User"

-- ❌ Wrong — those columns don't exist
SELECT user_id, created_at FROM user
```

Use `@@map("snake_case_table")` for snake_case table names while keeping camelCase field names.

---

## Repository Pattern

Use repositories for complex, reusable queries. Keep them in `libs/domain/database/src/lib/repositories/`.

```typescript
// libs/domain/database/src/lib/repositories/user.repository.ts
@Injectable()
export class UserRepository {
  constructor(@Inject(PrismaService) private prisma: PrismaService) {}

  async findWithRelations(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { profile: true },
    });
  }
}
```

Simple CRUD? Use Prisma directly in domain services — no repository needed.

---

## Transactions

```typescript
// Use transactions for related operations that must succeed or fail together
await prisma.$transaction([
  prisma.user.create({ data: userData }),
  prisma.account.create({ data: accountData }),
]);
```

---

## Test Database

Integration tests use a separate test DB (port 5443):

```typescript
beforeAll(async () => {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TEST;
  // ...
});
```

Always clear test data between tests:
```typescript
beforeEach(async () => {
  await prisma.user.deleteMany();
});
```

---

## PgBouncer (Connection Pooling)

Serverless and many-instance deployments exhaust Postgres connections fast. Put **PgBouncer**
in front of Postgres in **transaction** pooling mode.

With Prisma 7 driver adapters (`@prisma/adapter-pg`):

- **Runtime queries** go through PgBouncer — point `DATABASE_URL` at the PgBouncer port
  (commonly `6432`) and append `?pgbouncer=true` so Prisma disables prepared statements.
- **Migrations** need a DIRECT connection — PgBouncer's transaction mode can't run them. Keep a
  separate `DIRECT_URL` pointing straight at Postgres and use it when migrating:
  ```bash
  DATABASE_URL="$DIRECT_URL" npx prisma migrate dev \
    --schema=libs/domain/database/prisma/schema.prisma
  ```
- Local single-instance dev usually doesn't need PgBouncer — enable it for staging/production
  and any serverless target.

---

## pgvector (RAG Integration Only)

Only needed when `rag` integration is enabled in `PROJECT.md`.

When enabled:
1. Switch `docker-compose.yml` image: `postgres:18` → `pgvector/pgvector:pg18`
2. Add `extensions = [vector]` to datasource block
3. Schema example:
```prisma
model Document {
  id        String   @id @default(cuid())
  content   String
  embedding Unsupported("vector(1536)")
  metadata  Json?

  @@index([embedding], type: Hnsw)
}
```

---

## Seed Data

```bash
pnpm nx run database:seed
```

Use seeds for development data only. Use migrations for required production data (roles, config).

---

## Common Mistakes

```typescript
// ❌ Import PrismaClient directly
import { PrismaClient } from '@prisma/client';

// ✅ Import from workspace lib
import { PrismaService } from '@app/database';

// ❌ Import Prisma namespace from @prisma/client (violates Nx boundaries)
import { Prisma } from '@prisma/client';

// ✅ Import from workspace lib (ensure it re-exports the namespace)
import { Prisma } from '@app/database';
```
