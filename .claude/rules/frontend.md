# Frontend Rules (React)

## ⚠️ Reuse First — Check Before Building

Before creating any UI component, check `libs/shared/ui/`:
```bash
ls libs/shared/ui/src/lib/components/
```

If a similar component exists, extend it — don't create a duplicate. If you're building something
that could be reused by future features, put it in `libs/shared/ui/` from the start.

---

## State Management

### Server State: TanStack Query (React Query v5)
ALL API calls must use TanStack Query. Never fetch in `useEffect`.

### Client State: Zustand (only when truly needed)
Only for: complex multi-step UI state, global UI preferences (theme, sidebar).
NOT for: data from API, form state, derived state.

### Form State: React Hook Form + Zod
All forms use React Hook Form with `zodResolver`. Schema from `libs/shared/types/`.

---

## TanStack Query Patterns

### Data-fetching hook
```typescript
// apps/client/src/hooks/api/use-resources.ts
export function useResources(id: string) {
  return useQuery<Resource[]>({
    queryKey: ['resources', id],
    queryFn: async () => {
      const res = await fetch(`/api/v1/resources?id=${id}`, { credentials: 'include' });
      if (!res.ok) throw new Error('Failed to fetch');
      return res.json();
    },
  });
}
```

### Mutation with immediate cache update
```typescript
export function useUpdateResource() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, data }) => { /* ... */ },
    onSuccess: (updated) => {
      // Update cache immediately — don't rely on invalidateQueries alone
      // (refetch may not complete before unmount → stale UI on SPA navigation)
      queryClient.setQueryData(['resources', updated.id], updated);
      queryClient.invalidateQueries({ queryKey: ['resources'] });
    },
  });
}
```

**Symptom of missing `setQueryData`:** Feature works on page refresh but breaks on SPA navigation.

---

## Form Pattern

```typescript
// ✅ Correct — schema from shared types, not duplicated here
import { CreateResourceSchema, type CreateResourceDto } from '@app/types';

export function CreateResourceForm() {
  const form = useForm<CreateResourceDto>({
    resolver: zodResolver(CreateResourceSchema),
    defaultValues: { name: '' },
  });

  const create = useCreateResource();

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit((data) => create.mutate(data))}>
        <FormField control={form.control} name="name" render={({ field }) => (
          <FormItem>
            <FormLabel>Name</FormLabel>
            <FormControl><Input {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )} />
        <Button type="submit" disabled={create.isPending}>
          {create.isPending ? 'Creating...' : 'Create'}
        </Button>
      </form>
    </Form>
  );
}
```

---

## Component Structure

```
apps/client/src/
├── pages/              # Page-level components (one per route)
├── components/         # Feature-specific components (not reusable)
│   ├── forms/
│   ├── layouts/
│   └── modals/
└── hooks/
    └── api/            # TanStack Query hooks (one file per resource)

libs/shared/ui/src/lib/
├── components/         # REUSABLE components — available to all features
└── hooks/              # Shared hooks
```

**Rule:** If a component is used in more than one feature → it goes in `libs/shared/ui/`.

---

## Shadcn / Tailwind

Shadcn components live in `libs/shared/ui/src/lib/components/`.

```typescript
// Always import from the shared UI lib — never re-implement
import { Button, Card, Input, Form, FormField } from '@app/ui';
```

Use `cn()` for conditional classes:
```typescript
import { cn } from '@app/ui';
<div className={cn('base-class', condition && 'conditional-class')} />
```

---

## Types — Never Duplicate

```typescript
// ❌ Never define types locally in the frontend
interface User { id: string; email: string; }

// ✅ Always import from shared types lib
import type { User } from '@app/types';
```

---

## Error Handling

```tsx
// Error boundaries for page-level errors
<ErrorBoundary fallback={<ErrorPage />}>
  <MyPage />
</ErrorBoundary>

// Toast notifications for mutation errors (use your notification lib)
onError: (error) => toast.error(error.message)
```

---

## Performance

```typescript
// Code splitting for large pages
const HeavyPage = lazy(() => import('./pages/heavy-page'));
<Suspense fallback={<PageSkeleton />}><HeavyPage /></Suspense>

// Memoize only when measurably needed
const sorted = useMemo(() => items.sort(compareFn), [items]);
```

---

## Common Mistakes

```typescript
// ❌ Fetch in useEffect — stale data, race conditions, no caching
useEffect(() => {
  fetch('/api/users').then(res => setUsers(res.json()));
}, []);

// ✅ TanStack Query
const { data: users } = useUsers();

// ❌ Duplicate type
interface User { ... }

// ✅ Import from shared types
import type { User } from '@app/types';
```
