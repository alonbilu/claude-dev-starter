# Changelog

All notable changes to Claude Dev Starter Kit are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [1.6.0] — 2026-05-18

Closes the post-setup verification loop. v1.5.x got the workspace scaffolding clean — but
once it's set up, users were still spending an hour wondering why their first API call
returned 401, because the kit had no way to *test* that the credentials in `.env`
actually worked. v1.6.0 adds zero-dep verification scripts + a single-source-of-truth
checklist, and wires them into `/setup-project` as a new Step G.

### Added

- **`scripts/setup-cloudflared.sh`** — project-isolated Cloudflare Tunnel setup (the
  contribution offered in the downstream report). Solves the multi-project pain where
  `cloudflared tunnel login` always writes to `~/.cloudflared/cert.pem` — running it for a
  second project overwrites the first project's global cert. This script:
  1. Backs up `~/.cloudflared/cert.pem` (if present) with a timestamped suffix
  2. Removes it so `tunnel login` writes a fresh one
  3. Runs `cloudflared tunnel login` interactively
  4. Moves the new cert to `./.cloudflared/cert.pem` (project-local, chmod 600, gitignored)
  5. Restores the previous global cert from the backup
  6. Creates a named tunnel using the project-local cert (`TUNNEL_ORIGIN_CERT` env override)
  7. Routes DNS to a chosen hostname
  8. Writes `./.cloudflared/config.yml`
  9. Prints the `CLOUDFLARE_TUNNEL_TOKEN` for `.env`

  Idempotent — re-runs offer to skip or rebuild. Companion to the existing
  `scripts/start-cloudflared.sh` which boots a configured tunnel.

- **`scripts/verify-zitadel.js`** — zero-dep Node smoke test for Zitadel credentials.
  Reads `.env` directly (no `dotenv` dep), fetches `.well-known/openid-configuration`,
  signs an RS256 JWT with the service-account private key (using Node's built-in
  `crypto`), exchanges it for an access token, then calls the Management API
  (`/management/v1/orgs/me`) to confirm the service account has actual permissions.
  Per-check OK/FAIL with the exact HTTP status and body snippet. Exit codes: `0` ok,
  `1` config error, `2` network, `3` Zitadel rejection.

- **`scripts/verify-observability.js`** — same shape, auto-detects which observability
  providers are configured in `.env` and POSTs a real test event to each:
  - Axiom (`AXIOM_TOKEN` + `AXIOM_DATASET`) — POSTs to `/v1/datasets/.../ingest`,
    surfaces the EU 403 bug with a hint to switch to US region
  - Grafana Cloud / Loki (`GRAFANA_LOKI_URL` + `GRAFANA_CLOUD_API_KEY` +
    `GRAFANA_CLOUD_USER`) — POSTs a labeled line to the push endpoint
  - Better Stack (`BETTERSTACK_SOURCE_TOKEN`) — POSTs to `in.logs.betterstack.com`
  - Sentry (`SENTRY_DSN`) — parses the DSN, POSTs to the project's `store/` endpoint with
    the right `X-Sentry-Auth` header

  Every check prints a verifyId tag so the user can find their test event in the provider's
  UI. Skips checks for unconfigured providers (no spurious failures).

- **`docs/setup/EXTERNAL-SERVICES.md`** — single-source-of-truth checklist for every
  third-party account / API key / token the project needs. Per-section status legend
  (🔴 blocker / 🟡 in progress / 🟢 done / ⚪ deferred) and a verify command at the
  bottom of each section. Covers: Zitadel + Better Auth, Hydra, Axiom + Grafana Cloud +
  Better Stack, Sentry, OpenTelemetry tracing, Doppler + SOPS, GrowthBook + Unleash +
  LaunchDarkly, Resend, Stripe, S3, Cloudflare Tunnel. Replaces hidden TODOs in
  `.env` files — what's configured and what's blocking is visible to the whole team.

- **Step G in `/setup-project` — Smoke-test external services.** Final guided-execution
  sub-step that runs `verify-zitadel.js` + `verify-observability.js` and reports
  results inline. Includes the per-script failure-mode reference (Axiom EU 403, Zitadel
  ORG_OWNER missing, Sentry DSN format, etc.) so the wizard can guide the user to a fix
  immediately instead of dropping them into a debug session.

### Why this release matters

The downstream user's bug report counted ~60 minutes lost to the Axiom EU 403 issue alone —
that's the kind of "credentials are correct but the service is misconfigured" debugging
that costs whole afternoons. Adding a smoke test that takes ~2 seconds to run + writes a
real event to the actual provider eliminates 90% of those rabbit holes: either the test
returns 200 (everything works) or it returns the exact provider error (you fix that one
thing). The `EXTERNAL-SERVICES.md` checklist captures the steps that aren't testable via
HTTP — bucket CORS rules, sending-domain DNS verification, Stripe webhook registration,
etc. — so even the manual setup has a tracked status.

Outstanding contributions from the bug report: `.npmrc` baseline (already in v1.5.0's
scaffolder), pre-flight stuck-cwd check (already in v1.5.1's wizard hygiene rule).
Everything offered has landed.

---

## [1.5.1] — 2026-05-18

Follow-up patch release closing the gaps that v1.5.0 missed. The same downstream user who
reported the 17 scaffolding gotchas re-ran setup against v1.5.0 and found **four more
critical issues** I'd dismissed or hadn't caught. All four are now fixed; the new "Why this
release matters" line below explains the time accounting from the bug report.

### Fixed

- **`pnpm-workspace.yaml` `allowBuilds:` is the REAL pnpm 11 approval mechanism** — not
  `.npmrc`, not `package.json` `pnpm.onlyBuiltDependencies`. `nx init` writes the file with
  literal placeholder strings (`@nestjs/core: set this to true or false`) which pnpm reads
  as "not true" → still blocked. **90 minutes lost in the downstream debug session.**
  `scripts/init-workspace.sh` now follows `nx init` with a `node -e` block that strips the
  placeholder lines and rewrites all 18 known builds to `true`. The kit also documents this
  as a top-level entry in `stack-gotchas.md` → "Scaffolding & Tooling" with the full
  reproducer + the snippet for anyone writing their own scaffold.

- **PostgreSQL 18 changed the data-directory mount path.** PG ≤ 17 stored data under
  `/var/lib/postgresql/data` inside the official Docker image. PG 18 stores it under
  `/var/lib/postgresql/` itself — the old `/data` path becomes "unused mount/volume" and
  the container exits at boot with a `pg_ctlcluster` compatibility error. The kit's
  `docker-compose.yml` template now uses the PG 18+ path for both `postgres` and
  `postgres-test` services. Verified live in the downstream user's run.

- **`.claude/settings.json` deny list blocked `.env` writes during setup.** The wizard
  needed to render `.env` from a template + chmod 600, but `Write(.env)` and `Edit(.env)`
  were in the deny list (alongside `.env.local`, `.env.staging`, `.env.production`).
  Setup users had to manually relax these mid-flow. Relaxed: `.env` and `.env.local` are
  now writable; `.env.staging` and `.env.production` remain denied (those carry real
  production secrets and are the right targets for a strict policy).

- **Wizard cwd-hygiene rule** in `/setup-project`. The downstream user's worst single
  failure mode was the Bash tool's cwd persisting across separate invocations — one earlier
  `cd node_modules/.pnpm/.../unrs-resolver && ...` call leaked into every subsequent
  generator, writing 11 corrupted `project.json` files with `sourceRoot` paths buried 4
  levels deep in `node_modules/`. The wizard prompt now has a top-level "CRITICAL CWD
  HYGIENE" section instructing Claude to never `cd` into transitive deps without a
  subshell, to re-anchor every Bash call, and to assert `PROJECT.md` exists before any
  generator. The same gotcha is documented in `stack-gotchas.md` with the user's full
  recovery story.

### Added

- **Axiom EU-region 403 bug** documented in `.claude/knowledge/integrations.md` → Logging
  Gotchas. EU-region Axiom workspaces have a token-binding bug where every API endpoint
  returns 403 (including `/v1/user`); the same token at the US endpoint returns 400
  "primary region mismatch". Workaround until Axiom fixes server-side: use the US region
  for operational logs. Verified 2026-05.

- **pnpm 11.0.x `pnpm add -D` bug** documented in `stack-gotchas.md`: deps land in
  `pnpm-lock.yaml` but skip `package.json` `devDependencies`. Fixed in pnpm 11.5+. The
  kit's `init-workspace.sh` now pins `packageManager: pnpm@11.5.0` to prevent it.

### Why this release matters

v1.5.0 fixed the 17 gotchas from the original bug report, but it shipped without addressing
four others the same user surfaced in the follow-up. Time accounting from the downstream
report:

| Gap | Wasted setup time |
|-----|-------------------|
| Stuck cwd → 11 corrupted project.json files | ~45 min recovery |
| `pnpm-workspace.yaml` `allowBuilds` placeholder discovery | ~90 min debugging |
| Pre-commit / husky / install ordering | ~15 min |
| `.env` deny rule mid-flow | ~10 min |
| PG18 mount path | ~5 min |
| Axiom EU 403 (non-kit, doc gap) | ~60 min |
| **Total friction on top of productive setup** | **~3.5 hours** |

With v1.5.1, a fresh `git clone` + `/setup-project` should be a clean ~1-hour end-to-end
setup with no manual recovery. All four "blocker" categories now have either a fix in the
script or an explicit hygiene rule in the wizard prompt.

The downstream user is offering additional PRs (project-isolated Cloudflare Tunnel setup,
`verify-zitadel.js` / `verify-observability.js` post-setup smoke tests, a
`docs/setup/EXTERNAL-SERVICES.md` checklist) — those land in a follow-up release after
review.

---

## [1.5.0] — 2026-05-18

Closes the workspace-scaffolding gap that hit a downstream user on the v1.4.0/1.4.1
release: `/setup-project` configured PROJECT.md / CI / scripts / docs, but
**didn't actually scaffold the Nx workspace** — no `apps/`, no `libs/`, no `package.json`.
The user ran `/setup-project`, got the green "configured" message, and then `pnpm install`
failed because there was nothing to install. They wrote their own scaffold script and
reported 17 distinct gotchas they hit along the way. Every one of those gotchas is now
baked into the kit.

### Added

- **`scripts/init-workspace.sh`** — runnable, idempotent, ~495-line workspace scaffolder
  that reads `PROJECT.md` and produces a working Nx workspace. Every step is the distilled
  output of the downstream bug report. Highlights:
  - **cwd guard** anchored to the project root (script aborts unless `PROJECT.md` is in
    cwd) — protects against the failure mode where shells get stuck in
    `node_modules/.pnpm/...` cwds and `pnpm nx g` writes `sourceRoot` paths into the
    middle of the dependency tree.
  - `set -euo pipefail` + step-by-step idempotency guards (`[ -d apps/client ] || pnpm nx g ...`).
  - **pnpm 11 build-script preamble** — pre-writes `pnpm.onlyBuiltDependencies` covering
    `@prisma/engines`, `prisma`, `esbuild`, `unrs-resolver` (the nx-init dep that surfaced
    the issue), `@swc/core`, `@nestjs/core`, `sharp`. Tolerates `nx init`'s non-zero exit
    when only the postinstall warning is the problem.
  - **`--name=` on every Nx generator** — Nx 22.7+ schemas reject positional args
    (`Schema does not support positional arguments. Argument 'api' found.`); the script
    uses the explicit flag everywhere so it works across generator versions.
  - **Post-generation `build` target removal** for domain/shared libs — documented in
    architecture.md but unscripted before now; the script does it with a tiny `node -e`
    loop over `project.json` files.
  - **Reads PROJECT.md** for `type`, `auth_provider`, and the integration checkboxes;
    installs only what's needed (Zitadel vs Better Auth, GrowthBook vs Unleash vs
    LaunchDarkly, Axiom vs Grafana Cloud vs Better Stack, etc.).
  - **Healthy-wait on docker compose** (90s `pnpm nx ...` race protection).
  - **Final-pass** runs `pnpm rebuild` (force any blocked postinstalls to fire),
    `pnpm nx reset` (clear stale plugin cache), and asserts every expected project shows
    up in `pnpm nx show projects` before declaring success.
  - **Build smoke test** at the end (`pnpm nx build api && pnpm nx build client`) so
    "scaffold complete" actually means "everything compiles."

- **Step 5b in `/setup-project`** — wires the scaffolder into the wizard between
  "patch files" (Step 5) and "guided execution" (Step 6). User-prompted `[yes/no]`
  before running.

- **Scaffolding & Tooling gotchas section** in `.claude/knowledge/stack-gotchas.md` — a new
  section documenting the failure modes the init-workspace.sh script protects against, so
  anyone writing their own scaffolding script doesn't re-discover them:
  - cwd guards (with the 11-corrupted-`project.json` story from the bug report)
  - Idempotency patterns
  - pnpm 11 build-script blocking beyond Prisma (`unrs-resolver`, `nx init`, etc.) +
    pnpm 11.0.x devDeps-not-landing bug → bump to 11.5+
  - `prepare: "husky"` ordering footgun
  - Nx 22+ generators rejecting positional args
  - `npm ls X` doesn't work under pnpm (the bug the kit's own
    `install-pre-commit.sh` had)
  - Post-generation `build` target removal as a code snippet
  - `docker compose up -d` doesn't wait for healthy + the polling loop
  - Final-pass `nx show projects` assertion as a safety net
  - PG18 healthy-state confirmation

### Fixed

- **`scripts/install-pre-commit.sh`** no longer uses `npm ls @biomejs/biome` for its
  dep-presence check — that always returns non-zero under pnpm's strict-flat `node_modules`
  layout, so the script wrongly bailed even when Biome WAS installed. Replaced with a
  PM-agnostic check against `package.json`'s `dependencies` / `devDependencies` (works for
  any package manager).

- **`package.json.template.md`** now documents `@nestjs/swagger`, `helmet`, and
  `@nestjs/throttler` as `apps/api` dependencies in an actual JSON block (the previous
  prose-only mention was missed when copying the dep list).

### Why this release matters

v1.4.0/1.4.1 made the kit's docs / rules / wizard say all the right things, but the kit
still wasn't actually executable end-to-end — a fresh clone + `/setup-project` left you
with a beautifully-configured directory that had no app to run. v1.5.0 closes that loop.

Credit to the downstream user who ran the gauntlet and reported all 17 gotchas with their
exact recovery steps. The Scaffolding section of stack-gotchas.md is essentially a
transcript of that bug report, restructured.

---

## [1.4.1] — 2026-05-18

Hot-fix release. Plugs a wizard drift hole reported by a downstream user:
after pulling 1.4.0 and running `/setup-project`, Claude proposed
PostgreSQL 16 from training data even though every pinned reference in
the kit said 18. Root cause: a couple of stack-summary lines in the
wizard mentioned `PostgreSQL` with no version, leaving the LLM room to
fill in a stale default.

### Fixed

- **`/setup-project` Q3 recommended-stack lines** now include explicit
  versions: `Prisma 7.8 + PostgreSQL 18` in both the `saas-web-app` summary
  and the `api-only` one-liner. No more version-less stack descriptions.

- **`/setup-project` Q4b version-check rules** add an explicit floor:
  *NEVER recommend a version BELOW the kit's pin.* The check is only
  allowed to flag newer stable majors. Documents the PG16 drift incident
  inline so future Claude sessions can't repeat it.

- **`/setup-project` Step 2 "Concern: PostgreSQL"** now names the image
  tag (`postgres:18`) in option 1 and warns that managed/external choices
  must also be PG18+. Removes the last version-less surface in the wizard.

No behaviour changes to any other workflow. Pulling 1.4.1 over 1.4.0 is
a same-session re-clone; no migration steps.

---

## [1.4.0] — 2026-05-17

Distilled from real downstream upgrades: Prisma 6 → 7.8, the testing-runner split between
frontend and backend, and new opt-in integrations for auth, M2M tokens, and logging. Also
sweeps the stack to current stable versions and adds three pieces of long-missing guidance
(API contract, connection pooling, documentation discipline).

### Added

- **TanStack Router as the default frontend router.** New "Routing — TanStack Router"
  section in `.claude/rules/frontend.md` covering file-based routing, **typed/validated search
  params** (Zod-validated, type-safe from route definition through `useSearch()`), loaders +
  TanStack Query interplay, and typed navigation. The frontend stack lock-in is now Vite +
  React + TanStack Router + TanStack Query + Tailwind + shadcn/ui + Zod + Vitest. Search-param
  refactors now break at compile time instead of silently rotting.

- **Opt-in `auth_provider: better-auth | zitadel` in `PROJECT.md`.** Better Auth stays the
  default; **Zitadel** is the alternative for projects wanting an external OIDC identity
  provider plus Management API queries (users, orgs, roles, grants from the backend via a
  service-account). New section in `.claude/rules/api.md` and full setup/gotchas in the new
  `.claude/knowledge/integrations.md`.

- **`hydra` integration — ORY Hydra for machine-to-machine / API token auth.** Complementary
  to Better Auth / Zitadel (which handle humans); Hydra handles service-to-service tokens via
  the `client_credentials` grant. Knowledge file documents the public/admin URL split, the
  introspection guard pattern, and the seed-driven client-registration approach.

- **`logging` integration with provider choice — Axiom / Grafana Cloud / Better Stack.**
  `/setup-project` asks which provider with pros/cons (Axiom = simple logs; Grafana Cloud =
  full observability suite; Better Stack = logs + uptime + on-call in one), records
  `logging_provider` in PROJECT.md, and uncomments the matching env var block. Knowledge file
  has the provider-agnostic NestJS Pino-transport pattern, the React error-boundary +
  `visibilitychange` flush pattern, and the "frontend token must be ingest-only" gotcha.

- **`.claude/knowledge/integrations.md`** — single on-demand reference for opt-in integrations
  (Zitadel, Hydra, logging providers, Valkey). Loaded only when relevant to keep the
  always-loaded baseline lean.

- **OpenAPI/`@nestjs/swagger` as the API contract.** New section in `.claude/rules/api.md`:
  Swagger UI at `/api/docs`, raw spec at `/api/docs-json`, DTOs from `createZodDto` carry
  their shapes automatically (no hand-written `@ApiProperty()`), and re-exporting
  `docs/openapi.json` on contract changes so consumers can diff.

- **PgBouncer guidance.** New section in `.claude/rules/database.md`: transaction-mode pooling
  for runtime queries (`DATABASE_URL?pgbouncer=true`) with a separate `DIRECT_URL` for
  migrations. Sample `DIRECT_URL` env added to `.env.example`. Necessary for serverless and
  many-instance deployments.

- **Cloudflare Tunnel option in `/setup-project`.** Step 2 has a new "Cloudflare Tunnel"
  concern with walkthrough for `cloudflared tunnel create` / `route dns`, plus a
  `CLOUDFLARE_TUNNEL_TOKEN` placeholder in `.env.example`. Useful for exposing local dev to
  OAuth providers, webhook sources, or a home-server-based dev env.

- **Valkey documented as a drop-in Redis replacement.** Same protocol, BSD-licensed.
  `docker-compose.yml` comments call it out, `/setup-project` Q "Redis or Valkey" offers it,
  and the integrations knowledge file has a "no code changes needed" pointer.

- **Documentation discipline section in `ai-workflow.md`.** Adds "API docs (OpenAPI),
  code doc-comments on exported symbols (WHY not WHAT), feature CONTEXT/STATUS, README/module
  docs" to every step's definition of done. New checklist line: "Docs updated — API/OpenAPI
  doc, code doc-comments, README/module docs".

- **Cross-project Jest `moduleNameMapper` gotcha** in `stack-gotchas.md` — the Nx Jest preset
  does NOT resolve every `@app/*` alias automatically; consumer-side `jest.config.ts` needs
  explicit entries. Pulled from real "Cannot find module '@app/foo'" debugging.

- **`useMutation` in `useEffect` deps causes infinite loops** gotcha in `stack-gotchas.md`,
  with the `useRef` guard pattern. Saved real time once already.

- **Debugging meta-lesson** in `stack-gotchas.md`: when a low-level library throws a cryptic
  error after a higher-level upgrade, read the upgrade guide BEFORE auditing peer-dep
  versions. Direct lesson from the Prisma 7 upgrade (`pg-protocol` `ERR_INVALID_ARG_TYPE` was
  the `PrismaPg` constructor change, not a version mismatch).

### Added — security / observability / DX hardening

- **Security middleware section** in `api.md`: `helmet` for headers, `@nestjs/throttler` for
  rate limiting (with sample tight-rate-limit on `/login`). CI smoke-test guidance to fail
  the build if either is missing.

- **Health probes split** — `/api/v1/health/live` (liveness, cheap) vs `/api/v1/health/ready`
  (readiness, DB ping). The old `/health` stays as a readiness alias. Necessary for any
  container orchestrator that distinguishes restart-vs-stop-routing.

- **Zod-validated env loading rule** — `process.env` is parsed through a Zod schema at boot,
  before `NestFactory.create`. Bad env aborts the process; valid env returns a typed `env`
  object so callers don't null-check.

- **BullMQ worker patterns** in `api.md`: job-idempotency rule, retry+backoff defaults,
  dead-letter-queue handling via `failed` event, concurrency guidance, "workers belong in
  their own Nx app" rule.

- **OpenAPI → typed frontend client** pointer in `api.md`: `openapi-typescript` against the
  committed `docs/openapi.json` produces a typed fetch client the frontend uses; backend
  renames surface as TS errors in the frontend at compile time.

- **Playwright E2E section** in `testing.md` — covers `apps/client-e2e/`, scope ("happy-path
  user journeys, NOT exhaustive backend retests"), and CI guidance.

- **Storybook + MSW component workflow section** in `testing.md` — one set of MSW handlers
  drives both stories and Vitest component tests, importing paths from the generated OpenAPI
  client so mocks are type-checked.

- **Commitlint enforcement section** in `code-quality.md` — `@commitlint/cli` +
  `@commitlint/config-conventional` + a husky `commit-msg` hook so bad commit messages can't
  land. Subject-case rule relaxed so `(F[XXX] step N/Total)` tags still pass.

- **Production Dockerfile templates** in `deployment.md` — multi-stage Dockerfile for the
  NestJS API (non-root user, `node:22-alpine` runtime) and the React static build (served by
  `nginx:alpine`). Notes on `docker buildx` for ARM Droplets and worker-process variants.

- **Secret Management section** in `deployment.md` — provider comparison (Doppler, Infisical,
  SOPS + age, HashiCorp Vault, DO App Platform built-in) with explicit DigitalOcean fit per
  provider. Detail in `integrations.md` → "Secret Management" with Doppler-on-Droplet and
  SOPS-on-Droplet deploy-script patterns.

- **New opt-in integrations** added to `PROJECT.md` and `/setup-project` Q6:
  - `tracing` — OpenTelemetry distributed tracing (pairs with Grafana Cloud)
  - `secrets` — production secret manager
  - `feature-flags` — GrowthBook / Unleash / LaunchDarkly
  - `i18n` — react-i18next + ICU MessageFormat
  - `e2e` — Playwright

- **`.github/renovate.json`** — weekly Monday-morning dependency PRs, patch/minor auto-merged
  for stable packages, major upgrades labeled for human review, Prisma/Nx/TanStack/
  testing-library grouped so they bump together. Pairs with `/check-updates`.

- **`/new-adr [title]` command** — scaffolds a new ADR section in
  `.claude/knowledge/decisions.md` with `Status: proposed` and `[fill in]` placeholders.
  Stops here intentionally — the value of an ADR is the human reasoning.

- **`scripts/start-cloudflared.sh`** — companion to the Cloudflare Tunnel option in
  `/setup-project`. Reads `CLOUDFLARE_TUNNEL_TOKEN` from the env and runs the tunnel against
  the configured `API_PORT` / `CLIENT_PORT`.

- **Three ADRs added to `decisions.md`** documenting the bigger 1.4.0 choices:
  - **ADR-005** TanStack Router as the default frontend router
  - **ADR-006** Pluggable auth provider — Better Auth (default) + Zitadel + Hydra
  - **ADR-007** Testing runner split — Vitest (frontend) + Jest (backend)

- **`scripts/harden-server.sh`** — baseline server hardening pass for fresh Ubuntu staging /
  production servers: SSH port change (default 22 → 22222) via a sshd_config drop-in, key-only
  auth, root-password login disabled, `MaxAuthTries 3`, `ClientAliveInterval`, **ufw** with
  default-deny + new SSH port + 80/443, **fail2ban** for SSH brute-force protection,
  **unattended-upgrades** for automatic security patches, optional **Lynis** audit. Safety:
  keeps port 22 open temporarily and tells you to confirm the new port from a separate
  terminal BEFORE closing it. `scripts/staging-setup.sh` now offers to run hardening as the
  first step; `deployment.md` documents the recommended "production bootstrap sequence."

- **`scripts/start-preview.sh`** — builds the React client in production mode and serves it
  via `vite preview` (Nx target if available, falls back to `vite preview` in the app dir).
  Useful for verifying the production bundle locally before deploying, reproducing
  production-only bugs, or running Lighthouse against a realistic build.

### Fixed

- **CI workflow versions** — `.github/workflows/ci.yml` now uses `NODE_VERSION: '22'`,
  `PNPM_VERSION: '11'`, and `postgres:18` instead of `postgres:17`.

- **`scripts/install-prerequisites-ubuntu.sh`** — installs Node 22 (`setup_22.x`) and pnpm 11
  instead of 20 / 10. Version-detection regexes updated to accept 22+ / 11+.

- **`scripts/validate-setup.sh`** — Node-version check raised from `>= 20` to `>= 22`.

- **Prisma 7.8 migration rule corrected from live testing** — the original gotcha said
  "Prisma 7.2+ reads `DATABASE_URL` from `.env` in CWD automatically." A live end-to-end test
  (postgres:18 in a sandbox container, fresh `pnpm add prisma@7.8.0 @prisma/adapter-pg@7.8.0`)
  proved this is no longer true for `prisma migrate dev` — it now requires either a
  `prisma.config.ts` file or an explicit `--url=...` flag. `stack-gotchas.md` and
  `database.md` updated with the verified-working pattern.

- **pnpm 11 + Prisma postinstall** — pnpm 11 blocks Prisma's postinstall scripts by default
  (`ERR_PNPM_IGNORED_BUILDS` for `@prisma/engines`, `esbuild`, `prisma`). Now documented in
  `stack-gotchas.md` Prisma section — either `pnpm approve-builds` or rely on the kit's
  `prisma-generate.sh` hook running `prisma generate` explicitly on schema edits.

- **Nginx `listen` directive** — `staging-setup.sh` previously emitted `listen 443 ssl http2`,
  which Nginx 1.28+ deprecated. Replaced with `listen 443 ssl; http2 on;` (the new form). The
  config still passes `nginx -t` either way, but the deprecated form emits a warning.

### Tested

The 1.4.0 release was validated end-to-end in a Docker-sandboxed clone:

- postgres:18 (live container) reachable from a node:22-alpine runner on a private network
- VERSION ↔ CHANGELOG match, all 6 JSON files parse via `jq`, all 17 shell scripts pass
  `bash -n`
- **Prisma 7.8 migration loop** — `prisma migrate dev --url=$URL` creates `migration.sql` +
  `migration_lock.toml`, applies, records in `_prisma_migrations`; second additive migration
  (`add_source` column) applied as an independent migration
- **PrismaPg adapter CRUD** — `new PrismaPg({ connectionString })`, create / findUnique /
  findMany / delete / count, `prisma.$disconnect()` (no `pool.end()` — adapter owns the pool)
- **Biome 2.4.15** clean on biome.json + a sample TS file
- **Templated nginx config** (rate limits + security headers from `staging-setup.sh`) passes
  `nginx -t`
- **install-pre-commit.sh** correctly detects missing `@biomejs/biome` and instructs the user
- **Backend testing** — Jest + ts-jest + `@Injectable()` + `@Inject()` —
  `Reflect.getMetadata("design:paramtypes", UserService)` returns `[UserRepository]`,
  confirming decorator metadata IS preserved (the entire reason for the Jest-for-backend rule)
- **Frontend testing** — Vitest + jsdom + React + `@testing-library/react` — component
  renders, `screen.getByRole("heading").toHaveTextContent` matcher works
- **Both projects clean against Biome 2.4.15** after `biome check --write`

The findings from this pass are the corrections listed above.

### Changed

- **Testing rule split — Vitest for the frontend, Jest for the backend.** `testing.md` now
  documents both runners with the rule "Vitest for `apps/client` + frontend libs, Jest + ts-jest
  for `apps/api` + backend/domain libs." The decorator-metadata problem only affects NestJS,
  so blanket "never Vitest" was overly broad. New "Vitest Configuration (frontend)" section
  with a sample `vitest.config.ts`. `stack-gotchas.md`, `test-writer` agent, `CLAUDE.md`
  stack overview, README default stack table, and SETUP all updated. The hard rule stays:
  **NEVER run NestJS tests under Vitest** — DI silently breaks.

- **Migrations rule corrected to "raw Prisma from workspace root, NOT Nx."** `database.md`'s
  old "always use Nx" advice contradicted `stack-gotchas.md`'s battle-tested guidance — Nx
  changes CWD before invoking Prisma, breaking Prisma 7's `.env` lookup. Fixed across
  `database.md`, `db-expert.md` (Rule #2), `ai-workflow.md` (Zod-schema propagation step 3),
  `CLAUDE.md` Quick Commands, `setup-project.md` Step D, `deployment.md` CI/CD section, and
  `SETUP.md` Database Setup. `generate`/`seed`/`studio` via Nx are still fine — only
  migrations need workspace-root raw Prisma.

- **`db-expert` agent Rule #3 added** — `PrismaPg` adapter is instantiated with a config
  object, never a `pg.Pool`. Cleanup via `prisma.$disconnect()`. Critical for Prisma 7.

- **Stack version bumps across all template references.** Locked-in:
  - **Prisma 7.4 → 7.8** (driver-adapter mode required)
  - **PostgreSQL 17 → 18**
  - **Nx 20 → 22**, **pnpm 10 → 11**
  - **Vite 6 → 8**, **React 19 → 19.2**
  - **Zod 3 → 4**, **Jest 29 → 30**
  - **TypeScript ~5.6 → ~5.9**, **Node 20+ → 22+**
  - **Redis 7 → 8** in docker-compose; Valkey 8 as an alternative
  - **Biome schema 2.4.11 → 2.4.15** in `biome.json`
  Updated: README "Default Stack" table, SETUP "Stack Overview", `CLAUDE.md` stack overview,
  `package.json.template.md` devDependencies, `setup-project.md` version-check table,
  `check-updates.md` tracked-dependency table, `database.md` stack header, `code-quality.md`.

- **PrismaPg 7.x adapter gotcha** added to `stack-gotchas.md` and `database.md` — pass a
  config object, NOT a `pg.Pool`. Diagnostic clues (`Writer.addCString` trace,
  `ERR_INVALID_ARG_TYPE`, beforeAll hang) listed so the bug is recognizable. Bundled with the
  "Prisma 7 standalone scripts need a driver adapter" entry and the "hand-craft migration SQL
  for non-additive changes" entry.

- **Frontend `pages/` → `routes/`.** With TanStack Router file-based routing, `apps/client/src/routes/`
  replaces `apps/client/src/pages/`. Updated in `frontend.md` Component Structure block,
  `CLAUDE.md` Code Location Cheat Sheet, and frontend conventions.

- **CLAUDE.md stack overview rewritten** to reflect: TanStack Router added, OpenAPI line,
  auth providers (Better Auth or Zitadel + Hydra opt-in), Prisma 7 + PG18 + PgBouncer,
  Vitest/Jest split, Axiom/Grafana/Better Stack logging, Redis/Valkey, Zod (no version).

- **Default Auth section in `api.md`** now opens with an "Auth Provider — Better Auth (default)
  or Zitadel" preamble pointing to `integrations.md` for the Zitadel JWT-guard pattern. Better
  Auth content unchanged below it.

- **`docker-compose.yml`:** Postgres `17 → 18` (both dev + test), pgvector image hints updated
  to `pg18`, Redis `7-alpine → 8-alpine`, Valkey comment added.

- **`.env.example`** restructured: `DIRECT_URL` placeholder for PgBouncer migrations, Zitadel
  block, Hydra block, generalized logging block with Axiom + Grafana Cloud + Better Stack
  env vars, `CLOUDFLARE_TUNNEL_TOKEN` placeholder.

- **`package.json.template.md` Notes** now documents: test-runner package split (Vitest deps
  for frontend, Jest deps for backend), the database lib's three matched Prisma packages
  (`@prisma/client`, `@prisma/adapter-pg`, `prisma`) at 7.8.0+, and the `@nestjs/swagger`
  dependency for `apps/api`.

### Why

Three downstream signals drove this release:

1. **The Prisma 7.8 upgrade hit real bugs.** `/check-updates` recommended Prisma 7.8, and the
   `PrismaPg` constructor change cost real debugging time (cryptic `ERR_INVALID_ARG_TYPE` in
   `pg-protocol`, traced to a caller-side API change). Documenting the diagnostic clues and
   the v6 → v7 instantiation pattern saves anyone else from chasing peer-dep ghosts. The
   "migrations contradiction" between `database.md` and `stack-gotchas.md` was the same
   pattern — both files now agree.
2. **Frontend/backend testing genuinely diverged.** The blanket "never Vitest" rule was
   overcorrecting. Vitest pairs natively with Vite for the frontend (faster, simpler config);
   Jest + ts-jest stays mandatory for NestJS (decorator metadata). Splitting the rule by app
   matches how the runners actually behave.
3. **Multiple downstream projects wanted opt-in alternatives** — Zitadel as the auth provider
   when Better Auth's surface didn't fit; Hydra when machine-to-machine tokens needed their
   own grant flow; and structured logging where a "Sentry checklist item" wasn't enough.
   Making these first-class opt-in integrations (with `/setup-project` wiring + a single
   on-demand knowledge file) keeps the always-loaded baseline lean while letting projects
   pick.

OpenAPI + PgBouncer + documentation discipline are filling in gaps that every real project
ends up addressing anyway — putting them in the kit means they happen by default, not by
afterthought.

No breaking changes to existing commands or workflows. Pulling 1.4.0 into an older project
adds the new integrations and version targets without disturbing existing setups; the
`/check-updates` table will show the bumps and let you decide which to apply.

---

## [1.3.0] — 2026-04-14

New command filling the gap between `/quick` (throwaway same-branch fix, no docs) and `/new-feature` (full spec + dev plan + registry entry). Distilled from a downstream install where the user repeatedly wanted "a `/quick` but on a branch with a tiny paper trail so it can go through PR review."

### Added

- **`/quickbranch [task]` command.** Creates a short-lived `fix/…`, `chore/…`, or `feat/…` branch, writes a dated entry under `docs/quickbranches/{YYYY-MM-DD}-{slug}.md` capturing the user's original request verbatim + a plan + work-done log + commit SHAs, runs validation, commits code + docs separately, then prompts `[y/N]` to push or invoke `/create-pr`. Never auto-pushes. Time-box is 5-30 min; past that, it hands off to `/new-feature` (or `/hotfix` for critical prod bugs). Full comparison table lives inside `.claude/commands/quickbranch.md`.

- **`docs/quickbranches/` folder with `README.md`.** Explains the frontmatter schema (`date`, `branch`, `status`), lifecycle, and where `/quickbranch` sits relative to `/quick`, `/hotfix`, and `/new-feature`. The folder starts empty; the first `/quickbranch` invocation is what populates it.

### Changed

- **`/quick` description reworded** from "Quick fix or small change (5-15 min, no feature docs)" to "Fastest lane — no branch, no docs, commit on current branch (5-15 min). For PR-ready fix on its own branch + doc entry, use /quickbranch instead." Same behaviour, but the one-liner now makes the tradeoff with `/quickbranch` explicit at the point users pick a command. Scope-guard text inside `quick.md` also now suggests `/quickbranch` for 15-30 min fixes before escalating to `/new-feature`.

- **Command index updated** across `help.md`, `?.md`, `CLAUDE.md`, `README.md`, `docs/WORKFLOW-GUIDE.md`, `docs/WORKFLOW-OPTIONS.md`, and `.claude/rules/ai-workflow.md`. Each now lists `/quickbranch` alongside `/quick` with the branch/docs tradeoff called out in the same row. `WORKFLOW-OPTIONS.md` decision tree has a dedicated "SMALL fix, want own branch + lightweight doc + PR" branch.

### Why

The downstream signal was consistent: there are lots of fixes that don't merit `F###` registration + spec + dev plan, but do merit a PR for code review + an audit trail of what was asked for vs what was done. Before this, users had to either (a) use `/quick` and manually create the branch + docs themselves, losing the command-level guardrails, or (b) invoke `/new-feature` for a 20-minute fix and tolerate the ceremony. `/quickbranch` captures the actual shape of "small but reviewable."

The doc entry design deliberately leads with the user's verbatim request — future-you or a reviewer can always reconstruct context from the original phrasing even if the implementation ended up somewhere different. `status: in-progress` → `done` transition mirrors the existing feature-STATUS pattern without dragging in the rest of the feature workflow.

No API changes to existing commands — `/quick`, `/hotfix`, `/new-feature` all behave identically. Fully backwards-compatible for projects on older versions; pulling this version just adds the new command + doc folder.

---

## [1.2.0] — 2026-04-12

Lessons learned from installing the kit into two downstream projects (admin panel + background worker sharing a database). Bundles one hard bug fix (Biome config broken on current Biome versions), one enum gap (no `worker` project type), and three smaller upgrades (project name in statusline, independent multi-repo doc, `.tsbuildinfo` pre-ignored).

### Fixed

- **`biome.json` migrated to Biome 2.4 schema.** The previous config used 2.0-era keys (`files.ignore`, top-level `organizeImports`, `suspicious.noConsoleLog`, `overrides[].include`) that Biome ≥ 2.1 refuses to parse. Every new clone hit this on first `npm run lint` / `pnpm check`. The config now uses the 2.4 schema: `files.includes` with negation syntax, `assist.actions.source.organizeImports`, `suspicious.noConsole`, `overrides[].includes`. `@biomejs/biome` pin in `package.json.template.md` bumped from `2.x.x` → `^2.4.0`. Downstream users stuck on 2.0-era configs can run `npx @biomejs/biome migrate` to auto-upgrade.

### Added

- **New project type: `worker`.** For long-running Node processes (BullMQ consumers, queue runners, cron loops) with no HTTP surface. `api-only` and `cli` were both wrong fits — `api-only` implies HTTP, `cli` implies one-shot invocation. `worker` captures the actual shape: backend + queue (+ optional DB), no frontend, no `app.listen()`. Added to the enum in `PROJECT.md`, `SETUP.md`, `.claude/commands/setup-project.md` (Q3 list), and `docs/MIGRATION-FROM-EXISTING.md`.

- **New doc `docs/INDEPENDENT-MULTI-REPO.md`.** Sibling to `docs/MULTI-REPO-HUB.md`. Describes the "each repo fully independent" multi-repo pattern: per-repo `.claude/`, per-repo feature backlog (independent F-number counters), coordination only on shared runtime infra (DB schema, queue names, env vars). Sweet spot: 2–4 loosely-coupled services sharing a database or queue — admin panel + background worker + webhook handler. `MULTI-REPO-HUB.md` now has a signpost comparing the two patterns; README points at both from the renamed "Multi-Repo Variants" section.

- **Statusline shows `Project: <dirname>`.** Line 1 of `.claude/statusline/statusline.sh` now starts with a magenta-bold `Project:` indicator (basename of the git toplevel) so CLI sessions in multi-repo workspaces can tell which repo they're rooted at. Doesn't affect the VS Code extension (which doesn't render the custom statusline), but for anyone using Claude Code from a terminal it removes "wait, which repo am I in?" ambiguity.

- **`*.tsbuildinfo` pre-ignored.** Added to both the starter's own `.gitignore` and the `.gitignore` snippet in `docs/MIGRATION-FROM-EXISTING.md` Phase 1. TypeScript incremental build caches are machine-local artifacts that have no business in version control; pre-ignoring prevents the "why is my diff full of tsbuildinfo?" confusion on first `tsc` run.

### Why

All five items came from a real downstream install. The Biome breakage and the missing `worker` type were immediate papercuts that would hit anyone cloning the kit today — fixing them is a strict dependency on the kit being usable. The statusline addition and the independent multi-repo doc were lessons worth codifying: once you run two repos side-by-side you find that (a) telling them apart visually matters, and (b) the existing hub-variant doc doesn't cover the simpler pattern most real multi-repo installs actually want.

No API changes to workflow commands (`new-feature`, `start-coding`, etc.). Fully backwards-compatible for projects that cloned an older version — they keep working unchanged; pulling this version only requires the Biome migrate step if they pinned to 2.x and are on a recent install.

---

## [1.1.8] — 2026-04-12

Critical Prisma 7 migration gotcha corrected + NestJS env-loading gotcha added. Based on battle-tested knowledge from a production downstream project.

### Changed

- **Prisma migrations gotcha REPLACED.** Previous advice ("use Nx targets") was wrong for Prisma 7.x. The correct workflow is **raw `npx prisma migrate dev` from the workspace root with explicit `--schema=...` flag** — Nx targets fail because Nx changes CWD and `.env` (containing `DATABASE_URL`) is only at root. Also documents: killing idle DB connections before migrating (avoids advisory-lock timeouts), `db push` vs `migrate deploy` for test DBs.
- **Top Gotchas updated** — brain.md "Top 5" → "Top 6". Prisma entry now mentions the root + `--schema` rule, not just the "no url in datasource" change. New entry: `@nestjs/config` + `process.env`.

### Added

- **New gotcha: `@nestjs/config` does NOT populate `process.env`.** `ConfigModule.forRoot()` only makes values available via `ConfigService.get()` — code reading `process.env.FOO` directly gets `undefined`. Fix: `import 'dotenv/config'` as the FIRST import in `main.ts`. Also use bracket notation `process.env['VAR']` (esbuild-safe, dot notation can be stripped at build time). Symptom: works locally, breaks on staging.

### Why

These are both real failure modes that cost real debugging hours on a production project. The Prisma one actively contradicts what the kit previously recommended — keeping the incorrect advice would route users into the same 2-hour debugging session the downstream project went through. The env-loading gotcha is the canonical "works locally, breaks on staging" fail — worth a first-class entry.

Both gotchas are entirely project-agnostic: they apply to any Prisma 7.x + Nx monorepo and any NestJS project respectively.

---

## [1.1.7] — 2026-04-12

Makes the `/clear` + switch pattern concrete and proactive for x5 users.

### Added

- **`/start-coding` pre-flight check (x5 only)** — when invoked on Opus with `max_plan: x5`, prompts BEFORE running: "You're on Opus about to run `/start-coding ... {{STEP}}`. Implementation is pattern-following, Sonnet is ~5x cheaper. Continue on Opus anyway? [y/N]". Emphasized for `all` autopilot where savings compound per step. Skipped if already on Sonnet or if `max_plan: x20 | legacy`.
- **README "When to `/clear` + switch (x5 specifically)" sub-section** under Tier-Aware Commands with:
  - Short answer: yes, `/clear` + Sonnet + thinking off before `/start-coding all`
  - Why not mid-session (cache invalidation, thinking-block inconsistency, attention)
  - Cost math table: ~$10-20 on Opus vs ~$1-2 on Sonnet for 8-step feature
  - Exact command sequence for the transition
  - When to STAY on Opus (single step, ambiguous plan, cross-repo reasoning, debugging)
- **Enriched phase-transition reminder in `/plan-feature`** — explicit mention that `/start-coding all` is where the switch pays off most, pointing to README for cost reasoning.

### Why

v1.1.6 established the pattern but docs were mostly in the rules file. The decision about switching happens at README-discovery time and at `/start-coding`-invocation time. This patch puts the reasoning where the decision happens — in the README (discovery) and in the command itself (proactive suggestion at the exact moment of decision).

---

## [1.1.6] — 2026-04-12

Phase-based model + thinking switching for x5 Max users. x20 and legacy users are unaffected.

### Added

- **`claude.thinking_mode` field** in `PROJECT.md`. Values: `per-phase` (default for x5) / `always` (default for x20) / `never` (default for legacy) / `ask`.
- **`/setup-project` Step 3d** — asks for thinking mode preference, with defaults keyed to the chosen plan.
- **Extended `/setup-project` Step 3c** — when the user picks x5, shows a phase-based switching explainer (planning = Opus, implementation = Sonnet, transitions via `/clear` + restart).
- **New ai-workflow.md section: "Model & Thinking Switching by Phase (x5 only)"** — rule of thumb, the `/clear`-and-restart pattern, when Claude reminds the user, and when NOT to toggle mid-session (cache invalidation).
- **Phase-transition reminders** in `/new-feature`, `/discuss-feature`, `/generate-spec`, `/plan-feature`, `/plan-execution`. Each reads `claude.max_plan` from `PROJECT.md` and suggests a model switch (via `/clear` + `/resume-feature`) only if `x5` AND on the "wrong" model for the next phase.
- **README** — new "Phase-based Model + Thinking Switching" sub-section under Tier-Aware Commands; updated version-at-top line.

### Rationale

Mid-session model toggles **invalidate the prompt cache** (5-min TTL) and waste budget — the opposite of the goal. The `/clear` + restart pattern aligns with the natural phase boundary: discussion is done, save STATUS.md, clear, switch model (and thinking), reload. Phase transitions already feel like natural sessions breaks; this makes them the model-switch points too.

Thinking mode is treated as a separate question from max_plan because on x20 the user may still prefer thinking always-on or always-off independent of model. On x5, `per-phase` is the natural default (correlates with model).

### Not changing

- x20 and legacy users see no new behavior — reminders only fire for `max_plan: x5`.
- No command API changes. Every phase-transition reminder is additive output, not a behavior block.
- The Stop-for-review rules from v1.1.3 are unchanged; reminders are appended to those messages.

---

## [1.1.5] — 2026-04-12

Documentation release — overhauls README.md to describe the full usage flow and include commands that were missing from the reference table.

### Changed

- **README Commands Reference table** — adds `/generate-spec` and `/plan-execution` (the split-flow planning commands). Adds a "Planning flow choice" diagram showing when to use combined vs split. Clarifies `/complete-feature` as user-invoked-only.
- **New "Usage Flow — First Feature End-to-End" section** in README — 9-phase walkthrough with command examples, STOP markers at review gates, and explicit mentions of both planning flows (combined `/plan-feature` and split `/generate-spec` → `/plan-execution`).
- **New "Gate Map" section** — transition table showing every advance point (🛑 hard stop / ⚙️ auto / ✅ offered), plus a mental-shortcut summary.
- **Replaces the old short "How the Feature Workflow Works" section** which only showed the combined flow and omitted review gates.
- VERSION → 1.1.5.

### Why

Previous README only listed `/plan-feature` in the commands table even after 1.1.3 elevated `/generate-spec` and `/plan-execution` with their own review checkpoints. New developers reading the README couldn't discover the split flow. This fixes that and makes the full lifecycle legible without having to read multiple docs.

---

## [1.1.4] — 2026-04-12

Elevates the "update STATUS.md after every step" rule from a bullet in a list to a firm, prominent requirement. Behavior unchanged — docs clarified.

### Changed

- **`.claude/commands/start-coding.md`** — the post-step checklist (lint → test → **update STATUS.md** → commit) is now marked MANDATORY with an explicit enumeration of the STATUS.md fields to update (progress counter, current step, session-log entry with commit hash + time, last-updated date). Autopilot (`all`) repeats the same mandatory order after each step — never skips STATUS.md even in batch mode.
- Added framing: "STATUS.md is the session-resumption anchor. Skipping its update means the next session's `/resume-feature` loads a stale state. Treat the update as part of the step, not cleanup after."
- The Rules section now says: "a step that completes without a STATUS.md update is an incomplete step."
- README + CHANGELOG + VERSION → 1.1.4.

### Why

With auto-compaction, tier-aware resumption, and `/resume-feature` all depending on STATUS.md as the single source of session state, a skipped update was the cheapest-to-prevent failure mode in the system. Making it non-optional closes that gap.

---

## [1.1.3] — 2026-04-12

Adds explicit STOP-for-review checkpoints after each planning command. No auto-chaining through the planning phase — every artifact gets its own review window.

### Changed

- **`/discuss-feature`** — ends with an explicit "review 2-discussion.md" prompt, then lists both next-step options (combined `/plan-feature` for XS/S, split `/generate-spec` for M/L). No auto-advance.
- **`/generate-spec`** — ends with an explicit "review 3-spec.md" prompt. Do NOT auto-chain into `/plan-execution`. Mentions `/revise-spec` as the escape hatch if scope issues surface.
- **`/plan-execution`** — ends with an explicit "review 4-dev-plan.md" prompt. Do NOT auto-chain into `/start-coding`. Reminds user to create the feature branch before coding.
- **`.claude/rules/ai-workflow.md`** — adds a "Planning Checkpoints (Pre-Implementation Review Gates)" section with a transition table and "when to split vs combine" guidance (XS/S → combined, M/L → split).

### Why

The split planning flow (`/generate-spec` → `/plan-execution`) exists precisely to create a human review checkpoint between "design" (spec) and "execution" (dev plan). Without explicit STOPs, there was ambiguity about whether Claude should prompt-and-continue vs fully hand back control. This patch makes the STOP explicit everywhere in the planning phase — consistent with the existing rules for `/start-coding all → /complete-feature` and `/complete-feature → /create-pr`.

### Flow recap

```
Combined: /new-feature → /discuss-feature → /plan-feature → /start-coding
                              ↑                   ↑
                          2 checkpoints       good for XS/S

Split:    /new-feature → /discuss-feature → /generate-spec → /plan-execution → /start-coding
                              ↑                   ↑                ↑
                          4 checkpoints                         good for M/L
```

---

## [1.1.2] — 2026-04-12

Refinement of 1.1.1. `/complete-feature` remains user-invoked only (autopilot does NOT chain into it), but AFTER the user invokes `/complete-feature`, Claude may proactively OFFER `/create-pr` via `[y/N]` — the user's deliberate `/complete-feature` invocation is the review gate.

### Changed

- **`/complete-feature` can offer `/create-pr` with `[y/N]`.** On "yes", proceeds to `/create-pr` in the same turn. Restores the approved chain pattern. Explicit `[y/N]` prompt is required — no silent auto-forward.
- `/start-coding <name> all` autopilot **still stops** after the last step — never auto-chains to `/complete-feature`.
- `.claude/rules/ai-workflow.md` — "Manual-Only Commands" section refined: completion is the review gate, PR can be offered post-completion.

### Why the refinement

1.1.1 was over-strict. The review-gate concern is satisfied by the user's deliberate `/complete-feature` invocation; requiring them to also type `/create-pr` adds friction without added safety. The firm gate stays where it matters: between implementation (autopilot) and completion (human review).

---

## [1.1.1] — 2026-04-12

Patch release — safety guardrail around completion and PR commands. Superseded by 1.1.2's refinement.

### Changed

- `/complete-feature` and `/create-pr` marked user-invoked only. (Later relaxed in 1.1.2 to allow `/complete-feature` → `/create-pr` offer-chaining.)
- `/start-coding <name> all` autopilot stops after the last step and does not suggest in a way that could auto-continue.
- `.claude/rules/ai-workflow.md` — adds "Manual-Only Commands (Never Auto-Run)" section.

---

## [1.1.0] — 2026-04-12

First versioned release with additions from production use. Backward-compatible — no breaking changes.

### Added

- **Tier-aware command behavior.** Commands that load context (`/resume-feature`, `/trim-context`) now detect whether the running model is Opus 1M (model ID contains `1m`) or another tier (Sonnet 200k). On Opus 1M they load eagerly (full feature directory, wider budget thresholds); on Sonnet they stay lean (CONTEXT.md + STATUS.md only, tighter thresholds). Works without user configuration. See `.claude/rules/ai-workflow.md` and `.claude/knowledge/decisions.md` ADR-003.
- **Claude Max plan question in `/setup-project`.** Asks whether the user is on `x5` Max (mixed Opus/Sonnet usage) or `x20` Max (always Opus 1M). The answer is stored in `PROJECT.md` under `claude.max_plan` and used by tier-aware commands as a fallback when model-ID detection alone isn't enough.
- **Optional `.claude/knowledge/codebase-map.md` pattern.** Template at `.claude/knowledge/codebase-map.md.template` — a short always-loaded file that catalogs the top-level structure, services, and key API endpoints of the project. Useful once the codebase grows past ~20 files. Generated on demand; setup wizard flags it as opt-in after the first feature ships.
- **Multi-repo hub variant documented.** `docs/MULTI-REPO-HUB.md` explains how to adapt the workflow for projects split across multiple repos (e.g. separate frontend + backend): hub repo owns feature docs, branches named the same across repos, commits per repo per step, cross-linked PRs. This is an OPTION — the default is still single-repo/Nx monorepo. Pointer added to `docs/WORKFLOW-OPTIONS.md` and `README.md`.
- **`docs/FUTURE-ROADMAP.md`** documenting intentionally deferred additions:
  - **`/briefing [scope]`** — on-demand deep-load of all code for a subsystem, tier-aware. Deferred until the right default scope vocabulary is learned from real projects.
  - **Multi-feature mode** — load 2–3 active features simultaneously on Opus 1M. Deferred until there's empirical evidence users need it (attention quality concerns).
- **Versioning introduced.** This `CHANGELOG.md` + a plain-text `VERSION` file at the repo root. Releases are git-tagged (`v1.1.0` for this one).
- **ADRs in `.claude/knowledge/decisions.md`**:
  - ADR-003: Tier-aware command behavior.
  - ADR-004: Optional codebase-map knowledge pattern.

### Changed

- `README.md` — adds Tier-Aware Commands paragraph, pointer to `MULTI-REPO-HUB.md` + `FUTURE-ROADMAP.md`, mention of the plan-tier setup question, Changelog link.
- `.claude/rules/ai-workflow.md` — adds a "Tier Awareness" section.
- `.claude/commands/setup-project.md` — adds the plan-tier question early in the flow; persists to `PROJECT.md`.
- `.claude/commands/resume-feature.md` — tier-aware load depth.
- `.claude/commands/trim-context.md` — tier-aware budget thresholds.
- `CLAUDE.md` — references `claude.max_plan` from `PROJECT.md` during session startup.
- `PROJECT.md` — adds a `claude:` block with `max_plan` field.

### Not Changed

- Core feature workflow commands (`/new-feature`, `/discuss-feature`, `/plan-feature`, `/start-coding`, `/update-status`, `/complete-feature`, `/create-pr`) — unchanged.
- Default stack (React + Vite + NestJS + Prisma + Nx + pnpm + Biome) — unchanged.
- Rules files split across 8 files — unchanged (consolidation remains a project-by-project judgement).
- Command names — `/trim-context` kept (not renamed to `/context-audit`) for backward compat; tier-aware logic added in place.

---

## [1.0.0] — pre-2026-04-12

First public release, baselined retroactively as version 1.0.0. Content included:

- 6-phase feature workflow commands (new-feature → discuss → plan → start-coding → update-status → complete-feature → create-pr)
- Quick actions (`/quick`, `/debug`, `/scaffold`, `/review`)
- Entity commands (`/new-module`, `/new-submodule`, `/new-service`, etc.)
- Hotfix workflow (`/hotfix`, `/complete-hotfix`)
- `/setup-project` interactive wizard
- `/trim-context`, `/check-updates`, `/view-features`, `/help`
- Specialized subagents: `db-expert`, `test-writer`, `api-builder`, `ui-builder`
- Institutional memory: `brain.md`, `.claude/knowledge/{stack-gotchas.md, patterns.md, decisions.md}`
- Always-loaded rules split across 8 files
- Feature doc templates (`1-idea`, `2-discussion`, `3-spec`, `4-dev-plan`, `STATUS`, `CONTEXT`)
- Pre-commit + post-edit hooks (Biome format, Prisma generate, status reminder)
- CI/CD workflow + PR template
- Stack: React 19 + Vite 6 + NestJS 11 + Prisma 7 + Nx 20 + pnpm 10 + Better Auth 1.5 + Zod 3

---

[1.1.1]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.1
[1.1.8]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.8
[1.1.7]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.7
[1.1.6]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.6
[1.1.5]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.5
[1.1.4]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.4
[1.1.3]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.3
[1.1.2]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.2
[1.1.1]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.1
[1.1.0]: https://github.com/alonbilu/claude-dev-starter/releases/tag/v1.1.0
