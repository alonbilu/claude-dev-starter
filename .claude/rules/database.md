# Database Rules

## Stack

**ORM:** Prisma (latest)
**Database:** PostgreSQL 17
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

## ⚠️ CRITICAL: Run Prisma Commands via Nx (not directly)

Prisma CLI needs the correct CWD (`libs/domain/database/`). Nx handles this automatically.

```bash
# ✅ Correct — Nx applies the right cwd
pnpm nx run database:migrate:dev --name add_user_email_verified
pnpm nx run database:generate
pnpm nx run database:seed
pnpm nx run database:studio

# ❌ Wrong — wrong CWD, schema not found
prisma migrate dev
```

---

## Migration Workflow

```bash
# 1. Modify schema.prisma
# 2. Generate migration (descriptive name!)
pnpm nx run database:migrate:dev --name add_user_email_verification

# 3. Review generated SQL in prisma/migrations/
# 4. Test locally
# 5. Commit migration files

# Staging/production (non-interactive):
pnpm nx run database:migrate:deploy
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
2. `pnpm nx run database:migrate:dev --name [descriptive_name]`
3. Update Zod schemas in `libs/shared/types/`
4. Update domain services
5. Update API DTOs
6. Update frontend forms/queries
7. Update seed data
8. Run tests: `pnpm nx affected -t test`

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

## pgvector (RAG Integration Only)

Only needed when `rag` integration is enabled in `PROJECT.md`.

When enabled:
1. Switch `docker-compose.yml` image: `postgres:17` → `pgvector/pgvector:pg17`
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
