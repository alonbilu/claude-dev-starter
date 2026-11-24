# External Services Setup Checklist

Use this as the single source of truth for which third-party accounts / API keys / tokens are
required by your project. Update the status as you wire each one up. This file is checked into
git so it's visible to everyone on the team.

**Status legend**

- 🔴 **Blocker** — required for the project to run; not configured yet
- 🟡 **In progress** — credentials acquired, smoke test not yet passing
- 🟢 **Done** — credentials present + `node scripts/verify-*.js` returns 0
- ⚪ **Deferred** — not needed for this milestone, leave for later

**Verification** — every section ends with a verify command. Run `node scripts/verify-zitadel.js`
and `node scripts/verify-observability.js` to confirm credentials work end-to-end.

---

## Auth — `auth_provider` from `PROJECT.md`

### Zitadel (`auth_provider: zitadel`)

- [ ] 🔴 Zitadel workspace created (cloud or self-hosted)
- [ ] 🔴 Project created in Zitadel; project ID copied to `.env` as `ZITADEL_PROJECT_ID`
- [ ] 🔴 Web app client created (PKCE flow); client ID copied to `ZITADEL_CLIENT_ID` and `VITE_ZITADEL_CLIENT_ID`
- [ ] 🔴 Issuer URL (`https://<instance>.zitadel.cloud`) in `ZITADEL_ISSUER` + `VITE_ZITADEL_ISSUER`
- [ ] 🟡 Service account user created (Service Users → New); user ID noted
- [ ] 🟡 Service account key JSON downloaded → saved to project root as `zitadel-key.json` (chmod 600, gitignored)
- [ ] 🟡 `ZITADEL_SERVICE_ACCOUNT_KEY=./zitadel-key.json` in `.env`
- [ ] 🟡 Service account granted ORG_OWNER (or scoped role) in Zitadel
- [ ] 🟢 Verify: `node scripts/verify-zitadel.js`

### Better Auth (`auth_provider: better-auth`)

- [ ] 🔴 `BETTER_AUTH_SECRET` generated (`openssl rand -base64 32`)
- [ ] 🔴 `BETTER_AUTH_URL` set to the API base URL
- [ ] If OAuth providers: per-provider client ID/secret pairs (Google/GitHub/etc.)
- [ ] 🟢 Smoke test: `curl http://localhost:3333/api/v1/auth/get-session -H "Cookie: ..."`

---

## Machine-to-machine auth — `hydra` integration

- [ ] 🔴 ORY Hydra instance deployed (Docker or cloud)
- [ ] 🔴 `HYDRA_PUBLIC_URL` and `HYDRA_ADMIN_URL` in `.env`
- [ ] 🔴 OAuth2 client created via Hydra admin API (`POST /admin/clients`)
- [ ] 🔴 `HYDRA_CLIENT_ID` + `HYDRA_CLIENT_SECRET` in `.env`
- [ ] 🟢 Smoke test: `curl -X POST $HYDRA_PUBLIC_URL/oauth2/token -d grant_type=client_credentials -u $HYDRA_CLIENT_ID:$HYDRA_CLIENT_SECRET`

---

## Logging — `logging` integration (provider per `logging_provider`)

### Axiom

- [ ] 🔴 Axiom account created (**US region recommended** — EU has a token-binding bug, see integrations.md)
- [ ] 🔴 Dataset created for backend (`<project>` / `<project>-api`)
- [ ] 🔴 Dataset created for frontend (`<project>-web`)
- [ ] 🔴 Ingest-only API token created; backend token in `AXIOM_TOKEN`, frontend token in `VITE_AXIOM_TOKEN`
- [ ] 🔴 `AXIOM_DATASET` + `VITE_AXIOM_DATASET` set
- [ ] 🟢 Verify: `node scripts/verify-observability.js`

### Grafana Cloud (logs + optional metrics + traces)

- [ ] 🔴 Grafana Cloud stack created
- [ ] 🔴 `GRAFANA_LOKI_URL` (push endpoint from the Grafana → Connections → Loki page)
- [ ] 🔴 `GRAFANA_CLOUD_USER` + `GRAFANA_CLOUD_API_KEY` (API key with `MetricsPublisher` + `LogsPublisher` roles)
- [ ] If using tracing: `OTEL_EXPORTER_OTLP_ENDPOINT` + `OTEL_EXPORTER_OTLP_HEADERS`
- [ ] 🟢 Verify: `node scripts/verify-observability.js`

### Better Stack

- [ ] 🔴 Source created in Better Stack
- [ ] 🔴 `BETTERSTACK_SOURCE_TOKEN` (backend) + `VITE_BETTERSTACK_SOURCE_TOKEN` (frontend) in `.env`
- [ ] 🟢 Verify: `node scripts/verify-observability.js`

---

## Error tracking — `error-tracking` integration (Sentry; separate from `logging`)

- [ ] 🔴 Sentry project created (Node and/or React platform)
- [ ] 🔴 `SENTRY_DSN` (backend) + `VITE_SENTRY_DSN` (frontend) in `.env`
- [ ] ⚪ Sentry's GitHub integration installed for the repo (so errors can become GitHub issues for `/fix-issue` — see `docs/UNATTENDED.md`)
- [ ] 🟢 Verify: `node scripts/verify-observability.js`

---

## Independent PR review — `ai-review` integration

- [ ] 🔴 Claude GitHub App installed on the repository (`/install-github-app`)
- [ ] 🔴 `ANTHROPIC_API_KEY` added as a repository Actions secret (never in `.env`)
- [ ] 🟢 Verify: open a PR — a "Independent review" comment appears. Without the secret the job skips and passes.

---

## Tracing — `tracing` integration

- [ ] 🔴 OTLP endpoint URL in `OTEL_EXPORTER_OTLP_ENDPOINT`
- [ ] 🔴 Auth header in `OTEL_EXPORTER_OTLP_HEADERS` (Grafana Cloud uses Basic auth)
- [ ] 🔴 `OTEL_RESOURCE_ATTRIBUTES=service.name=<app>,deployment.environment=<env>`
- [ ] 🟢 Smoke test: send a span via the SDK in `apps/api/src/tracing.ts`, query in your backend (Grafana Tempo / Honeycomb)

---

## Secrets — `secrets` integration (production only)

### Doppler (recommended for DigitalOcean)

- [ ] 🔴 Doppler account + project created
- [ ] 🔴 `doppler` CLI installed locally; `doppler login` done
- [ ] 🔴 Project linked: `doppler setup` in the repo root (selects project + config)
- [ ] 🟡 Production secrets uploaded to Doppler
- [ ] 🟡 `scripts/production-deploy.sh` reads from Doppler (`doppler run --` or `doppler secrets download --no-file --format env`)
- [ ] 🟢 Smoke test: `doppler secrets --only-names | wc -l` returns the expected count

### SOPS + age (alternative, no external service)

- [ ] 🔴 `age` + `sops` installed locally
- [ ] 🔴 age keypair generated; private key saved on the deploy target only
- [ ] 🔴 `.sops.yaml` at repo root pinning encryption to the age recipient
- [ ] 🟡 `secrets/production.enc.env` encrypted with sops
- [ ] 🟢 Smoke test on deploy target: `sops --decrypt secrets/production.enc.env | head -3`

---

## Feature flags — `feature-flags` integration

### GrowthBook

- [ ] 🔴 GrowthBook account/instance + project created
- [ ] 🔴 API key (server) → `GROWTHBOOK_API_KEY`
- [ ] 🔴 Client key (browser) → `VITE_GROWTHBOOK_CLIENT_KEY`
- [ ] 🟡 First flag created (smoke test target)
- [ ] 🟢 Verify: backend evaluates the flag and returns expected boolean

### Unleash / LaunchDarkly

- [ ] 🔴 Instance + project + environment created
- [ ] 🔴 Server SDK token in `UNLEASH_API_TOKEN` / `LAUNCHDARKLY_SDK_KEY`
- [ ] 🔴 Browser SDK key in `VITE_LAUNCHDARKLY_CLIENT_ID` (LD only)
- [ ] 🟢 Smoke test: SDK initialized, first flag returns a value

---

## Email — `email` integration (Resend)

- [ ] 🔴 Resend account created
- [ ] 🔴 Sending domain verified (DNS records added)
- [ ] 🔴 API key → `RESEND_API_KEY`
- [ ] 🔴 `EMAIL_FROM=noreply@your-verified-domain.com`
- [ ] 🟢 Smoke test: `curl -X POST https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -d '...'`

---

## Payments — `payments` integration (Stripe)

- [ ] 🔴 Stripe account; test mode keys in `STRIPE_SECRET_KEY` + `STRIPE_PUBLISHABLE_KEY`
- [ ] 🔴 Webhook endpoint registered; signing secret in `STRIPE_WEBHOOK_SECRET`
- [ ] 🟡 Stripe CLI installed for local webhook testing: `stripe listen --forward-to localhost:3333/api/v1/webhooks/stripe`
- [ ] 🟢 Smoke test: `stripe trigger payment_intent.succeeded` and confirm webhook handler runs

---

## Storage — `storage` integration (S3-compatible)

- [ ] 🔴 Bucket created (DigitalOcean Spaces / AWS S3 / Cloudflare R2)
- [ ] 🔴 Access key + secret in `.env` (`S3_ACCESS_KEY` + `S3_SECRET_KEY`)
- [ ] 🔴 `S3_ENDPOINT` + `S3_BUCKET` + `S3_REGION`
- [ ] 🟡 CORS rules applied if direct browser upload (PUT from frontend)
- [ ] 🟢 Smoke test: `aws s3 ls s3://$S3_BUCKET --endpoint-url=$S3_ENDPOINT`

---

## Cloudflare Tunnel — optional dev exposure

- [ ] 🔴 Cloudflare account + zone available
- [ ] 🔴 `cloudflared` CLI installed
- [ ] 🟡 Run `bash scripts/setup-cloudflared.sh` (project-isolated — preserves your other tunnels' certs)
- [ ] 🟡 `CLOUDFLARE_TUNNEL_TOKEN` from the script's output added to `.env`
- [ ] 🟢 Smoke test: `bash scripts/start-cloudflared.sh` boots; public hostname returns local dev's response

---

## Updates

When a service is fully wired and verified, change its `🔴` / `🟡` to `🟢` and commit. New
team members reading this file should be able to tell what's blocking the project from
running just by scanning the dots.
