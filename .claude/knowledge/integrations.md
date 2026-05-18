# Optional Integrations

Setup notes and gotchas for opt-in integrations. **Loaded on demand** — only read the section
for an integration that is enabled in `PROJECT.md`. `/setup-project` wires the env vars and
infra for whichever ones you pick.

Auth-provider integrations (Zitadel, Hydra) are mutually-aware of the default (Better Auth):

| Concern | Default | Alternative |
|---------|---------|-------------|
| App auth (login, sessions, users) | Better Auth | **Zitadel** (`auth_provider: zitadel`) |
| Machine-to-machine / API tokens | — | **Hydra** (`hydra` integration) |
| Observability / logging | — | **Axiom** / **Grafana Cloud** / **Better Stack** (`logging` integration) |
| Distributed tracing | — | **OpenTelemetry** (`tracing` integration) |
| Production secrets | `.env` (dev only) | **Doppler** / **Infisical** / **SOPS** / **Vault** (`secrets` integration) |
| Feature flags / experiments | — | **GrowthBook** / **Unleash** / **LaunchDarkly** (`feature-flags`) |
| Localization | — | **react-i18next** (`i18n` integration) |
| End-to-end testing | — | **Playwright** (`e2e` integration) |
| Cache / queue backend | Redis | **Valkey** (drop-in, Redis-protocol compatible) |

---

## Zitadel — auth provider + Management API queries

Enable by setting `auth_provider: zitadel` in `PROJECT.md`. Zitadel is a full identity provider
(OIDC/OAuth2). It **replaces Better Auth** — pick one, not both. When Zitadel is the provider,
the Better Auth sections of `api.md` and `stack-gotchas.md` do not apply.

### Two things Zitadel does for you

1. **Auth** — OIDC login, sessions, and token validation. The frontend runs the OIDC
   Authorization Code + PKCE flow; the API validates the resulting JWT.
2. **Query (Management API)** — read/write users, organizations, projects, roles, and grants
   from your backend via a service-account, instead of mirroring that data in your own DB.

### Environment variables

```bash
# OIDC (auth)
ZITADEL_ISSUER=https://your-instance.zitadel.cloud
ZITADEL_CLIENT_ID=xxxxxxxx
ZITADEL_PROJECT_ID=xxxxxxxx
# Management API (query) — service-account key JSON, base64-encoded or a file path
ZITADEL_SERVICE_ACCOUNT_KEY=./zitadel-key.json
ZITADEL_API_URL=https://your-instance.zitadel.cloud
# Frontend (Vite — must be VITE_-prefixed to be exposed to the browser)
VITE_ZITADEL_ISSUER=https://your-instance.zitadel.cloud
VITE_ZITADEL_CLIENT_ID=xxxxxxxx
```

### API: validate Zitadel JWTs

Zitadel issues standard JWTs. Validate them against the issuer's JWKS — no shared secret.
Build a NestJS guard that fetches `${ZITADEL_ISSUER}/oauth/v2/keys`, caches the keys, verifies
signature + `iss` + `aud` (your project/client ID), and attaches the claims to the request.
This guard replaces Better Auth's `AuthGuard`. Keep the `@AllowAnonymous()` decorator pattern
so route-protection semantics stay identical to the Better Auth setup.

### Query: Management API from the backend

Use the service-account key to mint a Management API token, then call the Management API
(`/management/v1/...`) to list users, resolve roles/grants, or provision orgs. Wrap this in a
domain service (`libs/domain/identity/`) — never call the Management API straight from a
controller. Cache tokens until expiry; do not re-mint per request.

### Gotchas

- **Token audience:** Zitadel access tokens may be opaque unless you request a JWT-format
  token. Configure the project/app for JWT access tokens, or fall back to the introspection
  endpoint.
- **Roles** arrive as a nested claim (`urn:zitadel:iam:org:project:roles`), not a flat array.
- **Local OIDC testing** needs a public redirect URI — `localhost` is rejected. Use ngrok.
- The service-account key is a **secret** — it goes in `.env`, never in the repo or frontend.

---

## Hydra — machine-to-machine / API token auth

Enable the `hydra` integration in `PROJECT.md`. ORY Hydra is an OAuth2/OIDC **server** for
issuing and validating tokens — it has no user store and no login UI of its own. Use it for
**M2M auth**: service-to-service calls, third-party API clients, webhook callers. It is
complementary to Better Auth / Zitadel (which handle human login), not a replacement.

### Environment variables

```bash
HYDRA_PUBLIC_URL=https://hydra-public.your-domain.com   # token + introspection endpoints
HYDRA_ADMIN_URL=https://hydra-admin.your-domain.com     # client management (keep internal)
HYDRA_CLIENT_ID=xxxxxxxx                                # this service's own OAuth2 client
HYDRA_CLIENT_SECRET=xxxxxxxx
```

### Pattern

- **Issuing tokens:** API clients request a token via the `client_credentials` grant against
  `${HYDRA_PUBLIC_URL}/oauth2/token`.
- **Validating tokens:** a NestJS guard introspects the incoming bearer token against
  `${HYDRA_ADMIN_URL}/admin/oauth2/introspect`, checks `active: true`, and enforces the
  required `scope`. Put the guard in `libs/backend/core/src/lib/guards/` and apply it only to
  M2M routes (a separate controller or a `@MachineOnly()` decorator) — human-facing routes
  keep the Better Auth / Zitadel guard.
- **Client registration:** create OAuth2 clients via the Hydra **admin** API. Script it in a
  seed/migration so client provisioning is reproducible.

### Gotchas

- The **admin URL must never be public** — it can mint clients. Bind it to the internal
  network only.
- Introspection is a network call per request — cache positive results for a few seconds
  keyed by token hash, or accept signed JWTs and verify locally where latency matters.
- Hydra needs its own datastore (PostgreSQL). Add a `hydra` service to `docker-compose.yml`
  for local development.

---

## Logging — Axiom, Grafana Cloud, or Better Stack

Enable the `logging` integration in `PROJECT.md`, then pick a provider. `/setup-project`
explains the trade-offs and records the choice. The goal is the same regardless of provider:
**warnings and errors from both the API and the client** land in one queryable place.

### Choosing a provider

| Provider | Best for | Trade-off |
|----------|----------|-----------|
| **Axiom** | Structured event logs, simple ingest, generous free tier | Logs-focused — not a full metrics/dashboards/tracing suite |
| **Grafana Cloud** | Full observability — logs (Loki) + metrics + traces + dashboards | More to wire up; richest but heaviest |
| **Better Stack** | Logs + uptime monitoring + incident management in one product | Smaller ecosystem than Grafana |

Rule of thumb: **Axiom** if you just want logs fast; **Grafana Cloud** if you also want
metrics/traces/dashboards; **Better Stack** if you want logging plus uptime/on-call in one tool.

### Environment variables

```bash
# Axiom
AXIOM_TOKEN=xaat-xxxxxxxx
AXIOM_DATASET=your-app
VITE_AXIOM_TOKEN=xaat-xxxxxxxx
VITE_AXIOM_DATASET=your-app-web

# Grafana Cloud (Loki push)
GRAFANA_LOKI_URL=https://logs-prod-xxx.grafana.net/loki/api/v1/push
GRAFANA_CLOUD_USER=123456
GRAFANA_CLOUD_API_KEY=glc_xxxxxxxx

# Better Stack
BETTERSTACK_SOURCE_TOKEN=xxxxxxxx
VITE_BETTERSTACK_SOURCE_TOKEN=xxxxxxxx
```

### Backend (NestJS)

Wrap the chosen provider's SDK/transport in a `libs/backend/logging/` module that exposes a
`LoggerService`, registered globally. Pino is a good common base — each provider has a Pino
transport (`@axiomhq/pino`, a Loki transport for Grafana, `@logtail/pino` for Better Stack),
so app code stays provider-agnostic and only the transport changes. Forward NestJS's own
logger to it, and flush on shutdown (`app.enableShutdownHooks()`) or buffered logs are lost.

### Frontend (React + Vite)

Put a thin logger util in `libs/shared/utils/` behind the provider's browser SDK. Wire it into:
- a React **error boundary** (`componentDidCatch`),
- `window.onerror` / `window.onunhandledrejection`,
- explicit `logger.warn(...)` / `logger.error(...)` calls.

Send `warn` and `error` to the provider; keep `debug`/`info` console-only to control volume.
Batch client events and flush on `visibilitychange` so logs survive tab close.

### Gotchas

- Any **frontend** token is shipped to the browser — use an ingest-only token scoped to the
  web dataset/source, never an admin token.
- Ingestion is async + batched — an immediate crash can drop the last batch. Flush in error
  boundaries and on `beforeunload`/`visibilitychange`.
- Keep API logs and web logs in separate datasets/streams; correlate with a shared `requestId`.
- **Axiom EU-region token routing (verified 2026-05):** workspaces created in the EU region
  have a token-binding bug where API tokens return `403` on every endpoint (including
  `/v1/user`). The same token at the US endpoint returns `400` "primary region mismatch" —
  proving the token is valid but the EU deployment can't see its permissions. **Workaround:**
  create the workspace in the US region for now. Operational logs are non-PII so the US
  region is GDPR-acceptable for this use case. Retest the EU region periodically; Axiom is
  fixing this server-side.

---

## Tracing — OpenTelemetry (optional, pairs with Grafana Cloud)

Enable the `tracing` integration. If you picked Grafana Cloud for `logging_provider`, traces
are the missing third leg next to logs and metrics — wire them up.

```bash
pnpm add @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
```

```typescript
// apps/api/src/tracing.ts — imported FIRST, before any other module
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  serviceName: 'my-app-api',
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

```bash
# OTel SDK reads these automatically
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-prod-xxx.grafana.net/otlp
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic%20<base64>
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production
```

For the React frontend, `@opentelemetry/sdk-trace-web` captures fetch/XHR + user timing.
Frontend traces correlate with API traces via the `traceparent` header — TanStack Query and
`fetch` already pass it through.

**Gotchas:**
- Instrumentation MUST be imported BEFORE other modules (top-of-file side-effect import).
  Otherwise auto-instrumented modules are already loaded and not patched.
- Exclude high-volume endpoints (health probes) — set `OTEL_SDK_DISABLED` per-route or use an
  ignore filter.

---

## Secret Management — Doppler, Infisical, SOPS, or Vault

Enable the `secrets` integration in `PROJECT.md`, then pick a provider. `/setup-project`
records `secrets_provider` and wires the fetch step into the deploy scripts.

See `.claude/rules/deployment.md` → "Secret Management — production" for the provider
comparison (including the DigitalOcean fit per provider). Quick guide:

- **Doppler** — hosted, best UX, generous free tier
- **Infisical** — open-source, self-hostable
- **SOPS + age** — encrypted secrets in the repo, decrypted on deploy — no service to run
- **HashiCorp Vault** — heavyweight, full audit + rotation
- **DigitalOcean App Platform built-in** — native to App Platform, simple

Local dev still uses `.env` files (`chmod 600`); the secrets manager only fetches for staging
and production. Pattern for a Doppler-on-Droplet deploy:

```bash
# scripts/production-deploy.sh fragment
doppler secrets download --no-file --format env > .env.production
chmod 600 .env.production
# ... rest of deploy
shred -u .env.production   # after the app starts, wipe the plaintext
```

Pattern for SOPS-on-Droplet:

```bash
sops --decrypt secrets/production.enc.env > .env.production
chmod 600 .env.production
```

---

## Feature Flags — GrowthBook, Unleash, or LaunchDarkly

Enable the `feature-flags` integration; `/setup-project` records the provider choice.

| Provider | Best for | Trade-off |
|----------|----------|-----------|
| **GrowthBook** | A/B experimentation + flags, self-hostable | Smaller ecosystem |
| **Unleash** | Open-source flags, self-hostable on a Droplet | More setup if self-hosted |
| **LaunchDarkly** | Enterprise-grade flags, polished UI | Most expensive |

All three offer SDKs for Node (backend) and React (frontend). Wrap them behind a shared
`useFeatureFlag('flag-name')` hook in `libs/shared/utils/` so swapping providers later is one
file. Evaluate flags at render or request boundary — not in hot loops.

**Gotcha:** the frontend SDK ships flag definitions to the client — never put secret flags
(launch dates, internal-tool visibility) in there; those go through the backend.

---

## i18n — react-i18next + ICU MessageFormat

Enable the `i18n` integration when the app needs multiple languages.

- **Frontend:** `react-i18next` with namespaces split per feature (`common`, `auth`,
  `catalog`, …). Translation JSON files in `apps/client/src/locales/<lang>/<namespace>.json`.
- **Backend:** if API responses need localized strings (validation errors, emails), use
  `i18next` server-side too and detect locale from `Accept-Language`.
- **Source language:** keep one canonical (usually English) — others are derived. Don't let
  designers edit non-English files directly; translations come from one workflow.
- **Type-safe keys:** generate a TS type from your JSON files so `t('catalog.title')` is
  checked at compile time (`i18next-typescript` plugin).

For multi-tenant whitelabel projects, locale strings can also live in the database (per-tenant
overrides) — load them at app boot and merge over the JSON defaults.

---

## E2E Testing — Playwright

Enable the `e2e` integration to scaffold `apps/client-e2e/` (or `apps/e2e/` for fullstack
flows). See `.claude/rules/testing.md` → "E2E Tests — Playwright" for scope guidance and
commands.

---

## Valkey — Redis alternative

Anywhere this kit uses Redis (BullMQ queues, caching), **Valkey** is a drop-in replacement.
Valkey is the community fork of Redis 7.2, speaks the same protocol, and is BullMQ- and
`ioredis`-compatible. Choose it to stay on a fully open-source (BSD) license.

- **Docker:** swap `redis:8-alpine` → `valkey/valkey:8-alpine` in `docker-compose.yml`.
- **Connection:** the `REDIS_URL` env var and all client code stay unchanged.
- **Managed:** AWS ElastiCache, Aiven, and others offer managed Valkey.

No code changes are needed — it is purely an infra/image choice.
