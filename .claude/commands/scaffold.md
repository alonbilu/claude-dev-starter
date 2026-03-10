---
description: Scaffold a new endpoint, page, hook, service, or domain lib
---

Scaffold: $ARGUMENTS

**Format:** `<type> <name>` where type is one of: `endpoint`, `page`, `hook`, `service`, `domain-lib`

---

## Before Scaffolding (MANDATORY)

1. **Search for existing implementations:**
   ```bash
   grep -r "$NAME" libs/ apps/
   ls libs/domain/ libs/shared/
   ```
   If something similar exists, extend it — don't duplicate.

2. **Read patterns:** Load `.claude/knowledge/patterns.md` for the correct code template.

---

## Scaffold: endpoint [name]

Creates a NestJS API endpoint with controller, DTO, service, and module.

**Files to create:**
- `apps/api/src/app/[name]/[name].controller.ts` — thin controller (no logic)
- `apps/api/src/app/[name]/[name].module.ts` — NestJS module
- `apps/api/src/app/[name]/dto/create-[name].dto.ts` — DTO from Zod schema

**Also needed (remind user):**
- Zod schema in `libs/shared/types/src/lib/[name].schema.ts`
- Domain service in `libs/domain/[name]/src/lib/[name].service.ts`

**Pattern source:** patterns.md → "NestJS Controller" + "Domain Service with @Inject"
**Post:** Register module in `apps/api/src/app/app.module.ts`, run lint

---

## Scaffold: page [name]

Creates a React page component with data-fetching hook.

**Files to create:**
- `apps/client/src/pages/[name].tsx` — page component
- `apps/client/src/hooks/api/use-[name].ts` — TanStack Query hook

**Pattern source:** patterns.md → "TanStack Query Data-Fetching Hook"
**Post:** Add route to router config, run lint

---

## Scaffold: hook [name]

Creates a TanStack Query data-fetching or mutation hook.

**Files to create:**
- `apps/client/src/hooks/api/[name].ts` — query or mutation hook

**Pattern source:** patterns.md → "TanStack Query Data-Fetching Hook" or "Mutation with Cache Update"
**Post:** Run lint

---

## Scaffold: service [name]

Creates a domain service with test file.

**Files to create:**
- `libs/domain/[parent]/src/lib/[name].service.ts` — domain service
- `libs/domain/[parent]/src/lib/[name].service.spec.ts` — Jest test

**Note:** Ask user which domain lib this belongs in. If none exists, suggest `domain-lib` scaffold first.

**Pattern source:** patterns.md → "Domain Service with @Inject"
**Post:** Export from domain lib barrel, run lint

---

## Scaffold: domain-lib [name]

Creates a new Nx domain library.

**Steps:**
1. Run: `pnpm nx g @nx/js:library [name] --directory=libs/domain/[name]`
2. Remove `"build"` target from `libs/domain/[name]/project.json`
3. Create barrel export in `libs/domain/[name]/src/index.ts`
4. Verify path alias in `tsconfig.base.json`

**Post:** Run lint, remind user to add to module imports if NestJS

---

## After Scaffolding

- Run: `pnpm nx lint [project]`
- If new entity: remind user to create Zod schema in `libs/shared/types/`
- If new API endpoint: remind user about auth (`@AllowAnonymous()` if public)
- Show user what was created and what they need to fill in

---

Usage:
/scaffold endpoint users
/scaffold page dashboard
/scaffold hook useProjects
/scaffold service billing
/scaffold domain-lib notifications
