# /setup-project

You are running an interactive project setup wizard. Your job is to ask questions one at a time,
suggest sensible defaults, collect all answers, then configure the project automatically.

**DO NOT dump a wall of options at once. Ask ONE question, wait for the answer, then ask the next.**

---

## Step 0 — Pre-Flight Validation

Before starting setup, validate the environment:

**Check prerequisites:**

1. **Node.js 20+**
   ```bash
   node --version
   ```
   If not found or < 20: STOP. Tell user:
   ```
   Node.js 20 or higher is required.
   Install from: https://nodejs.org/ (LTS recommended)
   Then run /setup-project again.
   ```

2. **pnpm 10+**
   ```bash
   pnpm --version
   ```
   If not found: STOP. Tell user:
   ```
   pnpm 10+ is required (npm/yarn won't work).
   Install with: npm install -g pnpm
   Then run /setup-project again.
   ```

3. **Git initialized**
   ```bash
   git status
   ```
   If error: STOP. Tell user:
   ```
   This must be a git repository.
   Initialize with: git init && git add . && git commit -m "initial"
   Then run /setup-project again.
   ```

4. **Docker (optional but recommended)**
   ```bash
   docker --version
   ```
   If not found: WARN
   ```
   ⚠️  Docker not found. You'll need it to run PostgreSQL/Redis locally.
   Install from: https://www.docker.com/
   Or you can set up managed databases later.
   Continuing...
   ```

**If all checks pass:**
```
✓ Pre-flight checks passed. Starting setup wizard...
```

---

## Step 0 — Connect to Your Own GitHub Repo

Before anything else, check whether this repo is still pointing at the template remote:

```bash
git remote get-url origin
```

**If the URL contains `claude-dev-starter`** (i.e. still pointing at the template):

Tell the user:
```
First, let's connect this project to its own GitHub repo.
The current remote still points to the claude-dev-starter template — we need to change that.

What should the new GitHub repo be called?
Examples: my-project, acme-platform, devtools

Format: OWNER/REPO-NAME  (e.g. alon-codes/my-project)
Or just the repo name if creating under your personal account (e.g. my-project):
```

Once they provide the name:
1. Run: `git remote remove origin`
2. If `gh` CLI is available and authenticated (`gh auth status` succeeds):
   - Ask: `Create as public or private? [private]:`
   - Run: `gh repo create OWNER/REPO --private/public --source=. --remote=origin --push`
   - Confirm success and show the new repo URL
3. If `gh` is not available or not authenticated:
   - Tell the user:
     ```
     gh CLI isn't authenticated. Please do one of the following, then come back:

     Option A (recommended):
       gh auth login
       gh repo create OWNER/REPO --private --source=. --remote=origin --push

     Option B (manual):
       1. Create a new repo at https://github.com/new
       2. git remote add origin https://github.com/OWNER/REPO.git
       3. git push -u origin main

     Once your remote is set up, run /setup-project again to continue.
     ```
   - Stop here and wait.

4. **Replace README.md** — the current README describes the template itself, not this project.
   Write a clean project README using the project name and a one-line description (ask for it):
   ```
   In one sentence, what does this project do? (This will go in the README — you can always update it later)
   ```
   Then write `README.md` with this minimal structure:
   ```markdown
   # [project-name]

   [one-line description]

   ## Getting Started

   ```bash
   pnpm install
   pnpm nx serve api      # http://localhost:[api-port]
   pnpm nx serve client   # http://localhost:[client-port]
   ```

   ## Development

   This project uses the [Claude Dev Starter Kit](https://github.com/alonbilu/claude-dev-starter) workflow.
   See `docs/WORKFLOW-GUIDE.md` for the feature development process.
   ```
   Commit the new README: `git add README.md && git commit -m "chore: replace template README with project README"`

**If the URL does NOT contain `claude-dev-starter`** — the remote is already customized. Skip this step silently and proceed to Step 1.

---

## Step 1 — Collect Project Identity

Ask these questions one at a time, in order:

**Q1: Project name**
```
What's the name of this project? (used in Docker container names, scripts, and logs)
Example: my-app, acme-platform, devtools
```

**Q2: Project description**
```
In one sentence, what does this project do?
(Helps me recommend the right stack configuration)
```

**Q3: Project type**

Based on their description, recommend a type. Show the recommended stack for each:

```
Based on your description, I'd recommend:

  ➤ 1. saas-web-app (recommended)
       Stack: React + Vite + NestJS + Prisma + PostgreSQL + Better Auth
       UI: Tailwind + Shadcn/ui | Forms: React Hook Form + Zod
       Data: TanStack Query v5 | Testing: Jest | Linting: Biome

  2. api-only        — NestJS + Prisma + PostgreSQL (no frontend)
  3. fullstack-web   — Same as saas-web-app but no billing/auth layer
  4. cli             — Node.js CLI (no frontend, no database)
  5. library         — Reusable package (types, utils, SDK)
  6. static-site     — React + Vite (no backend)

Enter a number [1]:
```

**Important:** The default stack (saas-web-app) is battle-tested and pre-configured in all template files.
Choosing it means everything works out of the box. Other types may require manual adjustments.

**Q4: Stack confirmation** (only ask if they chose saas-web-app or fullstack-web)
```
Here's your default stack — all pre-configured and ready to go:

  Frontend:   React + Vite + Tailwind + Shadcn/ui
  State:      TanStack Query v5 (server) + Zustand (client, if needed)
  Forms:      React Hook Form + Zod resolver
  Backend:    NestJS (with Nx workspace)
  Database:   Prisma + PostgreSQL 17
  Auth:       Better Auth (cookie-based sessions)
  Validation: Zod (single source of truth for types)
  Testing:    Jest (never Vitest — breaks NestJS DI)
  Linting:    Biome (never ESLint)
  Monorepo:   Nx + pnpm

Want to change any of these? [no/yes]:
```

If they say **yes**, ask which specific tool they want to swap and warn about compatibility:
```
Which tool do you want to change?
Note: Some swaps require manual configuration changes.

  - Frontend framework (React → Next.js, Svelte, etc.)
  - CSS framework (Tailwind → CSS Modules, Styled Components, etc.)
  - Backend framework (NestJS → Express, Fastify, etc.)
  - Database (PostgreSQL → MySQL, SQLite, MongoDB, etc.)
  - Auth provider (Better Auth → NextAuth, Clerk, etc.)
  - ORM (Prisma → Drizzle, TypeORM, etc.)

Type the tool category to change, or "done" when finished:
```

For each swap, explain the trade-offs clearly. Here are the key swap explanations:

**Frontend framework: React + Vite vs Next.js**

If the user considers Next.js, explain:

```
React + Vite + NestJS (default) vs Next.js:

  Default setup (React + Vite frontend, NestJS backend):
  ✅ Clear separation — frontend and backend are independent apps
  ✅ Backend flexibility — NestJS gives you decorators, guards, interceptors,
     dependency injection, module system, BullMQ queues, WebSockets
  ✅ Independent scaling — deploy frontend (CDN/static) and API separately
  ✅ Team splitting — frontend and backend devs work independently
  ✅ Full control over API — versioning, middleware, background jobs
  ❌ Two servers to run locally (pnpm nx serve api + client)
  ❌ More initial boilerplate (separate apps, CORS config)

  Next.js (replaces both React + Vite AND NestJS):
  ✅ One framework — frontend + API routes in one project
  ✅ SSR/SSG — server-side rendering, static generation, ISR out of the box
  ✅ SEO — better for content-heavy / public-facing sites
  ✅ Simpler deploy — single Vercel deploy handles everything
  ✅ Less boilerplate for simple APIs (API routes vs full NestJS setup)
  ❌ API routes are thin — no DI, no guards, no interceptors, no module system
  ❌ Background jobs need a separate service anyway (no BullMQ equivalent)
  ❌ Coupled deploy — frontend and API scale together
  ❌ Vendor lock-in risk with Vercel-specific features (middleware, edge runtime)
  ❌ Harder to split team across frontend/backend boundaries

  Recommendation by project type:
  • SaaS/platform with complex backend (queues, WebSockets, multi-tenant)?
    → Stay with React + Vite + NestJS (default)
  • Content site, marketing site, or simple CRUD app?
    → Next.js is a good fit
  • SSR/SEO for public pages + complex backend?
    → Next.js frontend + NestJS as separate API
  • B2B whitelabel / embeddable widget + API?
    → Stay with default (see below)

Which would you like?
```

**B2B whitelabel / embeddable storefront guidance:**

If the user describes a B2B whitelabel product (embedded widget, storefront inside customer sites, JS SDK), explain:

```
For B2B whitelabel + API, the default stack (React + Vite + NestJS) is the right choice.
Next.js would actually be a worse fit. Here's why:

Your whitelabel UI lives INSIDE the customer's website — via <script> tag, iframe,
or Web Component. It's not a standalone page that Google crawls.
SSR (Next.js's main advantage) gives you nothing here.

Next.js assumes it owns the page (routing, <head>, HTML shell).
An embeddable widget should NOT own the page.

Recommended architecture:

  NestJS API (your core product)
    ├── Public API — customers integrate their own backends
    ├── Admin API — your internal dashboard
    └── Widget config API — per-customer settings (theme, products, branding)

  Two frontend build targets:
    1. Embeddable widget (React, Vite library mode → single JS bundle)
       → Loaded via <script src="https://cdn.you.com/widget.js">
       → Per-customer config (colors, logo, products) via API
       → CDN-hosted, scales infinitely, no per-customer server cost

    2. Admin dashboard (React + Vite SPA)
       → Your team manages customers, products, config
       → Standard internal SPA, no SSR needed

Why this beats Next.js for whitelabel:
  ✅ Widget is a lightweight client-side bundle — no server per customer
  ✅ API-first — customers who don't want your widget build their own UI
  ✅ CDN-hosted widget — infinite scale, zero per-customer server costs
  ✅ NestJS handles complexity — multi-tenancy, auth, catalog, webhooks
  ❌ Next.js owns the page — conflicts with embedding in customer sites
```

If they choose Next.js:
- Warn: "This replaces both the React+Vite frontend AND the NestJS backend. The template's API rules (api.md), NestJS-specific gotchas, and backend subagents (api-builder) won't apply. You'll need to update .claude/rules/api.md for Next.js API routes and .claude/rules/frontend.md for App Router patterns."
- Update PROJECT.md frontend to "Next.js" and backend to "Next.js API Routes"
- Note which rule files need manual updating

**Other swap warnings:**

For NestJS → Express/Fastify:
- Warn: "Template rules (api.md), gotchas (DI, decorators), and the api-builder agent are NestJS-specific. You'll need to rewrite .claude/rules/api.md and .claude/agents/api-builder.md for your framework."

For Prisma → Drizzle/TypeORM:
- Warn: "Template rules (database.md), migration workflow, the db-expert agent, and the Prisma auto-generate hook are Prisma-specific. You'll need to update .claude/rules/database.md, .claude/agents/db-expert.md, and .claude/hooks/prisma-generate.sh."

For PostgreSQL → MySQL/SQLite/MongoDB:
- Warn: "docker-compose.yml, migration scripts, and raw SQL examples assume PostgreSQL. You'll need to update infrastructure config."

For Better Auth → NextAuth/Clerk:
- Warn: "Auth rules in api.md (AllowAnonymous decorator, cookie sessions, AuthGuard) are Better Auth-specific. Update .claude/rules/api.md for your auth provider."

Then update PROJECT.md and relevant config files accordingly.

If they say **no** (default), proceed with the pre-configured stack.

**Q4b: Version freshness check** (automatic — runs after stack is confirmed)

Before continuing, check if any core dependencies have newer stable major versions
than what the template ships with. This ensures every new project starts on the latest
stable versions, not whatever was hardcoded when the template was last updated.

**Search the web** for the latest stable version of each confirmed stack tool:

| Dependency | Template version | Search query |
|-----------|-----------------|--------------|
| React | 19 | `React latest stable version [current year]` |
| Vite | 6 | `Vite latest stable version [current year]` |
| Tailwind CSS | v4 | `Tailwind CSS latest stable version [current year]` |
| NestJS | 11 | `NestJS latest stable version [current year]` |
| Prisma | 7.4 | `Prisma ORM latest stable version [current year]` |
| PostgreSQL | 17 | `PostgreSQL latest stable version [current year]` |
| Better Auth | 1.5 | `Better Auth latest stable version [current year]` |
| Biome | 2 | `Biome linter latest stable version [current year]` |
| pnpm | 10 | `pnpm latest stable version [current year]` |

**Rules:**
- Only flag **major version** upgrades (e.g., React 19 → 20, not 19.2 → 19.3)
- Only flag versions that have been **stable for at least 1 month** (no RC/beta)
- Skip tools the user swapped out in Q4

**If newer versions are found**, show:
```
I checked for newer stable versions of your stack. Found updates:

  [tool] [template version] → [latest version] (stable since [date])
    What's new: [1 sentence — key improvement]
    Breaking changes: [yes/no]
    Effort to upgrade: [low/medium/high]

  [tool] [template version] → [latest version] ...

Would you like to upgrade any of these? I'll update all version references
across the template. [yes/no]
```

If the user says **yes**, for each accepted upgrade:
1. Update version references in: README.md, SETUP.md, rules files, docker-compose.yml,
   CI workflow, package.json.template.md, biome.json, install script, and this setup command
2. Warn about any breaking changes or migration steps needed
3. Continue with setup

If the user says **no**, continue with the template's current versions.

**If all versions are current:**
```
✓ All stack versions are up to date — no newer stable releases found.
```
Continue immediately.

**Also update the weekly check timestamp** so `/check-updates` doesn't nag right after setup:
```bash
date +%s > .claude/.last-update-check
```

**Q5: Active layers** (pre-selected based on project type, just confirm)
```
Active layers for your [type] project:

  [x] frontend      — React + Vite + Tailwind + Shadcn/ui
  [x] backend       — NestJS + Zod validation
  [x] database      — Prisma + PostgreSQL 17
  [x] auth          — Better Auth (cookie-based sessions)
  [ ] mobile        — React Native (not included by default)

Press Enter to accept, or type layer names to toggle:
```

**Q6: Optional integrations** (only show integrations relevant to the active layers)
```
Which optional integrations do you need?

  [ ] payments   — Stripe subscriptions & billing
  [ ] email      — Transactional email (Resend + React Email)
  [ ] storage    — File uploads (S3-compatible object storage)
  [ ] llm        — LLM providers (OpenAI, Anthropic, etc.)
  [ ] rag        — Vector search / embeddings (requires pgvector)
  [ ] queue      — Background jobs (BullMQ + Redis)
  [ ] realtime   — WebSockets / SSE

Type integration names to enable (space-separated), or press Enter to skip all:
```

**Q7: Deployment target**
```
Where will this be deployed?

  1. digital-ocean    — DigitalOcean Droplet or App Platform (recommended)
  2. vercel           — Vercel (frontend) + separate API
  3. aws              — AWS (EC2, ECS, Lambda)
  4. docker-self-hosted — Self-hosted Docker Compose
  5. cloudflare       — Cloudflare Pages/Workers
  6. none             — Not decided yet

Enter a number [1]:
```

---

## Step 2 — Infrastructure Setup

Based on the chosen project type and active layers, present a suggested infrastructure configuration.
Then ask about each concern conversationally — one at a time.

**Example suggestion for saas-web-app with database + auth:**
```
Here's the suggested infrastructure for your [type] project:

  PostgreSQL     → Docker container (local dev)
  Test Database  → Separate Docker container
  Redis          → Docker container (for background jobs)  ← only if queue enabled
  Run apps       → Locally (faster hot-reload, better DX)

Does this work, or would you like to change anything? [yes/change]:
```

If they say "change", ask about each concern one at a time:

**Concern: PostgreSQL**
```
How do you want to run PostgreSQL?

  1. Docker locally (recommended — zero config, isolated)
  2. Managed cloud (Supabase, DigitalOcean, Railway, Neon)
  3. I have my own PostgreSQL running

[1]:
```

**Concern: Test database** (only if database layer is active)
```
Do you want a separate test database?

  1. Yes — separate Docker container (port 5443) — recommended for integration tests
  2. Same DB, different schema — simpler but can interfere with dev data
  3. Skip — no integration tests planned

[1]:
```

**Concern: Redis** (only if queue or realtime integration is enabled)
```
How do you want to run Redis?

  1. Docker locally (recommended)
  2. Managed cloud (Redis Cloud, Upstash)
  3. Not needed — remove from setup

[1]:
```

**Concern: pgvector** (only if rag integration is enabled)
```
The 'rag' integration requires pgvector. I'll switch the PostgreSQL image to
pgvector/pgvector:pg17 in docker-compose.yml. This is compatible with standard Postgres.

Confirm? [yes]:
```

**Concern: App execution**
```
How do you want to run your apps during development?

  1. Locally (recommended — faster hot-reload, better IDE integration)
  2. Fully Dockerized (adds Dockerfiles for api and client)

[1]:
```

---

## Step 3 — Configure Ports

Ask for ports, showing context-aware defaults (only show ports for services being set up locally):

```
Let's configure ports. Press Enter to accept defaults.

  API port          [3333]:
  Client port       [4200]:   ← skip if no frontend layer
  DB dev port       [5442]:   ← skip if Postgres is managed cloud
  DB test port      [5443]:   ← skip if no test DB
  Redis port        [6379]:   ← skip if no local Redis
```

---

## Step 3b — Context Auto-Save Checkpoints

```
Context auto-save checkpoints — saves feature status before auto-compaction can erase progress.

  First save at   [60]% — early snapshot
  Second save at  [85]% — final save + prompt to /compact or start fresh

Press Enter to keep defaults, or enter custom values (10-95):
```

Only show this if the user changed ports (i.e., they're the type to customize). Otherwise accept defaults silently.

---

## Step 3c — Claude Max Plan

Ask once which Claude Max plan the user is on. This becomes the **default tier** for tier-aware commands when model-ID detection alone is ambiguous.

```
Which Claude Max plan are you on?

  1) x20 Max — always using Opus 1M (eager context loading by default)
  2) x5 Max  — mix of Opus and Sonnet (lean loading by default, Opus unlocks when detected)
  3) Legacy / not on Max — lean loading (Sonnet-safe)

Enter 1/2/3 [default: 2]:
```

Record the answer as one of `x20` | `x5` | `legacy` — stored later in `PROJECT.md` under a `claude:` block by Step 4.

**Why:** tier-aware commands (e.g. `/resume-feature`, `/trim-context`) check the running model ID first. If the ID contains `1m`, they load eagerly. If not, they consult this declared default. On x20, the user is almost always on Opus 1M; on x5, they switch between tiers, so "lean by default, eager when Opus is detected" is safer. `legacy` means the user doesn't have Max — unusual but possible for users bringing their own API key; the answer just sets the default bucket.

This question replaces the need to manually re-declare tier preferences per session. It's asked exactly once during setup.

---

## Step 4 — Write PROJECT.md

Write the fully populated `PROJECT.md` with:
- `configured: true`  ← **CRITICAL: always include this line, replacing `configured: false`**
- type: (chosen type)
- active layers with [x] / [ ] checkboxes
- enabled integrations with [x] checkboxes
- target: (chosen deployment)
- Ports section with the configured values
- Context auto-save checkpoints (first_save, second_save)
- **Claude block** (new in v1.1.0):
  ```yaml
  claude:
    max_plan: <x20 | x5 | legacy>   # from Step 3c
  ```

This `configured: true` flag is what tells Claude in future sessions that setup is complete.
Without it, Claude will keep showing the first-time setup prompt every session.

---

## Step 5 — Patch Code Files

Apply the configuration to every hardcoded value in the repo. Make these changes automatically:

| File | What to update |
|------|---------------|
| `docker-compose.yml` | Port mappings; remove services not needed; switch to pgvector image if rag enabled; update container name prefix from YOUR_APP_NAME to the project name |
| `.env.example` | DATABASE_URL port; REDIS_URL (remove if no Redis); CLIENT_URL port; uncomment opt-in vars for enabled integrations only |
| `apps/api/src/main.ts` | `await app.listen(PORT)` → configured API port |
| `vite.config.ts` | `server: { port: CLIENT_PORT }` → configured client port |
| `scripts/dev.sh` | Port refs in health-check curls; container name prefix |
| `scripts/staging-setup.sh` | YOUR_DOMAIN, YOUR_APP_DIR placeholders |
| `scripts/staging-deploy.sh` | Health-check URL port, app directory |
| `CLAUDE.md` | "API port: XXXX | Client port: XXXX" in stack overview |
| `.claude/brain.md` | Port references in quick-ref section |

---

## Step 6 — Summary + Guided Execution

Print a confirmation table of every change made, then offer to run setup steps with permission:

```
Setup complete! Here's what was configured:

  Project name:    [name]
  Type:            [type]
  Layers:          [active layers]
  Integrations:    [enabled integrations, or "none"]
  Infrastructure:  [summary of infra choices]
  Ports:           API=[port], Client=[port], DB=[port]

Files updated: PROJECT.md, docker-compose.yml, .env.example, scripts/dev.sh, CLAUDE.md, brain.md
```

Then walk through setup steps, asking permission before each:

```
Ready to finish setup? I can run these steps for you:

  Step A: Install dependencies
  → pnpm install
  Run this now? [yes/no/skip]

  Step B: Install ccusage (powers the context metrics status line)
  → npm install -g ccusage
  The custom status line shows context window %, cache efficiency, branch, and session duration.
  Run this now? [yes/no/skip]

  Step C: Start Docker infrastructure
  → docker compose up -d
  Run this now? [yes/no/skip]

  Step D: Run initial database migration  ← only if database layer is active
  → pnpm nx run database:migrate:dev --name init
  Run this now? [yes/no/skip]

  Step E: Verify build
  → pnpm nx build api
  Run this now? [yes/no/skip]
```

For each approved step: run it, show output summary, confirm success, move to next.

**Error handling for each step:**

**Step A — pnpm install**
```
Common issues:
  • "command not found: pnpm" → install with: npm install -g pnpm
  • "ERR_EACCES permission denied" → fix with: npm config set prefix ~/.npm-global
  • "lockfile version mismatch" → delete pnpm-lock.yaml and retry

If fails: offer to diagnose or skip (can run manually later)
```

**Step B — ccusage (context metrics)**
```
Common issues:
  • "npm ERR! 404" → ccusage not available in npm
  • "permission denied" → try: sudo npm install -g ccusage

If fails: mark optional, explain it powers the status line
```

**Step C — docker compose up**
```
Common issues:
  • "docker: command not found" → Docker not installed
  • "Cannot connect to Docker daemon" → Docker not running
  • "port already allocated" → conflict with existing container, suggest docker compose down
  • "pull access denied" → Docker auth issue, suggest docker login

If fails: diagnose which service failed (postgres/redis) and suggest fixes
```

**Step D — database migrate**
```
Common issues:
  • "could not connect to server" → PostgreSQL not ready (wait 10s, retry)
  • "FATAL: database does not exist" → run: pnpm nx run database:generate first
  • "permission denied" → DATABASE_URL env var issue

If fails: suggest running: docker compose logs postgres (to inspect logs)
```

**Step E — build**
```
Common issues:
  • "error TS7030: Not all code paths return a value" → TypeScript error, show snippet
  • "Cannot find module" → dependency missing, suggest: pnpm install
  • "Biome check failed" → lint error, suggest: pnpm check:fix

If fails: show error snippet, offer specific fix based on error message
```

If a step fails: diagnose the error, show specific recovery command, offer to retry.

---

## Step 7 — Suggest MCP Plugins (Optional)

Based on the project type and enabled integrations, suggest relevant Claude MCP plugins.
Only suggest plugins that are genuinely useful for the chosen setup. Ask once:

```
Would you like suggestions for Claude MCP plugins that could help with this project? [yes/no]
```

If yes, suggest based on what's enabled:

| Integration / Layer | Suggested MCP Plugin | Why |
|---------------------|---------------------|-----|
| database layer      | `@modelcontextprotocol/server-postgres` | Query and inspect your database from Claude |
| Any project         | `@modelcontextprotocol/server-filesystem` | Direct filesystem access |
| Any project         | `@modelcontextprotocol/server-github` | GitHub PR/issue management from Claude |
| storage integration | `@modelcontextprotocol/server-aws-kb-retrieval` | S3 bucket access |
| Any project with browser | `@modelcontextprotocol/server-puppeteer` | Browser automation for testing |

Print only the relevant suggestions with install instructions:
```
Based on your project setup, these MCP plugins could be useful:

  • Postgres MCP — Query your database directly from Claude
    Install: claude mcp add postgres-db -- npx @modelcontextprotocol/server-postgres $DATABASE_URL

  • GitHub MCP — Manage PRs and issues from Claude
    Install: claude mcp add github -- npx @modelcontextprotocol/server-github
    (Requires: GITHUB_PERSONAL_ACCESS_TOKEN env var)

Install any of these now? Or run them later with the commands above.
```

---

## Step 8 — Post-Setup Trim (Saves ~3k tokens/session)

Setup is complete. Now trim setup-only content from always-loaded files and archive setup docs.
This saves ~3k tokens per session (~5% of the always-loaded context budget).

**Tell the user:**
```
Setup complete! Now I'll trim setup-only content from always-loaded files.
This saves ~2k tokens per session — content that was only needed during setup.

Trimming...
```

**Then perform ALL of the following trims automatically (no user prompt needed):**

---

### Trim 1: CLAUDE.md — Remove setup-check section (~300 tokens)

Remove the entire "FIRST: Check for First-Time Setup" section (from `## FIRST:` through the
`---` separator before `## Read at Start of EVERY Session`). This block checks for `configured: false`
which is now `true` — it will never trigger again.

**Remove this block from CLAUDE.md:**
```
## FIRST: Check for First-Time Setup

Read `PROJECT.md`. If it contains `configured: false`, this project has not been set up yet.

**Immediately say** (do not do anything else first):

...entire welcome message block...

Then **wait** for the user to run `/setup-project` before doing anything else.

---
```

---

### Trim 2: ai-workflow.md — Remove setup check from session start (~500 tokens)

In the "At the Start of Every Session" section, remove **Step 1** (the unconfigured project check).
Keep Steps 2 and 3 (reading brain.md and checking active features — those are always relevant).
Renumber Step 2 → Step 1, Step 3 → Step 2.

**Remove this block from ai-workflow.md:**
```
**Step 1: Check for unconfigured project**
Read `PROJECT.md`. If `APP_NAME` is still `YOUR_APP_NAME` or the project type is the template default
with no customization, say:
...
```

---

### Trim 3: PROJECT.md — Remove setup instructions (~250 tokens)

Remove the instructional comments that explain how to use `/setup-project`. After setup,
these are noise. Keep the actual configuration data.

**Replace the header and comments in PROJECT.md with a clean version:**

Before (remove):
```
> **Instructions:** Run `/setup-project` in Claude Code to fill this in interactively.
> The wizard will ask you questions, suggest sensible defaults, and update all code files automatically.
> Do NOT edit the Ports section manually after running `/setup-project`.

---

## Setup Status
<!-- IMPORTANT: /setup-project sets this to true when done. Claude uses this to detect unconfigured projects. -->
configured: false
```

After (replace with):
```
configured: true
```

Also remove all HTML comments (`<!-- ... -->`) throughout the file — they explain template choices
that are already made.

---

### Trim 4: deployment.md — Remove deployment target menu (~350 tokens)

**NOTE: brain.md is NOT trimmed.** The update protocol and MEMORY.md comparison table stay in
brain.md intentionally — co-locating the instructions with the data ensures Claude follows them
consistently every session. Both brain.md and ai-workflow.md are always-loaded, so moving content
between them saves zero tokens. Keeping the protocol in brain.md is the safer design.

Remove the "Deployment Target Options" section that lists all 6 possible targets with descriptions
and the "Run `/setup-project` to wire the correct scripts" instruction. The target is already
configured in PROJECT.md — the menu is setup-only content.

**Remove this block from deployment.md:**
```
## Deployment Target Options

Configure in `PROJECT.md` → `target:`. Options:

| Target | Setup |
...entire table...

Run `/setup-project` to wire the correct scripts for your chosen target.
```

---

### Trim 6: database.md — Remove pgvector section if rag not enabled (~500 tokens)

**Only if `rag` integration is NOT enabled in PROJECT.md**, remove the entire "pgvector (RAG Integration Only)"
section from database.md. This section is irrelevant if the project doesn't use vector search.

**Remove this block from database.md (only if rag: disabled):**
```
## pgvector (RAG Integration Only)

Only needed when `rag` integration is enabled in `PROJECT.md`.
...entire section including schema example and index...
```

If rag IS enabled, keep this section — it's actively needed.

---

### After all trims, commit:

```bash
git add CLAUDE.md .claude/rules/ai-workflow.md .claude/rules/database.md \
       .claude/rules/deployment.md PROJECT.md
git commit -m "chore: post-setup trim — remove setup-only content from always-loaded files (~2k tokens saved)"
```

**Print summary:**
```
Post-setup trim complete. Removed setup-only content from always-loaded files:

  CLAUDE.md          — removed setup-check section          (~300 tokens)
  ai-workflow.md     — removed unconfigured project check   (~500 tokens)
  PROJECT.md         — removed setup instructions/comments  (~250 tokens)
  deployment.md      — removed deployment target menu       (~350 tokens)
  database.md        — removed pgvector section (if unused) (~500 tokens)
  ──────────────────────────────────────────────────────────
  Total saved: ~1.9-2.4k tokens per session

  brain.md           — NOT trimmed (update protocol stays co-located with data)
```

---

### Archive setup documentation

**SETUP.md** (comprehensive onboarding guide — 14k+ tokens)
- Ask the user:
```
SETUP.md is a comprehensive onboarding guide. Now that setup is complete, would you like to:

  1. Delete it permanently (saves context, recoverable from git history)
  2. Archive it to .claude/archived-docs/ (not loaded in context, but visible if needed)
  3. Keep it in the repo

Choose [1/2/3]: [1 recommended]
```

If user chooses **1 (delete):**
  - Run: `rm SETUP.md && git add -A && git commit -m "chore: remove SETUP.md after project initialization"`

If user chooses **2 (archive):**
  - Run: `mkdir -p .claude/archived-docs && mv SETUP.md .claude/archived-docs/ && git add -A && git commit -m "chore: archive SETUP.md after project initialization"`

**README.md** (verify it's project-specific, not template)
- If it still shows the template intro ("A development framework for Claude Code"), ask:
```
README.md is still the template README. Would you like to:

  1. Replace it with a project-specific README
  2. Keep the template README
  3. Archive the template and create a new one

Choose [1/2/3]: [1 recommended]
```

If user chooses **1 (replace):**
  ```
  In one sentence, what does this project do? (This will become your README header)
  ```
  Then write `README.md`:
  ```markdown
  # [Project Name]

  [One-line description]

  ## Getting Started

  ```bash
  pnpm install
  pnpm nx serve api      # http://localhost:[api-port]
  pnpm nx serve client   # http://localhost:[client-port]
  ```

  ## Development

  This project uses the [Claude Dev Starter Kit](https://github.com/alonbilu/claude-dev-starter) workflow.
  See `docs/WORKFLOW-GUIDE.md` for the feature development process.
  ```
  Commit: `git add README.md && git commit -m "chore: add project-specific README"`

If user chooses **2 (keep template):** skip, move on.

If user chooses **3 (archive):**
  - Create new README as above, archive old one: `mkdir -p .claude/archived-docs && mv README.md.old .claude/archived-docs/`

---

### Clean up this setup file

```
Setup wizard is complete! Final cleanup...
  → Removing .claude/commands/setup-project.md (won't be needed again)
```

Run:
  - `rm .claude/commands/setup-project.md && git add -A && git commit -m "chore: remove setup-project.md after configuration"`

---

### Done message

```
Your project is ready!

Context savings from post-setup trim:
  • ~3k tokens/session removed from always-loaded files (setup-only content)
  • SETUP.md archived/deleted (~14k tokens)
  • setup-project.md deleted (won't load again)

You now have:
  • Custom status line showing context usage, cache efficiency, branch, session metrics
    (see .claude/STATUSLINE.md for details)
  • Pre-commit hooks with Biome linting
  • Auto-format after every edit + Prisma auto-generate
  • Feature workflow with spec-first planning
  • Specialized subagents (db-expert, test-writer, api-builder, ui-builder)
  • Team-wide patterns and gotchas in .claude/brain.md

Start your first feature:
  /new-feature [feature-name]

Or explore the workflow guide:
  docs/WORKFLOW-GUIDE.md

Check the status line as you work — it helps you stay within context limits.
```
