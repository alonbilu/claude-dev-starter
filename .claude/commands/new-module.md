---
description: Create a new Module (top-level domain area)
---

Create Module: {{MODULE_NAME}}

## What is a Module?

A Module is a top-level bounded context — a distinct subject area the software manages.
Examples: users, billing, projects, notifications, analytics.

Modules live in `libs/domain/[name]/` and serve as parent containers for SubModules.

---

## Steps

1. **Search for existing modules:**
   ```bash
   ls libs/domain/
   ls docs/modules/ 2>/dev/null
   ```
   If a similar module exists, extend it — don't create a duplicate.

2. **Create the docs structure:**
   ```
   docs/modules/{{MODULE_NAME}}/
   ├── spec.md              ← module specification
   └── submodules/           ← future SubModules go here
   ```

3. **Create `docs/modules/{{MODULE_NAME}}/spec.md`** with:
   ```markdown
   # Module: {{MODULE_NAME}}

   ## Purpose
   [One sentence: what does this module manage?]

   ## Location
   `libs/domain/{{MODULE_NAME}}/`

   ## Key Services
   - `{{ModuleName}}Service` — [primary responsibilities]

   ## Public API (exported from index.ts)
   - `{{ModuleName}}Service`
   - `{{ModuleName}}Module`

   ## Related Modules
   - [Other modules this interacts with and why]

   ## Created By Features
   - F[XXX] — [feature that created this module]

   ## SubModules
   - [None yet — use `/new-submodule {{MODULE_NAME}} [name]` to add]
   ```

4. **Create the Nx domain library** (if it doesn't exist yet):
   ```bash
   pnpm nx g @nx/js:library {{MODULE_NAME}} --directory=libs/domain/{{MODULE_NAME}}
   ```
   Then remove the `"build"` target from `libs/domain/{{MODULE_NAME}}/project.json`.

5. **Confirm creation** and show next steps.

---

## Output

```
✅ Module created: {{MODULE_NAME}}

📁 Docs: docs/modules/{{MODULE_NAME}}/spec.md
📁 Code: libs/domain/{{MODULE_NAME}}/

Next steps:
  - Fill in spec.md with module purpose and key services
  - Use /new-submodule {{MODULE_NAME}} [name] to add capabilities
  - OR use /new-feature [name] to build features that use this module
```

---

## Rules

- One module per bounded context — don't create micro-modules
- Modules are the TOP level. Features and SubModules live inside them.
- Always create the docs structure AND the Nx lib together

Usage:
/new-module billing
/new-module notifications
/new-module analytics
