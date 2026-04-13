# Development Plan: [Feature Name]

> **Feature ID:** F[XXX]
> **Status:** Ready for Development
> **Generated:** YYYY-MM-DD
> **Based on:** spec.md

---

## Development Strategy

**Approach:** [Bottom-up / Top-down / Iterative]

**Why this order:**
[Explain the logic behind the step sequence - e.g., "Database first so we can test with real data", "Frontend mockup first to validate UX before building backend"]

**Estimated total time:** [X sessions / Y days]

---

## Pre-Development Checklist

**Before starting Step 1:**
- [ ] Spec approved by stakeholders
- [ ] Design mockups reviewed (if applicable)
- [ ] External API keys obtained (if needed)
- [ ] Database backup created
- [ ] Feature branch created: `feature/F[XXX]-[name]`

---

## Development Steps

### Step 1: Database Schema & Migrations

**Entities affected:** [List modules being modified]

**What to build:**
- [ ] Create/modify Prisma schema in `libs/domain/database/src/lib/schema.prisma`
- [ ] Add new models: `[ModelName]`, `[ModelName]`
- [ ] Modify existing models: `[ModelName]` (add fields: `[field1, field2]`)
- [ ] Add indexes for: `[field]`, `[field]`
- [ ] Add relations: `[ModelA]` → `[ModelB]`

**Commands:**
```bash
# Generate migration
pnpm nx run database:migrate:dev --name add_[feature_name]_schema

# Verify schema
pnpm nx run database:studio

# Update Prisma Client
pnpm nx run database:generate
```

**Validation:**
- [ ] Migration applies without errors
- [ ] Database schema matches spec
- [ ] Can create/read/update/delete via Prisma Studio
- [ ] No breaking changes to existing data
- [ ] Indexes created correctly

**Files changed:**
- `libs/domain/database/src/lib/schema.prisma`
- `libs/domain/database/prisma/migrations/[timestamp]_add_[feature_name]_schema/`

**Estimated time:** [X minutes/hours]

---

### Step 2: Zod Schemas (Single Source of Truth)

**What to build:**
- [ ] Create Zod schema in `libs/shared/types/src/lib/[feature].schema.ts`
- [ ] Define base schema matching Prisma model
- [ ] Create input schemas (Create, Update)
- [ ] Create response schemas (if different from base)
- [ ] Export TypeScript types via `z.infer<>`
- [ ] Add JSDoc comments for documentation

**Schema structure:**
```typescript
// Base entity schema
export const ResourceSchema = z.object({
  id: z.string().cuid(),
  field1: z.string().min(3).max(100),
  // ... all fields matching Prisma
});

export type Resource = z.infer<typeof ResourceSchema>;

// Input schemas
export const CreateResourceSchema = ResourceSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const UpdateResourceSchema = CreateResourceSchema.partial();

export type CreateResourceInput = z.infer<typeof CreateResourceSchema>;
export type UpdateResourceInput = z.infer<typeof UpdateResourceSchema>;
```

**Validation:**
- [ ] Schema compiles without TypeScript errors
- [ ] Can import schema in test file
- [ ] Sample valid data passes validation
- [ ] Sample invalid data fails with correct errors
- [ ] Types exported correctly

**Files changed:**
- `libs/shared/types/src/lib/[feature].schema.ts`
- `libs/shared/types/src/index.ts` (export new schemas)

**Estimated time:** [X minutes/hours]

---

### Step 3: Domain Service (Business Logic)

**Entities affected:** [New service or existing module]

**What to build:**

**If creating NEW service:**
- [ ] Generate service library: `pnpm nx g @nx/js:library [name] --directory=libs/backend/[name]`
- [ ] Create service class: `libs/backend/[name]/src/lib/[name].service.ts`
- [ ] Inject PrismaService dependency
- [ ] Implement business methods: `create()`, `findOne()`, `update()`, `delete()`
- [ ] Add error handling (throw appropriate exceptions)
- [ ] Add logging for important operations
- [ ] Create service module: `libs/backend/[name]/src/lib/[name].module.ts`

**If modifying EXISTING service:**
- [ ] Open existing service: `libs/domain/[module]/src/lib/[module].service.ts`
- [ ] Add new methods per spec
- [ ] Modify existing methods if needed
- [ ] Update error handling
- [ ] Update logging

**Service methods to implement:**
```typescript
export class ResourceService {
  constructor(private prisma: PrismaService) {}

  async create(data: CreateResourceInput): Promise<Resource> {
    // 1. Validate business rules
    // 2. Create in database
    // 3. Return result
  }

  async findOne(id: string): Promise<Resource> {
    // 1. Query database
    // 2. If not found, throw NotFoundException
    // 3. Return result
  }

  async update(id: string, data: UpdateResourceInput): Promise<Resource> {
    // 1. Check exists
    // 2. Validate business rules
    // 3. Update in database
    // 4. Return result
  }

  async delete(id: string): Promise<void> {
    // 1. Check exists
    // 2. Check if safe to delete (no dependencies)
    // 3. Delete from database
  }
}
```

**Validation:**
- [ ] Unit tests pass for all methods
- [ ] Error cases throw correct exceptions
- [ ] Can call methods with valid data
- [ ] Invalid data is rejected
- [ ] Database operations work correctly

**Files changed:**
- `libs/backend/[name]/src/lib/[name].service.ts` (new)
- `libs/backend/[name]/src/lib/[name].module.ts` (new)
- OR `libs/domain/[module]/src/lib/[module].service.ts` (modified)

**Estimated time:** [X minutes/hours]

---

### Step 4: Unit Tests for Service

**What to build:**
- [ ] Create test file: `libs/backend/[name]/src/lib/[name].service.spec.ts`
- [ ] Mock PrismaService
- [ ] Test happy path for each method
- [ ] Test error cases (not found, validation failures)
- [ ] Test edge cases (empty strings, null values, etc.)
- [ ] Achieve > 80% code coverage

**Test structure:**
```typescript
describe('ResourceService', () => {
  let service: ResourceService;
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    service = new ResourceService(prisma);
  });

  describe('create', () => {
    it('should create resource successfully', async () => {
      // Arrange
      const input = { field1: 'test', field2: 100 };
      const expected = { id: '1', ...input, createdAt: new Date() };
      prisma.resource.create.mockResolvedValue(expected);

      // Act
      const result = await service.create(input);

      // Assert
      expect(result).toEqual(expected);
      expect(prisma.resource.create).toHaveBeenCalledWith({ data: input });
    });

    it('should throw BadRequestException for invalid input', async () => {
      // Test validation
    });
  });

  // ... more tests
});
```

**Validation:**
- [ ] Run tests: `pnpm nx test [lib-name]`
- [ ] All tests pass
- [ ] Coverage > 80%
- [ ] No flaky tests (run 3x to verify)

**Files changed:**
- `libs/backend/[name]/src/lib/[name].service.spec.ts`

**Estimated time:** [X minutes/hours]

---

### Step 5: API Layer (Controllers & DTOs)

**What to build:**

**DTOs:**
- [ ] Create DTOs in `apps/api/src/app/[resource]/dto/`
- [ ] `create-[resource].dto.ts` - Use Zod schema with `@nestjs/zod`
- [ ] `update-[resource].dto.ts` - Partial of create DTO
- [ ] `[resource]-response.dto.ts` - Response shape

**Controller:**
- [ ] Create controller in `apps/api/src/app/[resource]/[resource].controller.ts`
- [ ] Add auth guards: `@UseGuards(AuthGuard)`
- [ ] Add role guards: `@RequireRole(['admin', 'user'])`
- [ ] Implement endpoints per spec:
  - `POST /[resource]` - Create
  - `GET /[resource]/:id` - Get one
  - `GET /[resource]` - List (with pagination)
  - `PATCH /[resource]/:id` - Update
  - `DELETE /[resource]/:id` - Delete
- [ ] Use `@Body()`, `@Param()`, `@Query()` decorators
- [ ] Add Swagger decorators: `@ApiTags()`, `@ApiResponse()`
- [ ] Handle errors gracefully (try/catch if needed)

**DTO example:**
```typescript
import { createZodDto } from '@anatine/zod-nestjs';
import { CreateResourceSchema } from '@app/types';

export class CreateResourceDto extends createZodDto(CreateResourceSchema) {}
```

**Controller example:**
```typescript
@ApiTags('resources')
@Controller('resources')
@UseGuards(AuthGuard)
export class ResourceController {
  constructor(private resourceService: ResourceService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiResponse({ status: 201, description: 'Resource created' })
  async create(@Body() dto: CreateResourceDto, @User() user: UserPayload) {
    return this.resourceService.create(dto);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.resourceService.findOne(id);
  }

  // ... more endpoints
}
```

**Module registration:**
- [ ] Update `apps/api/src/app/app.module.ts` to import new module
- [ ] OR create feature module and import service module

**Validation:**
- [ ] Start API: `pnpm nx serve api`
- [ ] Test endpoints with curl/Postman:
  ```bash
  # Create
  curl -X POST http://localhost:3000/api/resources \
    -H "Content-Type: application/json" \
    -d '{"field1":"test","field2":100}'

  # Get
  curl http://localhost:3000/api/resources/[id]
  ```
- [ ] Verify auth required (401 without token)
- [ ] Verify validation works (400 for invalid data)
- [ ] Check Swagger docs: http://localhost:3000/api

**Files changed:**
- `apps/api/src/app/[resource]/dto/create-[resource].dto.ts`
- `apps/api/src/app/[resource]/dto/update-[resource].dto.ts`
- `apps/api/src/app/[resource]/[resource].controller.ts`
- `apps/api/src/app/[resource]/[resource].module.ts`
- `apps/api/src/app/app.module.ts`

**Estimated time:** [X minutes/hours]

---

### Step 6: API Integration Tests

**IMPORTANT: Use Jest (NOT Vitest) for NestJS Integration Tests**

Vitest's ESBuild/SWC transpilation doesn't preserve TypeScript decorator metadata (`emitDecoratorMetadata`) correctly for NestJS's decorator-based dependency injection. Jest with `ts-jest` uses the TypeScript compiler which properly handles decorator metadata.

**What to build:**
- [ ] Create test file: `apps/api/src/app/[resource]/[resource].controller.spec.ts`
- [ ] Test each endpoint
- [ ] Test auth/authorization
- [ ] Test validation errors
- [ ] Test database integration (use dedicated test database)

**Test structure (Jest syntax):**
```typescript
import { Test, type TestingModule } from '@nestjs/testing';
import { type INestApplication } from '@nestjs/common';
import { PrismaService } from '@app/database';
import request from 'supertest';
import { ResourceModule } from './resource.module';

describe('ResourceController (Integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let moduleRef: TestingModule;

  beforeAll(async () => {
    // Set test database URL
    process.env.DATABASE_URL =
      process.env.DATABASE_URL_TEST ||
      'postgresql://postgres:postgres@localhost:5443/blinders_test';

    moduleRef = await Test.createTestingModule({
      imports: [ResourceModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();

    prisma = moduleRef.get<PrismaService>(PrismaService);
  });

  beforeEach(async () => {
    // Reset mocks
    jest.clearAllMocks();
    // Clean up database
    await prisma.resource.deleteMany();
  });

  afterAll(async () => {
    await prisma.resource.deleteMany();
    await app.close();
  });

  describe('POST /api/resources', () => {
    it('should create resource', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/resources')
        .send({ field1: 'test', field2: 100 })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.field1).toBe('test');
    });

    it('should return 401 without auth', async () => {
      await request(app.getHttpServer())
        .post('/api/resources')
        .send({ field1: 'test' })
        .expect(401);
    });

    it('should return 400 for invalid data', async () => {
      await request(app.getHttpServer())
        .post('/api/resources')
        .send({ field1: 'ab' }) // Too short
        .expect(400);
    });
  });

  // ... more tests
});
```

**Running API Integration Tests:**
```bash
# Run all API integration tests with Jest
DATABASE_URL_TEST="postgresql://postgres:postgres@localhost:5443/blinders_test" \
  npx jest --config apps/api/jest.config.ts --runInBand

# Run specific test file
DATABASE_URL_TEST="..." npx jest --config apps/api/jest.config.ts \
  src/app/[resource]/[resource].controller.spec.ts --runInBand
```

**Key differences from Vitest:**
- Use `jest.fn()` instead of `vi.fn()`
- Use `jest.clearAllMocks()` instead of `vi.clearAllMocks()`
- Don't import `describe`, `it`, `expect` from vitest (use Jest globals)

**Validation:**
- [ ] Run tests with Jest (see commands above)
- [ ] All tests pass
- [ ] Coverage > 80% for controller
- [ ] Tests run against dedicated test database (port 5443)

**Files changed:**
- `apps/api/src/app/[resource]/[resource].controller.spec.ts`

**Estimated time:** [X minutes/hours]

---

### Step 7: React Query Hooks (API Client)

**What to build:**
- [ ] Create hooks file: `apps/client/src/hooks/use-[resource].ts`
- [ ] Implement query hooks (GET):
  - `useResource(id)` - Fetch single resource
  - `useResources()` - Fetch list with pagination
- [ ] Implement mutation hooks (POST/PATCH/DELETE):
  - `useCreateResource()` - Create new resource
  - `useUpdateResource()` - Update existing
  - `useDeleteResource()` - Delete resource
- [ ] Configure cache invalidation
- [ ] Add optimistic updates for better UX

**Hook implementation:**
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type { Resource, CreateResourceInput } from '@app/types';

const RESOURCE_KEYS = {
  all: ['resources'] as const,
  lists: () => [...RESOURCE_KEYS.all, 'list'] as const,
  list: (filters: string) => [...RESOURCE_KEYS.lists(), { filters }] as const,
  details: () => [...RESOURCE_KEYS.all, 'detail'] as const,
  detail: (id: string) => [...RESOURCE_KEYS.details(), id] as const,
};

// Query: Get single resource
export function useResource(id: string) {
  return useQuery({
    queryKey: RESOURCE_KEYS.detail(id),
    queryFn: async () => {
      const res = await fetch(`/api/resources/${id}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error('Failed to fetch resource');
      return res.json() as Promise<Resource>;
    },
    enabled: !!id,
  });
}

// Query: Get list of resources
export function useResources() {
  return useQuery({
    queryKey: RESOURCE_KEYS.lists(),
    queryFn: async () => {
      const res = await fetch('/api/resources', {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error('Failed to fetch resources');
      return res.json() as Promise<Resource[]>;
    },
  });
}

// Mutation: Create resource
export function useCreateResource() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateResourceInput) => {
      const res = await fetch('/api/resources', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to create resource');
      return res.json() as Promise<Resource>;
    },
    onSuccess: () => {
      // Invalidate cache to refetch list
      queryClient.invalidateQueries({ queryKey: RESOURCE_KEYS.lists() });
    },
  });
}

// Mutation: Update resource
export function useUpdateResource() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<CreateResourceInput> }) => {
      const res = await fetch(`/api/resources/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to update resource');
      return res.json() as Promise<Resource>;
    },
    onSuccess: (data) => {
      // Update cache with new data
      queryClient.setQueryData(RESOURCE_KEYS.detail(data.id), data);
      queryClient.invalidateQueries({ queryKey: RESOURCE_KEYS.lists() });
    },
  });
}

// Mutation: Delete resource
export function useDeleteResource() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const res = await fetch(`/api/resources/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error('Failed to delete resource');
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: RESOURCE_KEYS.lists() });
      queryClient.removeQueries({ queryKey: RESOURCE_KEYS.detail(id) });
    },
  });
}
```

**Validation:**
- [ ] Hooks compile without TypeScript errors
- [ ] Can import hooks in component
- [ ] Query returns loading/error/data states correctly
- [ ] Mutations trigger cache invalidation
- [ ] Optimistic updates work (if implemented)

**Files changed:**
- `apps/client/src/hooks/use-[resource].ts`

**Estimated time:** [X minutes/hours]

---

### Step 8: Forms with Validation

**What to build:**
- [ ] Create form component: `apps/client/src/components/forms/[Resource]Form.tsx`
- [ ] Use React Hook Form with Zod resolver
- [ ] Import Zod schema from `@app/types`
- [ ] Add form fields with validation
- [ ] Show validation errors inline
- [ ] Show loading state during submission
- [ ] Handle success/error responses

**Form implementation:**
```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { CreateResourceSchema, type CreateResourceInput } from '@app/types';
import { useCreateResource } from '@/hooks/use-resource';
import { toast } from 'sonner';

export function ResourceForm({ onSuccess }: { onSuccess?: () => void }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateResourceInput>({
    resolver: zodResolver(CreateResourceSchema),
  });

  const { mutate: createResource, isLoading } = useCreateResource();

  const onSubmit = (data: CreateResourceInput) => {
    createResource(data, {
      onSuccess: () => {
        toast.success('Resource created successfully');
        onSuccess?.();
      },
      onError: (error) => {
        toast.error(error.message);
      },
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label htmlFor="field1">Field 1</label>
        <input
          id="field1"
          type="text"
          {...register('field1')}
          className={errors.field1 ? 'border-red-500' : ''}
        />
        {errors.field1 && (
          <p className="text-sm text-red-500">{errors.field1.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="field2">Field 2</label>
        <input
          id="field2"
          type="number"
          {...register('field2', { valueAsNumber: true })}
          className={errors.field2 ? 'border-red-500' : ''}
        />
        {errors.field2 && (
          <p className="text-sm text-red-500">{errors.field2.message}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={isLoading || isSubmitting}
        className="btn-primary"
      >
        {isLoading ? 'Creating...' : 'Create Resource'}
      </button>
    </form>
  );
}
```

**Or using Shadcn/ui:**
```typescript
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@app/ui';

export function ResourceForm({ onSuccess }: { onSuccess?: () => void }) {
  const form = useForm<CreateResourceInput>({
    resolver: zodResolver(CreateResourceSchema),
    defaultValues: {
      field1: '',
      field2: 0,
    },
  });

  const { mutate: createResource, isLoading } = useCreateResource();

  const onSubmit = (data: CreateResourceInput) => {
    createResource(data, {
      onSuccess: () => {
        toast.success('Resource created successfully');
        form.reset();
        onSuccess?.();
      },
      onError: (error) => {
        toast.error(error.message);
      },
    });
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <FormField
          control={form.control}
          name="field1"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Field 1</FormLabel>
              <FormControl>
                <Input placeholder="Enter value" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="field2"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Field 2</FormLabel>
              <FormControl>
                <Input
                  type="number"
                  {...field}
                  onChange={(e) => field.onChange(Number(e.target.value))}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={isLoading}>
          {isLoading ? 'Creating...' : 'Create Resource'}
        </Button>
      </form>
    </Form>
  );
}
```

**Validation:**
- [ ] Form renders without errors
- [ ] Can type into fields
- [ ] Validation errors show for invalid input
- [ ] Form submits with valid data
- [ ] Success toast appears on success
- [ ] Error toast appears on failure
- [ ] Form resets after successful submission
- [ ] Submit button disabled while loading

**Files changed:**
- `apps/client/src/components/forms/[Resource]Form.tsx`

**Estimated time:** [X minutes/hours]

---

### Step 9: Pages & Components

**What to build:**

**List Page:**
- [ ] Create `apps/client/src/pages/[resources]/index.tsx`
- [ ] Use `useResources()` hook
- [ ] Show loading skeleton
- [ ] Show error state with retry button
- [ ] Render list of resources
- [ ] Add "Create New" button linking to create page
- [ ] Add pagination (if needed)

**Detail Page:**
- [ ] Create `apps/client/src/pages/[resources]/[id].tsx`
- [ ] Use `useResource(id)` hook
- [ ] Show loading skeleton
- [ ] Show 404 if not found
- [ ] Display resource details
- [ ] Add "Edit" and "Delete" buttons
- [ ] Confirm before delete

**Create Page:**
- [ ] Create `apps/client/src/pages/[resources]/new.tsx`
- [ ] Use `<ResourceForm />` component
- [ ] Redirect to detail page on success

**Edit Page:**
- [ ] Create `apps/client/src/pages/[resources]/[id]/edit.tsx`
- [ ] Load existing data with `useResource(id)`
- [ ] Pre-fill form with current values
- [ ] Use `useUpdateResource()` mutation
- [ ] Redirect to detail page on success

**List Page example:**
```typescript
import { useResources } from '@/hooks/use-resource';
import { Link } from 'react-router-dom';

export function ResourcesPage() {
  const { data: resources, isLoading, error } = useResources();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1>Resources</h1>
        <Link to="/resources/new">
          <button>Create New</button>
        </Link>
      </div>

      <div className="grid gap-4">
        {resources?.map((resource) => (
          <Link key={resource.id} to={`/resources/${resource.id}`}>
            <div className="border p-4 rounded">
              <h2>{resource.field1}</h2>
              <p>{resource.field2}</p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
```

**Routing:**
- [ ] Update `apps/client/src/App.tsx` or router config
- [ ] Add routes for all pages:
  ```typescript
  <Route path="/resources" element={<ResourcesPage />} />
  <Route path="/resources/new" element={<CreateResourcePage />} />
  <Route path="/resources/:id" element={<ResourceDetailPage />} />
  <Route path="/resources/:id/edit" element={<EditResourcePage />} />
  ```

**Validation:**
- [ ] Start client: `pnpm nx serve client`
- [ ] Navigate to list page
- [ ] See loading state, then data
- [ ] Click "Create New", fill form, submit
- [ ] Redirected to detail page
- [ ] See new resource in list
- [ ] Click resource to see details
- [ ] Click "Edit", modify, submit
- [ ] See updated data
- [ ] Click "Delete", confirm, see resource removed

**Files changed:**
- `apps/client/src/pages/[resources]/index.tsx`
- `apps/client/src/pages/[resources]/new.tsx`
- `apps/client/src/pages/[resources]/[id].tsx`
- `apps/client/src/pages/[resources]/[id]/edit.tsx`
- `apps/client/src/App.tsx` (or router config)

**Estimated time:** [X minutes/hours]

---

### Step 10: E2E Tests (Critical Flow)

**What to build:**
- [ ] Create E2E test: `apps/client-e2e/src/[resource].spec.ts`
- [ ] Test complete user journey
- [ ] Use Playwright for browser automation
- [ ] Seed test database with known data
- [ ] Clean up test data after tests

**E2E test example:**
```typescript
import { test, expect } from '@playwright/test';

test.describe('Resource Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login as test user
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL('/dashboard');
  });

  test('User can create, view, edit, and delete resource', async ({ page }) => {
    // 1. Navigate to resources page
    await page.goto('/resources');
    await expect(page.locator('h1')).toContainText('Resources');

    // 2. Click "Create New"
    await page.click('text=Create New');
    await expect(page).toHaveURL('/resources/new');

    // 3. Fill form
    await page.fill('[name="field1"]', 'Test Resource');
    await page.fill('[name="field2"]', '100');
    await page.click('button[type="submit"]');

    // 4. Verify redirect to detail page
    await expect(page).toHaveURL(/\/resources\/[\w]+$/);
    await expect(page.locator('h1')).toContainText('Test Resource');

    // 5. Click "Edit"
    await page.click('text=Edit');
    await expect(page).toHaveURL(/\/resources\/[\w]+\/edit$/);

    // 6. Modify data
    await page.fill('[name="field1"]', 'Updated Resource');
    await page.click('button[type="submit"]');

    // 7. Verify updated
    await expect(page).toHaveURL(/\/resources\/[\w]+$/);
    await expect(page.locator('h1')).toContainText('Updated Resource');

    // 8. Delete resource
    await page.click('text=Delete');
    await page.click('text=Confirm'); // Confirmation dialog
    await expect(page).toHaveURL('/resources');

    // 9. Verify deleted (not in list)
    await expect(page.locator('text=Updated Resource')).not.toBeVisible();
  });

  test('Form validation works', async ({ page }) => {
    await page.goto('/resources/new');

    // Submit empty form
    await page.click('button[type="submit"]');

    // Verify validation errors
    await expect(page.locator('text=Required')).toBeVisible();

    // Fill with invalid data
    await page.fill('[name="field1"]', 'ab'); // Too short
    await page.fill('[name="field2"]', '-1'); // Negative
    await page.click('button[type="submit"]');

    // Verify specific errors
    await expect(page.locator('text=at least 3 characters')).toBeVisible();
    await expect(page.locator('text=must be positive')).toBeVisible();
  });
});
```

**Validation:**
- [ ] Run E2E tests: `pnpm nx e2e client-e2e`
- [ ] All tests pass
- [ ] Tests run in headless mode
- [ ] Can also run with UI: `pnpm nx e2e client-e2e --headed`
- [ ] Screenshots captured on failure

**Files changed:**
- `apps/client-e2e/src/[resource].spec.ts`

**Estimated time:** [X minutes/hours]

---

### Step 11: Polish & Edge Cases

**What to improve:**

**Error Handling:**
- [ ] Add error boundaries for unexpected errors
- [ ] Add retry logic for failed requests
- [ ] Add offline detection and messaging
- [ ] Add toast notifications for all user actions
- [ ] Improve error messages to be user-friendly

**Loading States:**
- [ ] Add skeletons for all loading states
- [ ] Add loading spinners for mutations
- [ ] Disable buttons while loading
- [ ] Show progress indicators for long operations

**Empty States:**
- [ ] Add empty state for no resources
- [ ] Add call-to-action to create first resource
- [ ] Add helpful illustrations or icons

**Accessibility:**
- [ ] Add ARIA labels to all interactive elements
- [ ] Ensure keyboard navigation works
- [ ] Test with screen reader
- [ ] Ensure color contrast meets WCAG AA
- [ ] Add focus indicators

**Responsive Design:**
- [ ] Test on mobile, tablet, desktop
- [ ] Adjust layouts for small screens
- [ ] Use responsive utilities (Tailwind)

**Performance:**
- [ ] Add React Query stale time configuration
- [ ] Implement pagination if list is long
- [ ] Lazy load images if applicable
- [ ] Code split heavy components

**Security:**
- [ ] Verify auth required for all routes
- [ ] Verify CSRF protection enabled
- [ ] Sanitize user input (XSS protection)
- [ ] Add rate limiting (if not done)

**Validation:**
- [ ] Run Lighthouse audit (score > 90)
- [ ] Test with slow 3G connection
- [ ] Test offline behavior
- [ ] Test with screen reader (VoiceOver/NVDA)
- [ ] Manual testing on mobile device

**Files changed:**
- Various component files
- Error boundary components
- Loading/skeleton components

**Estimated time:** [X minutes/hours]

---

### Step 12: Documentation & Deployment

**What to document:**

**Architecture Docs:**
- [ ] Create `docs/architecture/modules/[name].md` (if new module)
- [ ] Update `docs/architecture/modules/[name].md` (if modified)
- [ ] Create `docs/architecture/services/[name].md` (if new service)
- [ ] Document entity structure, relationships, responsibilities

**API Documentation:**
- [ ] Ensure Swagger/OpenAPI spec is up to date
- [ ] Add example requests/responses
- [ ] Document authentication requirements
- [ ] Document rate limits

**README Updates:**
- [ ] Update main README.md if new env vars added
- [ ] Update setup instructions if needed
- [ ] Add troubleshooting section if common issues

**Feature Documentation:**
- [ ] Create user guide (if complex feature)
- [ ] Add screenshots/GIFs of feature
- [ ] Document known limitations

**Deployment Checklist:**
- [ ] Run full test suite: `pnpm nx affected -t test`
- [ ] Run linter: `pnpm nx affected -t lint`
- [ ] Run build: `pnpm nx affected -t build`
- [ ] Test production build locally
- [ ] Create database backup
- [ ] Deploy database migrations: `pnpm nx run database:migrate:deploy`
- [ ] Deploy backend: `docker compose up -d api`
- [ ] Deploy frontend: Update env vars, build, deploy
- [ ] Smoke test production
- [ ] Monitor logs for errors
- [ ] Monitor metrics (response times, error rates)

**Environment Variables:**
- [ ] Add to `.env.example`
- [ ] Add to production environment (DigitalOcean)
- [ ] Document in README

**Validation:**
- [ ] All tests pass in CI
- [ ] Production build succeeds
- [ ] Migration applies cleanly
- [ ] Feature works in production
- [ ] No errors in logs
- [ ] Performance metrics acceptable

**Files changed:**
- `docs/architecture/modules/[name].md`
- `docs/architecture/services/[name].md`
- `README.md`
- `.env.example`

**Estimated time:** [X minutes/hours]

---

## Post-Development

### Final Checklist

**Code Quality:**
- [ ] All tests pass (unit, integration, E2E)
- [ ] Test coverage > 80%
- [ ] No linting errors
- [ ] No TypeScript errors
- [ ] Code reviewed (if team)

**Functionality:**
- [ ] All acceptance criteria met
- [ ] Happy path works end-to-end
- [ ] Error cases handled gracefully
- [ ] Edge cases tested

**Performance:**
- [ ] Lighthouse score > 90
- [ ] API responses < 500ms (p95)
- [ ] Page loads < 2s
- [ ] No memory leaks

**Security:**
- [ ] Authentication required
- [ ] Authorization enforced
- [ ] Input validation (client + server)
- [ ] No sensitive data exposed
- [ ] Security scan passed

**Documentation:**
- [ ] Architecture documented
- [ ] API documented
- [ ] README updated
- [ ] User guide written (if needed)

**Deployment:**
- [ ] Deployed to staging
- [ ] Smoke tested
- [ ] Deployed to production
- [ ] Monitoring configured
- [ ] Rollback plan ready

---

### Update Feature Status

**After completing all steps:**
1. Run `/update-status F[XXX]`
2. Mark feature as "Complete"
3. Move from `docs/features/active/` to `docs/features/completed/`
4. Document any deferred items for future work

---

## Troubleshooting

### Common Issues

**Database migration fails:**
- Check Prisma schema syntax
- Verify database connection
- Check for conflicting migrations
- Solution: Fix schema, delete migration, regenerate

**TypeScript errors after adding types:**
- Run `pnpm nx run database:generate` to update Prisma Client
- Restart TypeScript server in IDE
- Clear `node_modules/.cache`

**API returns 500 errors:**
- Check server logs: `docker compose logs api`
- Verify database seeded correctly
- Check environment variables loaded
- Add more logging to service methods

**React Query not updating:**
- Check cache key consistency
- Verify `invalidateQueries` called after mutations
- Check `enabled` flag on queries
- Use React Query DevTools to inspect cache

**Tests failing intermittently:**
- Add `await` to async operations
- Increase timeouts for slow operations
- Mock external dependencies
- Seed test database consistently

---

## Notes

**Lessons learned:**
[Document anything that was harder than expected, or any gotchas for future reference]

**Deferred items:**
[Any features/improvements deferred to future iterations]

**Future improvements:**
[Ideas for V2 of this feature]

---

**Total Estimated Time:** [Sum of all steps]

**Status:** Ready for Implementation ✅
**Next Step:** `/start-step F[XXX] 1` to begin with Step 1
