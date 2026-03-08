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

## Database Migrations in CI/CD

```bash
# Non-interactive (staging/production)
pnpm nx run database:migrate:deploy
```

Run migrations **BEFORE** deploying the new app version — never after.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/dev.sh` | Start local dev environment |
| `scripts/setup-env.sh` | Interactive env file wizard |
| `scripts/staging-setup.sh` | Bootstrap a new staging server |
| `scripts/staging-deploy.sh` | Deploy to staging |
| `scripts/production-deploy.sh` | Deploy to production (with safety gates) |
| `scripts/trim-context.sh` | Audit and archive context window bloat |

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
- [ ] Error tracking set up (Sentry recommended)
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
