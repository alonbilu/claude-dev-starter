---
description: Implement a SubModule (4-phase workflow)
---

Implement SubModule {{SUBMODULE_NAME}} in {{PARENT_MODULE}}

Steps:
1. Read `docs/modules/{{PARENT_MODULE}}/submodules/{{SUBMODULE_NAME}}/idea-spec.md`
2. Verify spec is complete and approved by user
3. Execute 4-phase implementation:

**Phase 1: Backend Setup**
- Update Zod schemas (if needed)
- Create/update database migrations
- Implement service methods in parent module's domain library

**Phase 2: API Integration**
- Create DTOs (if new endpoints needed)
- Implement/update API endpoints
- Write integration tests

**Phase 3: Frontend**
- Create pages/components
- Create forms (with Zod validation)
- Connect to API

**Phase 4: Polish & Test**
- Handle edge cases
- Test integration with parent module
- E2E test for critical flow

4. For each phase:
   - Implement tasks systematically
   - Validate after each task
   - Ask user before moving to next phase

5. When complete, update parent module status

Important:
- SubModules live within parent module's codebase
- They enhance but don't replace parent functionality
- Keep integration points clear
- Can be added/removed independently

Usage:
/implement-submodule user-auth email-verification
/implement-submodule billing invoice-generation
