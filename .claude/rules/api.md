# API Rules (NestJS)

## Versioning & Routing

**Global prefix:** `/api`
**Versioning:** URI-based (NestJS built-in), default version `1`
**All endpoints:** `/api/v1/*`

```typescript
// apps/api/src/main.ts
import { VersioningType } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bodyParser: false }); // bodyParser off for Better Auth
  app.setGlobalPrefix('api');
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.enableCors({
    origin: process.env['CLIENT_URL'],
    credentials: true,  // required for cookie-based auth
  });
  await app.listen(process.env['API_PORT'] ?? 3333);
}
```

```typescript
// ✅ Correct controller
@Controller('users')  // → /api/v1/users
export class UsersController {}

// ❌ Never hardcode version/prefix
@Controller('api/v1/users')
export class UsersController {}
```

---

## Environment Variables — Zod-validated at boot

Parse `process.env` through a Zod schema in `libs/shared/config/` at boot. Missing or
mistyped vars MUST abort the process — not silently produce `undefined` in a service method.

```typescript
// libs/shared/config/src/lib/env.ts
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']),
  API_PORT: z.coerce.number().int().positive().default(3333),
  DATABASE_URL: z.string().url(),
  BETTER_AUTH_SECRET: z.string().min(32),
  BETTER_AUTH_URL: z.string().url(),
  // Optional integrations — declare per integration:
  REDIS_URL: z.string().url().optional(),
  AXIOM_TOKEN: z.string().optional(),
});

export type Env = z.infer<typeof EnvSchema>;

const parsed = EnvSchema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}
export const env: Env = parsed.data;
```

Use `env.DATABASE_URL` everywhere instead of `process.env['DATABASE_URL']`. The type is
`string`, not `string | undefined`, so callers don't need to null-check. Run this BEFORE
`NestFactory.create(...)` so a bad env aborts before any module wiring.

---

## ⚠️ CRITICAL: Import Rules for Controllers

**NEVER use `import type` for injectable services.** It's erased at compile time — NestJS DI gets `undefined`.

```typescript
// ❌ BAD — service will be undefined at runtime
import type { UserService } from '@app/users';

// ✅ GOOD
import { UserService } from '@app/users';
```

**Also:** Always add explicit `@Inject()` decorators — esbuild strips metadata inconsistently.

```typescript
@Controller('users')
export class UsersController {
  constructor(@Inject(UserService) private userService: UserService) {}

  @Get()
  findAll() {
    return this.userService.findAll();  // ← delegate immediately, no logic here
  }
}
```

---

## Auth Provider — Better Auth (default) or Zitadel

The auth provider is declared in `PROJECT.md` → `auth_provider`:

- **`better-auth`** (default) — library-based, cookie sessions, runs inside the API. Documented below.
- **`zitadel`** — external OIDC identity provider + Management API queries. The Better Auth
  sections below do NOT apply; see `.claude/knowledge/integrations.md` → Zitadel for the JWT
  validation guard and Management-API query patterns.

For **machine-to-machine / API token** auth (separate from human login), enable the `hydra`
integration — see `.claude/knowledge/integrations.md` → Hydra.

---

## Better Auth Integration

```typescript
// libs/shared/auth/src/lib/auth.ts
import { betterAuth } from 'better-auth';
import { prismaAdapter } from 'better-auth/adapters/prisma';

export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: 'postgresql' }),
  emailAndPassword: { enabled: true },
  session: {
    expiresIn: 60 * 60 * 24 * 7,
    cookieCache: { enabled: false },  // disable in dev for freshness
  },
});
```

```typescript
// Register in AppModule
@Module({
  imports: [AuthModule.forRoot({ auth })],  // registers global AuthGuard
})
export class AppModule {}
```

**All routes are protected by default.** To allow anonymous access:

```typescript
@AllowAnonymous()
@Get('public')
async getPublic() { /* ... */ }
```

---

## Reuse: Check Existing Guards Before Creating New Ones

Before creating a new guard, check `libs/backend/core/src/lib/guards/`:
```bash
ls libs/backend/core/src/lib/guards/
```

If you need a new guard, add it there — never inside an app or feature lib.

---

## Validation with Zod

```typescript
// 1. Schema in libs/shared/types/ (single source of truth)
export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
});

// 2. DTO in apps/api/ (derived from schema)
export class CreateUserDto extends createZodDto(CreateUserSchema) {}

// 3. Controller uses DTO (auto-validated by ZodValidationPipe)
@Post()
create(@Body() dto: CreateUserDto) {
  return this.userService.create(dto);
}
```

Register the global pipe once in `main.ts`:
```typescript
app.useGlobalPipes(new ZodValidationPipe());
```

---

## API Contract — OpenAPI (`@nestjs/swagger`)

Every API exposes an OpenAPI document via `@nestjs/swagger`. Set it up once in `main.ts`:

```typescript
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

const config = new DocumentBuilder()
  .setTitle('My API')
  .setVersion('1')
  .addCookieAuth('session')   // or .addBearerAuth() for token auth
  .build();
SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, config));
```

- Swagger UI is served at `/api/docs`; the raw spec at `/api/docs-json`.
- DTOs derived from Zod via `createZodDto` carry their schema into the OpenAPI document
  automatically — keep Zod as the source of truth; don't hand-write `@ApiProperty()` where the
  DTO already describes the shape.
- Annotate controllers with `@ApiTags()` and notable responses with `@ApiResponse()`.
- When the contract changes, export the spec (`/api/docs-json` → `docs/openapi.json`) and
  commit it, so API consumers and the frontend can diff it.

### Generate a typed frontend client from the spec

Run `openapi-typescript` against `docs/openapi.json` to generate a typed fetch client:

```bash
pnpm dlx openapi-typescript docs/openapi.json -o libs/shared/api-client/src/lib/schema.ts
```

Wrap it in a small `apiFetch<RoutePath, Method>()` helper in `libs/shared/api-client/`. The
frontend imports paths + types from the generated module, so a backend rename surfaces as a
TS error in the frontend at compile time. Regenerate as part of CI whenever `docs/openapi.json`
changes.

---

## Security Middleware — `helmet` + `@nestjs/throttler`

Two pieces of middleware every public API needs. Add both in `main.ts` / `AppModule`.

### Security headers — `helmet`

```typescript
import helmet from 'helmet';
app.use(helmet());   // X-Frame-Options, X-Content-Type-Options, CSP, HSTS, etc.
```

### Rate limiting — `@nestjs/throttler`

```typescript
// apps/api/src/app.module.ts
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }])],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}

// Tighten on sensitive routes:
@Throttle({ default: { ttl: 60_000, limit: 5 } })
@Post('login') async login(...) { /* ... */ }
```

CI should fail the build if either is missing — add a smoke test in `apps/api/src/main.spec.ts`.

---

## Error Handling

```typescript
// Domain exception
export class ResourceNotFoundException extends NotFoundException {
  constructor(id: string) {
    super({ message: `Resource ${id} not found`, code: 'RESOURCE_NOT_FOUND' });
  }
}

// Global filter (register once in main.ts or AppModule)
@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    res.status(exception.getStatus()).json({
      error: {
        message: exception.message,
        code: exception.name,
        timestamp: new Date().toISOString(),
      },
    });
  }
}
```

---

## Pagination

```typescript
// Shared schema — reuse across all paginated endpoints
export const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(10),
});

// In service
async findAll({ page, limit }: PaginationQuery) {
  const skip = (page - 1) * limit;
  const [data, total] = await Promise.all([
    this.prisma.resource.findMany({ skip, take: limit }),
    this.prisma.resource.count(),
  ]);
  return { data, meta: { pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } } };
}
```

---

## Health Probes — liveness + readiness

Containers need TWO health probes. They mean different things:

- **Liveness** — "is the process alive?" Cheap, no external calls. If it fails, the
  orchestrator RESTARTS the pod.
- **Readiness** — "can we serve traffic?" Includes DB ping (and Redis ping, etc.). If it
  fails, the orchestrator stops routing traffic but doesn't restart.

```typescript
@Controller('health')
export class HealthController {
  constructor(@Inject(PrismaService) private prisma: PrismaService) {}

  @AllowAnonymous()
  @Get('live')
  live() { return { status: 'ok' }; }

  @AllowAnonymous()
  @Get('ready')
  async ready() {
    await this.prisma.$queryRaw`SELECT 1`;
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  // Backwards-compat alias for /health → readiness
  @AllowAnonymous()
  @Get()
  health() { return this.ready(); }
}
```

Endpoints: `GET /api/v1/health/live`, `GET /api/v1/health/ready`, `GET /api/v1/health` (alias
of readiness). For K8s, point `livenessProbe` at `/live` and `readinessProbe` at `/ready`.

---

## Background Workers — BullMQ (when the `queue` integration is enabled)

### Job idempotency is mandatory

BullMQ retries on failure. A non-idempotent processor will double-charge, double-send, or
duplicate rows. Either use a deterministic `jobId` (`process-payment-${paymentId}`) so
duplicates are deduped at enqueue, or check state at the top of `process()` and return early.

### Retries + backoff + retention

```typescript
BullModule.registerQueue({
  name: 'payments',
  defaultJobOptions: {
    attempts: 5,
    backoff: { type: 'exponential', delay: 5_000 },
    removeOnComplete: { age: 86_400, count: 1_000 },   // 24h history
    removeOnFail: { age: 7 * 86_400 },                  // 7d failure trail for DLQ inspection
  },
});
```

After `attempts` is exhausted, BullMQ leaves the job in `failed` state — listen on the
`failed` event to persist it for manual retry or alerting (a real DLQ).

### Concurrency

Default Worker concurrency is 1. Set per processor based on the job: I/O-bound → higher;
CPU-bound → 1, and run on a separate process. Run workers as a separate Nx app (project type
`worker`) — never inside `apps/api`, where a queue spike will starve HTTP handling.

---

## Controller Checklist

- [ ] Services imported with `import { }` (not `import type`)
- [ ] All constructor params have explicit `@Inject()` decorator
- [ ] Controller delegates immediately — zero business logic
- [ ] `@AllowAnonymous()` on any public routes
- [ ] DTOs derived from Zod schemas in `libs/shared/types/`
- [ ] No database access (goes through service → repository)
