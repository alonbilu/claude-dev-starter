# Reusable Patterns

Common patterns discovered and validated across features. Use these instead of inventing new approaches.

---

## Backend Patterns (NestJS)

### Service with explicit @Inject decorators (always safe)
```typescript
import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '@app/database';
import { UserService } from '@app/users';

@Injectable()
export class MyFeatureService {
  constructor(
    @Inject(PrismaService) private prisma: PrismaService,
    @Inject(UserService) private userService: UserService,
  ) {}
}
```

### Repository pattern for complex queries
```typescript
// libs/domain/database/src/lib/repositories/user.repository.ts
@Injectable()
export class UserRepository {
  constructor(@Inject(PrismaService) private prisma: PrismaService) {}

  async findWithRelations(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { profile: true, subscription: true },
    });
  }

  async countByStatus(status: string): Promise<number> {
    return this.prisma.user.count({ where: { status } });
  }
}
```

### Domain exception pattern
```typescript
// libs/domain/[feature]/src/lib/exceptions/
import { NotFoundException } from '@nestjs/common';

export class ResourceNotFoundException extends NotFoundException {
  constructor(id: string) {
    super({ message: `Resource ${id} not found`, code: 'RESOURCE_NOT_FOUND' });
  }
}
```

### NestJS controller (thin — no logic)
```typescript
@Controller('resources')
export class ResourceController {
  constructor(@Inject(ResourceService) private service: ResourceService) {}

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);  // delegate immediately
  }

  @Post()
  create(@Body() dto: CreateResourceDto, @Session() session: UserSession) {
    return this.service.create(dto, session.user.id);
  }
}
```

### Background job (BullMQ) — only when queue integration is enabled
```typescript
// libs/domain/[feature]/src/lib/processors/my.processor.ts
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';

@Processor('my-queue')
export class MyProcessor extends WorkerHost {
  async process(job: Job) {
    const { data } = job;
    // process...
    return { result: 'done' };
  }
}
```

---

## Frontend Patterns (React)

### TanStack Query data-fetching hook
```typescript
// apps/client/src/hooks/api/use-resources.ts
import { useQuery } from '@tanstack/react-query';
import type { Resource } from '@app/types';

export function useResources(projectId: string) {
  return useQuery<Resource[]>({
    queryKey: ['resources', projectId],
    queryFn: async () => {
      const res = await fetch(`/api/v1/resources?projectId=${projectId}`, {
        credentials: 'include',
      });
      if (!res.ok) throw new Error('Failed to fetch resources');
      return res.json();
    },
  });
}
```

### Mutation with optimistic cache update
```typescript
export function useUpdateResource() {
  const queryClient = useQueryClient();

  return useMutation<Resource, Error, { id: string; data: UpdateResourceDto }>({
    mutationFn: async ({ id, data }) => {
      const res = await fetch(`/api/v1/resources/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to update');
      return res.json();
    },
    onSuccess: (updated) => {
      // Update cache immediately — don't wait for refetch
      queryClient.setQueryData(['resources', updated.id], updated);
      queryClient.invalidateQueries({ queryKey: ['resources'] });
    },
  });
}
```

### Form with Zod validation (React Hook Form)
```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { CreateResourceSchema, type CreateResourceDto } from '@app/types';

export function CreateResourceForm() {
  const form = useForm<CreateResourceDto>({
    resolver: zodResolver(CreateResourceSchema),
    defaultValues: { name: '', description: '' },
  });

  const create = useCreateResource();

  return (
    <form onSubmit={form.handleSubmit((data) => create.mutate(data))}>
      {/* fields */}
      <Button type="submit" disabled={create.isPending}>
        {create.isPending ? 'Creating...' : 'Create'}
      </Button>
    </form>
  );
}
```

### Protected route pattern
```typescript
export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();
  if (isLoading) return <LoadingSpinner />;
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
}
```

---

## Zod Schema Patterns

### Shared schema (single source of truth)
```typescript
// libs/shared/types/src/lib/resource.schema.ts
import { z } from 'zod';

export const ResourceSchema = z.object({
  id: z.string().cuid(),
  name: z.string().min(1).max(100),
  description: z.string().optional(),
  status: z.enum(['active', 'archived']).default('active'),
  createdAt: z.date(),
  ownerId: z.string().cuid(),
});

export const CreateResourceSchema = ResourceSchema.omit({ id: true, createdAt: true });
export const UpdateResourceSchema = CreateResourceSchema.partial();

export type Resource = z.infer<typeof ResourceSchema>;
export type CreateResourceDto = z.infer<typeof CreateResourceSchema>;
export type UpdateResourceDto = z.infer<typeof UpdateResourceSchema>;
```

### NestJS DTO from Zod
```typescript
// apps/api/src/app/resources/dto/create-resource.dto.ts
import { createZodDto } from 'nestjs-zod';
import { CreateResourceSchema } from '@app/types';

export class CreateResourceDto extends createZodDto(CreateResourceSchema) {}
```

---

## Testing Patterns

### Unit test with manual mock (Jest)
```typescript
describe('ResourceService', () => {
  let service: ResourceService;
  let repository: jest.Mocked<ResourceRepository>;

  beforeEach(() => {
    repository = {
      findById: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    } as any;
    service = new ResourceService(repository);
  });

  it('should throw when resource not found', async () => {
    repository.findById.mockResolvedValue(null);
    await expect(service.findById('missing-id')).rejects.toThrow(ResourceNotFoundException);
  });
});
```

### Integration test with test DB (Jest + supertest)
```typescript
describe('ResourceController (Integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    process.env.DATABASE_URL = process.env.DATABASE_URL_TEST;
    const moduleRef = await Test.createTestingModule({
      imports: [ResourceModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    await app.init();
    prisma = moduleRef.get(PrismaService);
  });

  afterAll(() => app.close());
  beforeEach(() => prisma.resource.deleteMany());

  it('POST /api/v1/resources should create resource', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/resources')
      .send({ name: 'Test', ownerId: 'user-1' })
      .expect(201);
    expect(res.body.name).toBe('Test');
  });
});
```
