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

## Health Check

```typescript
@Controller('health')
export class HealthController {
  constructor(@Inject(PrismaService) private prisma: PrismaService) {}

  @AllowAnonymous()
  @Get()
  async check() {
    await this.prisma.$queryRaw`SELECT 1`;
    return { status: 'ok', timestamp: new Date().toISOString() };
  }
}
```

Endpoint: `GET /api/v1/health`

---

## Controller Checklist

- [ ] Services imported with `import { }` (not `import type`)
- [ ] All constructor params have explicit `@Inject()` decorator
- [ ] Controller delegates immediately — zero business logic
- [ ] `@AllowAnonymous()` on any public routes
- [ ] DTOs derived from Zod schemas in `libs/shared/types/`
- [ ] No database access (goes through service → repository)
