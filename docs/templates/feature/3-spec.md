# Feature Specification: [Feature Name]

> **Feature ID:** F[XXX]
> **Status:** Specification
> **Generated:** YYYY-MM-DD
> **Based on:** discussion.md

---

## Executive Summary

**What this feature does:**
[1-2 sentence summary]

**Entities affected:**
- **Modify:** [List existing modules/services being changed]
- **Create:** [List new modules/services/processors being created]

**Timeline:** [Estimated from dev plan]

---

## Requirements (From Discussion)

### Functional Requirements

1. **[Requirement category]**
   - [ ] [Specific requirement]
   - [ ] [Specific requirement]
   - [ ] [Specific requirement]

2. **[Requirement category]**
   - [ ] [Specific requirement]
   - [ ] [Specific requirement]

### Non-Functional Requirements

- **Performance:** [Response time, throughput targets]
- **Security:** [Auth, permissions, data protection]
- **Scalability:** [Expected load, growth patterns]
- **Reliability:** [Uptime, error handling]

---

## Architecture Overview

### System Context

```
[ASCII diagram showing how this feature fits into the system]

User → Frontend → API → Domain Services → Database
                    ↓
              External APIs
```

**Integration points:**
- [Service/API] - For [purpose]
- [Service/API] - For [purpose]

### Data Flow

```
1. [Actor] triggers [action]
2. [Component] validates [data]
3. [Service] processes [operation]
4. [Database] stores [result]
5. [Component] returns [response]
```

---

## Database Changes

### Schema Modifications

#### New Tables

**Table: `[table_name]`**
```prisma
model TableName {
  id        String   @id @default(cuid())
  field1    String
  field2    Int
  field3    DateTime @default(now())

  // Relations
  userId    String
  user      User     @relation(fields: [userId], references: [id])

  @@index([field1])
  @@map("table_name")
}
```

**Purpose:** [What this table stores and why]

#### Modified Tables

**Table: `users` (existing)**
- **Add fields:**
  - `newField: String?` - [Purpose]
  - `anotherField: Json?` - [Purpose]
- **Add indexes:**
  - `@@index([newField])`
- **Add relations:**
  - `relation TableName[]`

### Migrations

**Migration name:** `add_[feature_name]_tables`

**Rollback strategy:** [How to safely rollback if needed]

**Data migration:** [If existing data needs transformation]

---

## Backend Specification

### New Services

#### Service: [ServiceName]

**Location:** `libs/backend/[name]/`

**Purpose:** [What this service does]

**Responsibilities:**
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Public Interface:**
```typescript
export class ServiceName {
  async method1(params: Type): Promise<ReturnType> {
    // [What this does]
  }

  async method2(params: Type): Promise<ReturnType> {
    // [What this does]
  }
}
```

**Dependencies:**
- PrismaService
- [Other services]

**Error Handling:**
- Throws `BadRequestException` when [condition]
- Throws `NotFoundException` when [condition]
- Throws `UnauthorizedException` when [condition]

**External Integrations:**
- [API/Service] - For [purpose]
  - Endpoint: [URL]
  - Auth: [method]
  - Rate limit: [limit]

---

### Modified Services

#### Module: [ExistingModule]

**Location:** `libs/domain/[name]/`

**New methods:**
```typescript
async newMethod(params: Type): Promise<ReturnType> {
  // [What this does]
}
```

**Modified methods:**
```typescript
async existingMethod(params: Type): Promise<ReturnType> {
  // [What changes and why]
}
```

**Why these changes:** [Rationale]

---

### New Processors (Pure Functions)

#### Processor: [ProcessorName]

**Location:** `libs/shared/utils/src/lib/processors/[name].ts`

**Purpose:** [Pure transformation - no side effects]

**Interface:**
```typescript
export function processorName(input: InputType): OutputType {
  // [Transformation logic]
}
```

**Test cases:**
- Input: `[example]` → Output: `[example]`
- Input: `[edge case]` → Output: `[result]`

---

## API Specification

### New Endpoints

#### `POST /api/[resource]`

**Purpose:** [What this endpoint does]

**Auth:** `@UseGuards(AuthGuard)` + `@RequireRole(['admin', 'user'])`

**Request:**
```typescript
// DTO: CreateResourceDto
{
  field1: string;      // [Description, validation rules]
  field2: number;      // [Description, validation rules]
  field3?: boolean;    // [Optional, description]
}
```

**Response:**
```typescript
// Success (201 Created)
{
  id: string;
  field1: string;
  field2: number;
  createdAt: string;
}

// Error (400 Bad Request)
{
  statusCode: 400,
  message: "Validation failed",
  errors: [...]
}
```

**Business Logic:**
1. Validate input against Zod schema
2. Check permissions
3. Call service method
4. Return formatted response

**Validation Rules:**
- `field1`: min 3 chars, max 100 chars, alphanumeric
- `field2`: min 0, max 1000
- `field3`: boolean, defaults to false

---

#### `GET /api/[resource]/:id`

**Purpose:** [What this endpoint does]

**Auth:** `@UseGuards(AuthGuard)`

**Response:**
```typescript
// Success (200 OK)
{
  id: string;
  field1: string;
  // ... full resource
}

// Error (404 Not Found)
{
  statusCode: 404,
  message: "Resource not found"
}
```

---

### Modified Endpoints

#### `PATCH /api/[existing-resource]/:id`

**Changes:**
- Add new field `newField` to request DTO
- Add new validation rules
- Update response to include new fields

**Backward compatibility:** [How existing clients are affected]

---

## Frontend Specification

### New Pages

#### Page: `/[route]`

**Purpose:** [What user does on this page]

**Location:** `apps/client/src/pages/[name]/`

**Components:**
- `[ComponentName]` - [Purpose]
- `[ComponentName]` - [Purpose]

**State Management:**
- React Query for server state: `useQuery(['resource', id])`
- Local state with useState for: [UI state]

**User Flow:**
1. User lands on page
2. Page loads data via `useResourceQuery(id)`
3. User interacts with form
4. Form validates with Zod
5. Submission calls `useCreateResource()` mutation
6. Success → redirect to [page]
7. Error → show toast notification

---

### New Components

#### Component: `[ComponentName]`

**Location:** `apps/client/src/components/[name]/[ComponentName].tsx`

**Purpose:** [What this component does]

**Props:**
```typescript
interface ComponentNameProps {
  prop1: string;
  prop2: number;
  onAction?: (data: Type) => void;
}
```

**State:**
- [State description]

**Behavior:**
- [User interaction] triggers [action]
- [Condition] shows [UI element]

**Accessibility:**
- ARIA labels: [describe]
- Keyboard navigation: [describe]
- Screen reader support: [describe]

---

### Forms

#### Form: `[FormName]`

**Location:** `apps/client/src/components/forms/[FormName].tsx`

**Schema:** `libs/shared/types/src/lib/[name].schema.ts`

**Fields:**
```typescript
const formSchema = z.object({
  field1: z.string().min(3).max(100),
  field2: z.number().min(0).max(1000),
  field3: z.boolean().default(false),
});

type FormData = z.infer<typeof formSchema>;
```

**Validation:**
- Client-side: React Hook Form + Zod (immediate feedback)
- Server-side: NestJS + Zod (security boundary)

**UX:**
- Show validation errors inline
- Disable submit while invalid
- Show loading state during submission
- Show success/error toast after submission

**Integration:**
```typescript
const { mutate, isLoading } = useCreateResource();

const onSubmit = (data: FormData) => {
  mutate(data, {
    onSuccess: () => {
      toast.success('Resource created');
      navigate('/resources');
    },
    onError: (error) => {
      toast.error(error.message);
    },
  });
};
```

---

### Modified Components

#### Component: `[ExistingComponent]`

**Changes:**
- Add new prop: `newProp: Type`
- Update rendering logic to handle [scenario]
- Add new event handler: `onNewAction`

**Backward compatibility:** [How existing usage is affected]

---

## Validation & Error Handling

### Zod Schemas

**Location:** `libs/shared/types/src/lib/[feature].schema.ts`

```typescript
export const ResourceSchema = z.object({
  id: z.string().cuid(),
  field1: z.string().min(3).max(100),
  field2: z.number().int().min(0).max(1000),
  field3: z.boolean().default(false),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Resource = z.infer<typeof ResourceSchema>;

export const CreateResourceSchema = ResourceSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export type CreateResourceInput = z.infer<typeof CreateResourceSchema>;
```

**Shared across:**
- ✅ API DTOs (server validation)
- ✅ React forms (client validation)
- ✅ Database seeding (type safety)
- ✅ Tests (mock data)

---

### Error Scenarios

| Scenario | HTTP Code | User Message | Technical Action |
|----------|-----------|--------------|------------------|
| Invalid input | 400 | "Please check your input" | Show field errors |
| Unauthorized | 401 | "Please log in" | Redirect to login |
| Forbidden | 403 | "You don't have permission" | Show error page |
| Not found | 404 | "Resource not found" | Show 404 page |
| Server error | 500 | "Something went wrong" | Log error, show retry |

**Retry Strategy:**
- Idempotent operations (GET, PUT, DELETE): Auto-retry 3x with exponential backoff
- Non-idempotent (POST): Show "Retry" button, don't auto-retry

---

## Testing Strategy

### Unit Tests

**Backend:**
- [ ] Service methods (libs/backend/[name]/*.spec.ts)
- [ ] Processors (libs/shared/utils/*.spec.ts)
- [ ] Validation schemas (libs/shared/types/*.spec.ts)

**Frontend:**
- [ ] Component rendering (*.test.tsx)
- [ ] Form validation (*.test.tsx)
- [ ] React Query hooks (*.test.ts)

### Integration Tests

**API:**
- [ ] POST /api/[resource] - Create resource
- [ ] GET /api/[resource]/:id - Fetch resource
- [ ] PATCH /api/[resource]/:id - Update resource
- [ ] DELETE /api/[resource]/:id - Delete resource

**Test database:** Use separate test database with migrations

### E2E Tests (Critical Flows)

**Scenario:** [User completes main feature flow]

```typescript
test('User can create and view resource', async ({ page }) => {
  // 1. Navigate to page
  await page.goto('/resources/new');

  // 2. Fill form
  await page.fill('[name="field1"]', 'Test Resource');
  await page.fill('[name="field2"]', '100');

  // 3. Submit
  await page.click('button[type="submit"]');

  // 4. Verify redirect
  await expect(page).toHaveURL(/\/resources\/[\w]+/);

  // 5. Verify data
  await expect(page.locator('h1')).toContainText('Test Resource');
});
```

**Run with:** `pnpm nx e2e client-e2e`

---

## Security Considerations

### Authentication & Authorization

- **Who can access:** [Roles/permissions required]
- **Data isolation:** [How multi-tenant data is separated]
- **API keys:** [If external API keys needed, how stored]

### Data Validation

- ✅ Client-side (UX) + Server-side (security)
- ✅ Zod schemas enforce types at runtime
- ✅ SQL injection prevented by Prisma
- ✅ XSS prevented by React escaping

### Sensitive Data

- **PII fields:** [Which fields contain PII]
- **Encryption:** [What's encrypted at rest/in transit]
- **Access logging:** [What user actions are logged]

---

## Performance Considerations

### Database

- **Indexes:** [Which fields indexed and why]
- **Query optimization:** [N+1 queries prevented, eager loading strategy]
- **Expected load:** [Reads/writes per second]

### Caching

- **React Query:** Cache server data for 5 minutes
- **Backend:** [Any server-side caching]

### Bundle Size

- **New dependencies:** [List any new npm packages and size]
- **Code splitting:** [Which routes lazy-loaded]

---

## Deployment & Rollout

### Environment Variables

**New variables needed:**
```bash
# .env.example
NEW_SERVICE_API_KEY=your_api_key_here
NEW_SERVICE_ENDPOINT=https://api.example.com
```

**Where to add:**
- Local: `.env`
- Production: DigitalOcean App Platform settings

### Database Migration

**Steps:**
1. Deploy migration: `pnpm nx run database:migrate:deploy`
2. Verify migration success
3. If rollback needed: `pnpm nx run database:migrate:rollback`

**Downtime:** [Expected downtime, if any]

### Feature Flags (If Applicable)

```typescript
if (featureFlags.newFeature) {
  // New code
} else {
  // Old code
}
```

**Rollout plan:**
1. Deploy with flag OFF
2. Enable for internal users
3. Monitor for 24h
4. Enable for all users
5. Remove flag after 1 week

---

## Acceptance Criteria

### Functional

- [ ] User can [action] successfully
- [ ] System validates [input] correctly
- [ ] Error messages are clear and actionable
- [ ] Data persists correctly in database
- [ ] All API endpoints return correct status codes
- [ ] Frontend displays loading states
- [ ] Frontend displays error states

### Non-Functional

- [ ] Page loads in < 2 seconds
- [ ] API responds in < 500ms (p95)
- [ ] No console errors in browser
- [ ] No server errors in logs
- [ ] All tests pass (unit, integration, e2e)
- [ ] Lighthouse score > 90
- [ ] Accessible (WCAG 2.1 AA)

### Security

- [ ] Authentication required for protected routes
- [ ] Authorization enforced (only allowed users can access)
- [ ] Input validation on client and server
- [ ] No sensitive data in logs
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities

---

## Dependencies & Risks

### Blockers

**Must complete first:**
- [Feature/entity that must exist]
- [External service setup]

### External Dependencies

- **[Service name]**: [What we depend on, SLA, fallback plan]
- **[API name]**: [Rate limits, error handling]

### Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to mitigate] |
| External API downtime | High | Low | Cache responses, graceful degradation |
| Data migration fails | High | Low | Test on staging, have rollback plan |

---

## Documentation Updates

**Update these docs after implementation:**
- [ ] `docs/architecture/modules/[name].md` - Document new/modified module
- [ ] `docs/architecture/services/[name].md` - Document new service
- [ ] `README.md` - Update if new env vars or setup steps
- [ ] API documentation - Update Swagger/OpenAPI spec

---

## Success Metrics

**How we'll measure success:**
- [Metric]: [Target] (e.g., "95% of forms submitted successfully")
- [Metric]: [Target] (e.g., "< 1% error rate on API calls")
- [Metric]: [Target] (e.g., "User completes flow in < 2 minutes")

**Monitoring:**
- Track with [tool/metric]
- Alert if [condition]

---

**Status:** Specification Complete ✅
**Next Step:** Generate development plan using `/plan-execution [name]`
