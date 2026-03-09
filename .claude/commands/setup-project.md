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

2. **pnpm 9+**
   ```bash
   pnpm --version
   ```
   If not found: STOP. Tell user:
   ```
   pnpm 9+ is required (npm/yarn won't work).
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

**Q2: Project type**
```
What type of project is this?

  1. saas-web-app    — Full-stack: frontend + backend API + database + auth
  2. api-only        — Backend API only (no frontend)
  3. fullstack-web   — Frontend + backend (no billing/credits layer)
  4. cli             — Command-line tool (no frontend, no database)
  5. library         — Reusable package (types, utils, SDK)
  6. static-site     — Static frontend only

Enter a number or type the name [1]:
```

**Q3: Active layers** (skip layers that don't apply to the chosen type — e.g. cli skips frontend)
```
Which layers are active in this project? (press Enter to accept defaults for your project type)

  [x] frontend   — React/Next/mobile UI
  [x] backend    — NestJS/Express/Fastify API
  [x] database   — Prisma + PostgreSQL
  [x] auth       — Better Auth / NextAuth / Clerk

Type layer names to toggle (space-separated), or press Enter to accept:
```

**Q4: Optional integrations** (only show integrations relevant to the active layers)
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

**Q5: Deployment target**
```
Where will this be deployed?

  1. digital-ocean    — DigitalOcean Droplet or App Platform
  2. vercel           — Vercel (frontend) + separate API
  3. aws              — AWS (EC2, ECS, Lambda)
  4. docker-self-hosted — Self-hosted Docker Compose
  5. cloudflare       — Cloudflare Pages/Workers
  6. none             — Not decided yet

Enter a number or type the name [1]:
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
pgvector/pgvector:pg16 in docker-compose.yml. This is compatible with standard Postgres.

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

## Step 4 — Write PROJECT.md

Write the fully populated `PROJECT.md` with:
- `configured: true`  ← **CRITICAL: always include this line, replacing `configured: false`**
- type: (chosen type)
- active layers with [x] / [ ] checkboxes
- enabled integrations with [x] checkboxes
- target: (chosen deployment)
- Ports section with the configured values

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

## Step 8 — Archive Setup Documentation (Saves Context)

Setup is now complete. These files were helpful for getting started but are no longer needed in active context:

**SETUP.md** (comprehensive onboarding guide — 14k+ tokens)
- Referenced in git history if new team members clone
- Ask the user:
```
SETUP.md is a comprehensive onboarding guide. Now that setup is complete, would you like to:

  1. Delete it permanently (saves context, recoverable from git history)
  2. Archive it to .claude/archived-docs/ (not loaded in context, but visible if needed)
  3. Keep it in the repo (still consumes context every session)

Choose [1/2/3]: [1 recommended]
```

If user chooses **1 (delete):**
  - Run: `rm SETUP.md && git add -A && git commit -m "chore: remove SETUP.md after project initialization"`

If user chooses **2 (archive):**
  - Run: `mkdir -p .claude/archived-docs && mv SETUP.md .claude/archived-docs/ && git add -A && git commit -m "chore: archive SETUP.md after project initialization"`

**README.md** (verify it's project-specific, not template)
- If it still shows the template intro ("A project template that makes Claude Code work..."), ask:
```
README.md is still the template README. Would you like to:

  1. Replace it with a project-specific README
     (One-line description of what THIS project does)
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

**Finally, clean up this setup file itself:**

```
Setup wizard is complete! Cleaning up...
  → Removing .claude/commands/setup-project.md (won't be needed again)
```

Run:
  - `rm .claude/commands/setup-project.md && git add -A && git commit -m "chore: remove setup-project.md after configuration"`

---

When all done:
```
Your project is ready! Context saved by archiving setup docs.

You now have:
  • Custom status line showing context usage, cache efficiency, branch, session metrics
    (see .claude/STATUSLINE.md for details)
  • Pre-commit hooks with Biome linting
  • Feature workflow with spec-first planning
  • Team-wide patterns and gotchas in .claude/brain.md

Start your first feature:
  /new-feature [feature-name]

Or explore the workflow guide:
  docs/WORKFLOW-GUIDE.md

Check the status line as you work — it helps you stay within context limits.
```
