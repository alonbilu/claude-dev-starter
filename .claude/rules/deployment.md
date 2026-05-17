# Deployment Rules

## Development Environment

**Apps run locally. Infrastructure runs in Docker.**

```bash
# 1. Start infrastructure
docker compose up -d

# 2. Run apps natively (faster HMR, better IDE integration)
pnpm nx serve api      # API: http://localhost:3333
pnpm nx serve client   # Client: http://localhost:4200

# 3. Stop infrastructure
docker compose down
```

**NEVER run apps inside Docker in development** — file sync latency kills hot-reload.

---

## Environment Files

| File | For | Committed? |
|------|-----|-----------|
| `.env` | Local dev | No (gitignored) |
| `.env.staging` | Staging | No |
| `.env.production` | Production | No |
| `.env.example` | Documentation | Yes |

**Setup wizard (recommended):**
```bash
bash scripts/setup-env.sh --env dev
bash scripts/setup-env.sh --env staging
bash scripts/setup-env.sh --env production
```

**Generate a secret manually:**
```bash
openssl rand -base64 32
```

---

## Build

```bash
pnpm nx affected -t build --configuration=production
pnpm nx build api --configuration=production
pnpm nx build client --configuration=production
```

Output: `dist/apps/[name]/`

---

## Production Containers — Dockerfile templates

The kit ships these multi-stage Dockerfile templates as the production-container baseline:

```dockerfile
# apps/api/Dockerfile — NestJS API
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm nx build api --configuration=production

FROM node:22-alpine AS runtime
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/dist/apps/api ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER app
EXPOSE 3333
CMD ["node", "dist/main.js"]
```

```dockerfile
# apps/client/Dockerfile — React static build served by nginx
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm nx build client --configuration=production

FROM nginx:alpine AS runtime
COPY --from=builder /app/dist/apps/client /usr/share/nginx/html
COPY apps/client/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Tune:
- Multi-platform build (`docker buildx`) if you deploy to ARM (Apple Silicon Droplets).
- Mount `.env.production` as a Docker secret, never a plaintext env var (see secret-management
  section below).
- For BullMQ workers (project type `worker`), reuse the NestJS template and swap `CMD` to the
  worker entrypoint.

---

## Database Migrations in CI/CD

```bash
# Non-interactive (staging/production) — raw Prisma from the workspace root
npx prisma migrate deploy --schema=libs/domain/database/prisma/schema.prisma
```

Run migrations **BEFORE** deploying the new app version — never after.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/dev.sh` | Start local dev environment |
| `scripts/start-preview.sh` | Build + serve the React app via Vite preview (production bundle locally) |
| `scripts/start-cloudflared.sh` | Run a Cloudflare Tunnel pointing at the local dev env |
| `scripts/setup-env.sh` | Interactive env file wizard |
| `scripts/harden-server.sh` | One-time server hardening (SSH port, ufw, fail2ban, auto-updates) |
| `scripts/staging-setup.sh` | Bootstrap a new staging server (calls `harden-server.sh` first) |
| `scripts/staging-deploy.sh` | Deploy to staging |
| `scripts/production-deploy.sh` | Deploy to production (with safety gates) |
| `scripts/trim-context.sh` | Audit and archive context window bloat |

---

## Server Hardening — `scripts/harden-server.sh`

Run **once** on every fresh staging / production server, BEFORE exposing it to the internet.
The script is interactive and idempotent — re-running it after a config change is safe.

What it does:

1. **SSH port change** — moves sshd off port 22 to a configurable port (default `22222`).
   Keeps port 22 open in ufw until you confirm you can reconnect on the new port. Drop-in
   `/etc/ssh/sshd_config.d/99-hardening.conf` so the change survives package upgrades.
2. **SSH lockdown** — `PasswordAuthentication no`, `PermitRootLogin prohibit-password`,
   `MaxAuthTries 3`, `ClientAliveInterval 300`, no agent/X11/TCP forwarding, key-only auth.
3. **Authorized key** — optional: append a fresh public key to `/root/.ssh/authorized_keys`
   before disabling password auth (so you don't lock yourself out).
4. **ufw** — default deny incoming, default allow outgoing, allow: new SSH port + 80 + 443.
5. **fail2ban** — 5 failed SSH attempts → 1h ban, using ufw as the ban action. Listens on both
   the new and old SSH ports during the transition.
6. **Unattended security updates** — `unattended-upgrades` + apt periodic config; optional
   email notifications on update events.
7. **Optional Lynis audit** — runs a `lynis audit system --quick` at the end and points you
   at `/var/log/lynis.log` for the report.

**Safety:** the script opens the new SSH port in ufw BEFORE restarting sshd, keeps port 22
open as a temporary fallback, and tells you to verify the new port from a separate terminal
before closing 22 (`ufw delete allow 22/tcp`). It never `--force`-disconnects you.

`scripts/staging-setup.sh` offers to run it as the first step; for production servers, run it
standalone first and reconnect before anything else.

### Nginx-level protections — already wired by `staging-setup.sh`

The Nginx config the kit writes (when Nginx is the reverse proxy) includes:

- **Per-IP rate limits** — `api_limit` (10 req/s, `burst=20`) for general API traffic;
  `login_limit` (5 req/min, `burst=5`) for `/api/v1/(auth|login|signup|register|reset-password)`.
  Defined as `limit_req_zone` in `/etc/nginx/conf.d/rate-limits.conf`; consumed per-location
  in the site config.
- **Per-IP concurrent connection cap** — `limit_conn conn_limit 20`.
- **HTTP/2** enabled on TLS, `keepalive_timeout 65s`.
- **Body-size cap** — `client_max_body_size 10M`. Override per-location for upload routes.
- **Security headers** — `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`,
  `Permissions-Policy` (camera/mic/geo locked off by default), `Strict-Transport-Security`
  with `preload`. Complementary to `helmet` on the API; both layers help.
- **gzip** for text-ish responses (`text/*`, JSON, JS, SVG).
- **Health-probe routes are excluded from rate limiting** and have `access_log off` so
  Kubernetes / Docker probe noise doesn't drown the access log.

Tune these via `/etc/nginx/sites-available/app` and `/etc/nginx/conf.d/rate-limits.conf`.
Common adjustments:
- Behind Cloudflare / a load balancer — uncomment `set_real_ip_from` + `real_ip_header` so
  the rate limits key on the real client IP, not the LB's IP.
- File-upload route — `location /api/v1/upload { client_max_body_size 100M; ... }`.
- Stricter rate on a payment-webhook endpoint — define a new `limit_req_zone` and apply it
  per-location.

---

## Production Server Bootstrap — recommended sequence

For a brand-new production server (fresh DO Droplet, fresh AWS EC2, etc.):

```
1. SSH in as root using a temporary password (or the cloud-provider's initial key)
2. Upload your real SSH public key:
     scp ~/.ssh/id_ed25519.pub root@<ip>:/tmp/admin.pub
3. Run:
     bash scripts/harden-server.sh
   - Provide the new SSH port (default 22222) and the path /tmp/admin.pub
   - Keep this session open until step 5 succeeds
4. From a NEW terminal:
     ssh -p 22222 root@<ip>
   Confirm it works.
5. Close the temporary port 22:
     ufw delete allow 22/tcp
6. Then run scripts/staging-setup.sh (or your production equivalent) to install the app stack
```

For DigitalOcean App Platform, hardening doesn't apply (you don't manage the host) — focus on
the secret-management section instead.

---

## Production Deploy Safety Gates

`scripts/production-deploy.sh` enforces:

1. Confirm by typing `deploy`
2. Verify branch is `main` and working tree is clean
3. Verify `NODE_ENV=production` and no `localhost` in `.env.production`
4. Show pending migrations — confirm before applying
5. Health check retry loop (3x) — auto-rollback if all fail

---

## Deployment Checklist

- [ ] All tests pass (`pnpm nx affected -t test`)
- [ ] Build succeeds (`pnpm nx affected -t build`)
- [ ] No empty secrets in `.env.production`
- [ ] Pending migrations reviewed
- [ ] Health check working: `GET /api/v1/health`
- [ ] CORS configured for production domain
- [ ] SSL/HTTPS configured
- [ ] Error tracking / logging set up (Axiom `logging` integration, or Sentry)
- [ ] Uptime monitoring set up (UptimeRobot is free)
- [ ] Database backup taken before major migrations

---

## Security Non-Negotiables

```
NEVER:
  Commit any .env* file (except .env.example)
  Reuse secrets across dev / staging / production
  Use localhost URLs in staging or production env files
  Deploy without reviewing pending migrations

ALWAYS:
  chmod 600 on all .env files (scripts/setup-env.sh does this automatically)
  Generate secrets with: openssl rand -base64 32
  Use separate secrets per environment
  Back up the database before running major migrations
```

---

## Secret Management — production

For local dev, `.env` + `chmod 600` is fine. For production, do NOT keep plaintext
`.env.production` on the server. Pick one — `/setup-project` records `secrets_provider` if
the `secrets` integration is enabled:

| Tool | What it is | DigitalOcean fit | Trade-off |
|------|-----------|------------------|-----------|
| **DigitalOcean App Platform — built-in encrypted env vars** | Native to App Platform | Native — set via UI / `doctl` | No rotation, no audit log |
| **Doppler** | Hosted secrets manager with great UX | Works on Droplets (CLI fetch) + App Platform (env sync) | Hosted service; small free tier |
| **Infisical** | Open-source secrets manager (hosted or self-hosted) | Self-host on a Droplet, or use Infisical Cloud | More moving parts if self-hosted |
| **SOPS + age** | Encrypted secrets stored IN the repo, decrypted on deploy with an age key | Works anywhere — including a Droplet with no extra service | Git-native; no centralized rotation |
| **HashiCorp Vault** | Self-hosted secrets vault — audit + rotation built-in | Run on a Droplet | Heavyweight; full ops burden |

**For DigitalOcean specifically:**

- **App Platform users** — start with built-in encrypted env vars; graduate to Doppler when
  you need rotation, multi-env sync, or an audit log.
- **Droplet users** — **Doppler** if you want a hosted service; **SOPS + age** if you'd rather
  keep secrets in the repo (encrypted) and avoid running another service. SOPS works well on
  a single Droplet — your deploy script decrypts to `.env.production` at deploy time using an
  age key that lives only on the server.
- **Vault on a Droplet** — over-engineered unless you have multiple apps, dynamic database
  credentials, or strict compliance requirements.

`.env*` files stay git-ignored even when SOPS is encrypting their counterparts in the repo.
See `.claude/knowledge/integrations.md` → Secret Management for code patterns.

---

## Deployment Target Options

Configure in `PROJECT.md` → `target:`. Options:

| Target | Setup |
|--------|-------|
| `digital-ocean` | Droplet + Docker Compose, or App Platform |
| `vercel` | Vercel (frontend) + separate API host |
| `aws` | EC2/ECS, adapt scripts accordingly |
| `docker-self-hosted` | Any server with Docker Compose |
| `cloudflare` | Pages/Workers (no traditional server) |
| `none` | Not decided yet |

Run `/setup-project` to wire the correct scripts for your chosen target.
