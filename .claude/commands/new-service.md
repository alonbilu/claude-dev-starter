---
description: Create a new Service (backend process/coordination)
---

Create Service: {{SERVICE_NAME}}

Steps:
1. Create directory `docs/services/{{SERVICE_NAME}}/`
2. Copy template `docs/templates/service/spec.md` to `docs/services/{{SERVICE_NAME}}/spec.md`
3. Open file for user to fill out

Explain:
- Services are backend-only (no frontend)
- They manage data, execute processes, or coordinate systems
- Examples: NotificationService, WebhookService, SyncService
- No user-facing UI

Ask user to define:
- Purpose and use cases
- External dependencies (APIs, services)
- Data flow
- Error handling strategy
- Logging and monitoring needs

Next steps:
- User fills out spec.md
- Use `/implement-service {{SERVICE_NAME}}` to start implementation

Usage:
/new-service notification
/new-service webhook-handler
/new-service sync-service
