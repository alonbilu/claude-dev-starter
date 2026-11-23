# Testing Rules

## ⚠️ CRITICAL: Vitest for the frontend, Jest for the backend

**Two test runners, split by app:**

| App / lib | Runner | Why |
|-----------|--------|-----|
| `apps/client` + frontend libs (React) | **Vitest** | Pairs natively with Vite — shares its config + transform pipeline; fast watch |
| `apps/api` + backend/domain libs (NestJS) | **Jest** with ts-jest | Vitest's esbuild/SWC does NOT preserve `emitDecoratorMetadata` — NestJS DI breaks (services `undefined` in controllers/guards) |

**The hard rule:** NEVER run NestJS tests under Vitest. The decorator-metadata problem makes DI
silently fail. Jest with ts-jest is mandatory for anything using NestJS decorators
(`@Injectable`, `@Controller`, `@Inject`). The frontend has no decorator-metadata dependency,
so Vitest is the better fit there.

`pnpm nx test [project]` runs whichever runner that project is configured for.

---

## Coverage Requirements

| Layer | Minimum |
|-------|---------|
| `libs/domain/*` services | 70% |
| `libs/domain/database/repositories/` | 80% |
| `libs/shared/utils/` | 80% |
| `libs/backend/*` | 60% |
| Controllers | Not required (logic-free) |
| Presentational React components | Not required |

### These minimums are enforced

| | |
|---|---|
| **Defined in** | `tools/coverage-thresholds.cjs` — the only place the numbers live. Change it and this table in the same commit. |
| **Applied by** | `jest.preset.js` (every Jest project inherits its layer's minimum) and the `coverage` block of each Vitest config. Wired by `scripts/setup-quality-gates.js`. |
| **Checked when** | Tests run with `--coverage`. `pnpm verify` and CI always do; plain `pnpm nx test [project]` and watch mode do not, so a single-file run is never failed by the gate. |
| **Metric** | Lines and statements. Branches and functions are reported, not gated. |
| **What counts** | Every source file in the project (`src/**/*.ts(x)`, minus specs, `.d.ts` and `index.ts` barrels) — including files no test imports. A service with no test lowers coverage; it cannot hide. |
| **Repositories** | `libs/domain/database` is gated at 80% on `src/lib/repositories/` only, once that folder exists. |
| **Not gated** | `apps/*`, `libs/shared/types`, `libs/shared/config`, `libs/shared/ui` (no minimum is defined for them above). |

A gated library with **no tests at all** fails (`No tests found`), by design.

To see the numbers for one project: `pnpm nx test [project] --coverage`.

---

## Jest Configuration

### jest.config.ts
```typescript
import type { Config } from 'jest';

const config: Config = {
  displayName: 'api',
  testEnvironment: 'node',
  transform: {
    '^.+\\.[tj]sx?$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.spec.json' }],
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  testMatch: ['**/*.spec.ts', '**/*.test.ts'],
  testTimeout: 30000,
  moduleNameMapper: {
    '^@app/database$': '<rootDir>/../../libs/domain/database/src/index.ts',
    '^@app/types$': '<rootDir>/../../libs/shared/types/src/index.ts',
    // Add aliases matching tsconfig.base.json
  },
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
};

export default config;
```

Do not add `coverageThreshold` or `collectCoverageFrom` here — generated projects set
`preset: '<root>/jest.preset.js'`, which supplies both from `tools/coverage-thresholds.cjs`.

### jest.setup.ts — First line must be reflect-metadata
```typescript
import 'reflect-metadata';
```

### tsconfig.spec.json — Critical settings
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "module": "commonjs",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "esModuleInterop": true,
    "types": ["jest", "node"]
  }
}
```

---

## Vitest Configuration (frontend)

Frontend projects (`apps/client`, React libs) use Vitest. It reuses the Vite config, so there
is no separate transform pipeline to maintain.

```typescript
// vitest.config.ts
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
  },
});
```

```typescript
// vitest.setup.ts
import '@testing-library/jest-dom/vitest';
```

In generated projects the `coverage` block also spreads `vitestCoverage(import.meta.dirname)`
from `tools/coverage-thresholds.cjs`. No frontend layer has a minimum today, so it adds
nothing until one is listed there — that is the place to add one.

Use `@testing-library/react` for component tests. Do NOT import `reflect-metadata` here — that
is a backend/Jest concern. Never point Vitest at NestJS code.

---

## Test File Location

Co-locate tests with source files:
```
libs/domain/users/src/lib/
├── user.service.ts
├── user.service.spec.ts      ← here
└── user.repository.ts
└── user.repository.spec.ts   ← here
```

---

## Unit Test Pattern

```typescript
describe('UserService', () => {
  let service: UserService;
  let repository: jest.Mocked<Pick<UserRepository, 'findById' | 'create'>>;

  beforeEach(() => {
    repository = { findById: jest.fn(), create: jest.fn() };
    service = new UserService(repository as any);
  });

  afterEach(() => jest.clearAllMocks());

  it('should throw when user not found', async () => {
    repository.findById.mockResolvedValue(null);
    await expect(service.findById('missing')).rejects.toThrow(UserNotFoundException);
  });
});
```

## Integration Test Pattern

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

  it('POST /api/v1/resources creates a resource', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/resources')
      .send({ name: 'Test' })
      .expect(201);
    expect(res.body.name).toBe('Test');
  });
});
```

---

## Test Factories

```typescript
// libs/shared/types/src/lib/factories/user.factory.ts
import { faker } from '@faker-js/faker';
import { UserSchema, type User } from '../user.schema';

export function createMockUser(overrides?: Partial<User>): User {
  return UserSchema.parse({
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    ...overrides,
  });
}
```

---

## Mock External Services

```typescript
// Always mock external APIs in tests
jest.mock('stripe', () => ({
  default: jest.fn(() => ({
    customers: { create: jest.fn().mockResolvedValue({ id: 'cus_123' }) },
  })),
}));
```

---

## E2E Tests — Playwright

E2E specs live in `apps/client-e2e/` (or `apps/e2e/` for fullstack flows). Playwright is the
default — Chromium + Firefox + WebKit, strong API, great debugger.

```bash
pnpm dlx playwright install --with-deps   # one-time per machine
pnpm nx e2e client-e2e                    # run the E2E suite
pnpm nx e2e client-e2e --ui               # interactive runner
```

**Scope:**
- E2E covers happy-path user flows end-to-end (signup → first-feature → settings).
- Do NOT exhaustively retest backend logic in E2E — that belongs in Jest integration tests.
- **CI:** when the `e2e` integration is enabled in `PROJECT.md`, `.github/workflows/e2e.yml`
  runs a Chromium smoke pass of `client-e2e` on every PR. It is installed by
  `scripts/setup-quality-gates.js` from `docs/templates/ci/e2e.yml`; with `e2e` disabled the
  workflow does not exist and **no E2E runs in CI**. The template serves the built client and
  provides a Postgres service; flows that need the API must add migrate/seed/start steps to
  the installed workflow (marked in the file).
- One spec per top-level user journey; not one per component.

---

## Frontend Component Workflow — Storybook + MSW

For component-driven development on the React frontend:

- **Storybook** for isolated component dev — `pnpm dlx storybook@latest init`. Stories live
  next to components (`*.stories.tsx`). Especially useful for `libs/shared/ui/` components.
- **MSW** (Mock Service Worker) mocks API calls for both Storybook stories AND Vitest
  component tests — one set of handlers, used in both. Handlers live in
  `libs/shared/api-client/src/lib/mocks/` and import paths from the generated OpenAPI client,
  so mock responses are type-checked against the real API contract.

---

## Running Tests

```bash
pnpm nx test [project]              # run tests
pnpm nx test [project] --watch      # watch mode (use during development)
pnpm nx test [project] --coverage   # with coverage report
pnpm nx affected -t test            # only test changed projects
pnpm verify                         # the full gate, incl. coverage minimums (what CI runs)
```

---

## What to Test

**Must test:**
- Domain services (`libs/domain/*/src/lib/*.service.ts`)
- Repositories (`libs/domain/database/src/lib/repositories/`)
- Utility functions (`libs/shared/utils/`)
- API endpoints that write data (POST, PUT, PATCH, DELETE)

**Don't test:**
- Thin controllers (no logic to test)
- Prisma generated code
- Third-party libraries
- Simple presentational React components

---

## Testing Checklist (Per Step)

- [ ] Tests written for all new services and utilities
- [ ] No `it.skip` or `describe.skip` in new tests
- [ ] External services are mocked
- [ ] Test DB used for integration tests (not dev DB)
- [ ] `pnpm verify` is green (lint, boundaries, typecheck, tests + coverage minimums, build)

**Never mark a step complete if tests fail.**
