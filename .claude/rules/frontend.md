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

## Routing — TanStack Router

The router is **TanStack Router** (file-based). Routes live in `apps/client/src/routes/`; the
route tree is generated into `routeTree.gen.ts` — never edit that file by hand.

### Typed search params are first-class state

TanStack Router treats URL search params as **typed, validated state** — not strings. Validate
them with a Zod schema from `libs/shared/types/`:

```typescript
// apps/client/src/routes/catalog.tsx
import { createFileRoute } from '@tanstack/react-router';
import { CatalogFiltersSchema } from '@app/types';

export const Route = createFileRoute('/catalog')({
  validateSearch: CatalogFiltersSchema,        // typed + validated search params
  loaderDeps: ({ search }) => ({ search }),
  loader: ({ deps }) => fetchCatalog(deps.search),
  component: CatalogPage,
});

// Reading typed search params anywhere in the route — fully type-safe
const { destination, dateFrom, pax } = Route.useSearch();
```

**Why this matters:** renaming a route param or search key breaks at **compile time** at every
usage site. For filter-heavy UIs (catalog filters, dates, pax, destinations) this catches a
real class of refactor bug.

### Loaders vs TanStack Query

Route `loader`s and TanStack Query are complementary: loaders run on navigation and can prime
the query cache; components still read through `useQuery` for caching, refetch, and mutations.
Use the loader to start the fetch early; keep `useQuery` as the read path.

### Navigation — never hand-build URLs

```typescript
import { Link, useNavigate } from '@tanstack/react-router';

<Link to="/catalog" search={{ destination: 'PAR' }}>Paris</Link>;

const navigate = useNavigate();
navigate({ to: '/catalog', search: (prev) => ({ ...prev, pax: 2 }) });
```

> Frontend tests run on **Vitest** (see `testing.md`) — never Jest for `apps/client`.

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
├── routes/             # File-based routes (TanStack Router) — routeTree.gen.ts is generated
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
