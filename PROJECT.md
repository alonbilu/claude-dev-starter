# Project Configuration

> **Instructions:** Run `/setup-project` in Claude Code to fill this in interactively.
> The wizard will ask you questions, suggest sensible defaults, and update all code files automatically.
> Do NOT edit the Ports section manually after running `/setup-project`.

---

## Setup Status
<!-- IMPORTANT: /setup-project sets this to true when done. Claude uses this to detect unconfigured projects. -->
configured: false

---

## Project Type
<!-- Choose one: saas-web-app | api-only | fullstack-web | mobile-app | cli | library | static-site -->
type: saas-web-app

## Active Layers
<!-- Mark which architectural layers exist in THIS project -->
- [x] frontend      # React/Next/mobile UI
- [x] backend       # NestJS/Express/Fastify API
- [x] database      # Prisma + PostgreSQL
- [x] auth          # Better Auth / NextAuth / Clerk
- [ ] mobile        # React Native
- [ ] cli           # Command-line interface

## Optional Integrations
<!-- Enable the ones you need — /setup-project will wire them up -->
- [ ] payments      # Stripe
- [ ] email         # Resend + React Email
- [ ] storage       # S3-compatible (DigitalOcean Spaces / AWS)
- [ ] llm           # OpenAI / Anthropic
- [ ] rag           # pgvector / embeddings
- [ ] queue         # BullMQ background jobs
- [ ] realtime      # WebSockets / SSE

## Deployment Target
<!-- Choose one: digital-ocean | vercel | aws | docker-self-hosted | cloudflare | none -->
target: digital-ocean

## Ports
<!-- Configured by /setup-project — do not edit manually after setup -->
api: 3333
client: 4200
db_dev: 5442
db_test: 5443
redis: 6379

## Context Auto-Save Checkpoints
<!-- When an active feature exists, Claude saves status at these thresholds -->
first_save: 60
second_save: 85

## Claude
<!-- Declared by /setup-project (v1.1.0+). Read by tier-aware commands as a fallback when the running model ID alone doesn't determine tier. -->
<!-- max_plan values:                                                                                                                         -->
<!--   x20     — user is always on Opus 1M → commands default to eager context loading                                                         -->
<!--   x5      — user mixes Opus and Sonnet → lean loading by default, Opus mode when detected                                                 -->
<!--   legacy  — no Max plan → lean loading (Sonnet-safe)                                                                                       -->
claude:
  max_plan: x5

## Notes
<!-- Any project-specific notes Claude should always keep in mind -->
