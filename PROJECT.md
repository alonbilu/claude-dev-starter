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
<!-- Choose one: saas-web-app | api-only | fullstack-web | mobile-app | cli | library | static-site | worker -->
<!-- `worker` = long-running Node process (BullMQ consumer, queue runner, cron loop, etc.) — no HTTP surface. -->
type: saas-web-app

## Active Layers
<!-- Mark which architectural layers exist in THIS project -->
- [x] frontend      # React/Next/mobile UI
- [x] backend       # NestJS/Express/Fastify API
- [x] database      # Prisma + PostgreSQL
- [x] auth          # Better Auth / NextAuth / Clerk
- [ ] mobile        # React Native
- [ ] cli           # Command-line interface

## Auth Provider
<!-- Only relevant when the `auth` layer is active. Pick ONE provider. -->
<!-- better-auth — library-based, cookie sessions, runs inside your API (default) -->
<!-- zitadel     — full OIDC identity provider + Management API queries -->
<!-- See .claude/knowledge/integrations.md for Zitadel setup + gotchas. -->
auth_provider: better-auth

## Optional Integrations
<!-- Enable the ones you need — /setup-project will wire them up -->
- [ ] payments      # Stripe
- [ ] email         # Resend + React Email
- [ ] storage       # S3-compatible (DigitalOcean Spaces / AWS)
- [ ] llm           # OpenAI / Anthropic
- [ ] rag           # pgvector / embeddings
- [ ] queue         # BullMQ background jobs (Redis or Valkey)
- [ ] realtime      # WebSockets / SSE
- [ ] hydra         # ORY Hydra — OAuth2 server for machine-to-machine / API tokens
- [ ] logging       # Structured logging — Axiom / Grafana Cloud / Better Stack (pick at setup)
- [ ] tracing       # OpenTelemetry distributed tracing (pairs with Grafana Cloud)
- [ ] secrets       # Production secret management — Doppler / Infisical / SOPS / Vault (pick at setup)
- [ ] feature-flags # Feature flags / experiments — GrowthBook / Unleash / LaunchDarkly (pick at setup)
- [ ] i18n          # Localization — react-i18next + ICU MessageFormat
- [ ] e2e           # End-to-end testing — Playwright (adds .github/workflows/e2e.yml)
- [ ] error-tracking # Error tracking — Sentry (backend + frontend); feeds the /fix-issue lane via its GitHub integration
- [ ] ai-review     # Independent Claude review comment on every PR (adds .github/workflows/claude-review.yml)

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
<!-- Declared by /setup-project. Read by tier-aware commands and phase-transition reminders. -->
<!--                                                                                          -->
<!-- max_plan values (v1.1.0+):                                                               -->
<!--   x20     — always on Opus 1M; no phase-based model switching needed                     -->
<!--   x5      — mix Opus and Sonnet; phase-based switching via /clear is recommended         -->
<!--   legacy  — no Max plan; Sonnet-safe throughout                                           -->
<!--                                                                                          -->
<!-- thinking_mode values (v1.1.6+):                                                          -->
<!--   per-phase — on during planning, off during implementation (recommended for x5)         -->
<!--   always    — extended thinking always on (typical for x20 with budget to spare)         -->
<!--   never     — extended thinking always off (fastest, tightest budget)                    -->
<!--   ask       — Claude asks at phase boundaries rather than having a default               -->
claude:
  max_plan: x5
  thinking_mode: per-phase

## Notes
<!-- Any project-specific notes Claude should always keep in mind -->
