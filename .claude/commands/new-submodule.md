---
description: Create a new SubModule within a parent Module
---

Create SubModule {{SUBMODULE_NAME}} within parent Module {{PARENT_MODULE}}

Steps:
1. Verify parent module exists in `docs/modules/{{PARENT_MODULE}}/`
2. Create directory `docs/modules/{{PARENT_MODULE}}/submodules/{{SUBMODULE_NAME}}/`
3. Copy template `docs/templates/submodule/idea-spec.md` to `docs/modules/{{PARENT_MODULE}}/submodules/{{SUBMODULE_NAME}}/idea-spec.md`
4. Fill in parent module name in template
5. Open file for user to fill out

Explain:
- SubModules are secondary features within a Module
- They use a simplified workflow (combined idea + spec)
- They have 4 phases instead of 6
- They integrate with parent module

Next steps:
- User fills out idea-spec.md
- Use `/implement-submodule {{PARENT_MODULE}} {{SUBMODULE_NAME}}` to start implementation

Usage:
/new-submodule user-auth email-verification
/new-submodule billing invoice-generation
