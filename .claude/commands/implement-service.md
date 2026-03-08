---
description: Implement a Service (backend-only workflow)
---

Implement Service: {{SERVICE_NAME}}

Steps:
1. Read `docs/services/{{SERVICE_NAME}}/spec.md`
2. Verify spec is complete and approved by user
3. Execute backend-only implementation:

**Phase 1: Setup & Interfaces**
- Create service library: `libs/backend/{{SERVICE_NAME}}/` or `libs/domain/[feature]/src/lib/services/`
- Define TypeScript interfaces
- Setup configuration/environment validation
- Setup external API clients (if needed)

**Phase 2: Core Logic**
- Implement main service methods
- Implement error handling
- Implement retry logic (if needed)
- Add structured logging

**Phase 3: Integration**
- Connect to external APIs
- Setup authentication for external services
- Implement data transformations
- Add monitoring/metrics

**Phase 4: Testing**
- Write unit tests (70%+ coverage)
- Write integration tests (mock external services)
- Test error scenarios
- Test retry logic

4. For each phase:
   - Implement systematically
   - Validate with tests
   - Ask user before proceeding

5. When complete:
   - Document usage in spec
   - Update service catalog
   - Document environment variables needed

Important:
- Services have side effects (DB writes, API calls, state management)
- Services should be injectable and testable
- Mock external dependencies in tests
- Log all important events
- Handle errors gracefully with retries where appropriate

Usage:
/implement-service notification
/implement-service webhook-handler
