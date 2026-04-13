# SubModule: [Name]

> **Parent Module:** [Module Name]
> **Type:** SubModule
> **Status:** Draft

---

## What This SubModule Does

[One paragraph: What problem does this solve for users?]

---

## User Story

As a [user type], I want to [action] so that [benefit].

---

## Integration with Parent Module

**How it fits:**
[Explain how this enhances the parent module]

**Triggers:**
- User clicks [button/link] in [parent page]
- User reaches [step] in [parent workflow]

**Data shared with parent:**
- [Data field 1]
- [Data field 2]

---

## Quick Spec

### Database Changes

**New tables:**
```prisma
model [ModelName] {
  // fields
}
```

**Changes to existing tables:**
- Add column `[field]` to `[Table]`

### API Endpoints

**POST /api/v1/[resource]**
- Purpose: [what it does]
- Auth: Required/Optional
- Request: `{ field: type }`
- Response: `{ data: type }`

[List all endpoints]

### Frontend

**Pages:**
- `apps/client/src/pages/[parent]/[submodule].tsx`

**Components:**
- `[ComponentName]` - [description]

**Forms:**
- `[FormName]` - Fields: [list]

---

## Implementation Checklist

### Phase 1: Backend (libs/domain)
- [ ] Update Zod schemas
- [ ] Create migration (if DB changes)
- [ ] Implement service methods
- [ ] Write unit tests

### Phase 2: API (apps/api)
- [ ] Create DTOs
- [ ] Implement endpoints
- [ ] Write integration tests

### Phase 3: Frontend (apps/client)
- [ ] Create pages/components
- [ ] Create forms
- [ ] Connect to API
- [ ] Test user flow

### Phase 4: Integration
- [ ] Test with parent module
- [ ] Handle edge cases
- [ ] Polish UX

---

## Acceptance Criteria

- [ ] User can [primary action]
- [ ] Data persists correctly
- [ ] Integrates seamlessly with [parent]
- [ ] Tests pass
- [ ] No console errors

---

**Estimated effort:** 2-4 sessions
**Next step:** Review and approve, then implement
