# Claude Dev Starter Kit

A project template pre-configured with everything needed for Claude Code to work effectively
from session 1 — feature workflow, institutional memory, reuse rules, env setup, and deploy scripts.

---

## Quick Start

**7 steps from clone to first feature:**

- [ ] **1. Clone and rename**
  ```bash
  git clone https://github.com/YOUR_ORG/claude-dev-starter my-project-name
  cd my-project-name
  git remote remove origin
  git remote add origin https://github.com/YOUR_ORG/my-project-name.git
  ```

- [ ] **2. Run the project setup wizard** (do this before anything else)
  ```bash
  # Open Claude Code in this directory, then run:
  /setup-project
  ```
  This will ask you about your project type, infrastructure choices, and ports —
  then configure all files automatically.

- [ ] **3. Set up your environment**
  ```bash
  bash scripts/setup-env.sh --env dev
  ```
  Prompts for each variable, auto-generates secrets, validates output, applies `chmod 600`.

- [ ] **4. Initialize your Nx workspace** (if starting fresh)
  ```bash
  pnpm dlx create-nx-workspace@20 --preset=empty --packageManager=pnpm
  # Then move the generated files into this directory
  ```
  Or copy in your existing Nx workspace files — see `package.json.template.md` for reference.

- [ ] **5. Install dependencies**
  ```bash
  pnpm install
  ```

- [ ] **6. Start infrastructure and verify**
  ```bash
  bash scripts/dev.sh
  # Then in separate terminals:
  pnpm nx serve api
  pnpm nx serve client
  ```

- [ ] **7. Start your first feature**
  ```bash
  /new-feature [your-feature-name]
  ```

---

## What's Included

### Workflow System
- **5-phase feature workflow**: idea → discussion → spec+plan → implementation → completion
- **Dynamic step sizing**: 2–12 steps based on feature complexity
- **CONTEXT.md per feature**: fast session resumption in ~15k tokens
- **brain.md**: project institutional memory (≤200 lines, always loaded)
- **knowledge/**: detailed gotchas and patterns loaded on-demand

### Claude Commands
| Command | Purpose |
|---------|---------|
| `/setup-project` | Interactive wizard — configure for your project |
| `/new-feature [name]` | Start a new feature |
| `/discuss-feature [name]` | Discussion phase |
| `/plan-feature [name]` | Generate spec + dev plan |
| `/start-step [name] N` | Implement step N |
| `/start-step [name] all` | Autopilot remaining steps |
| `/resume-feature [name]` | Resume after a break |
| `/update-status [name]` | Update progress (mandatory each session) |
| `/complete-feature [name]` | Archive and version bump |
| `/create-pr` | Create GitHub PR |
| `/trim-context` | Intelligent context window cleanup |

### Scripts
| Script | Purpose |
|--------|---------|
| `scripts/setup-env.sh` | Dev/staging/production env file wizard |
| `scripts/dev.sh` | Start local dev environment |
| `scripts/start-db.sh` | Start database containers only |
| `scripts/start-ngrok.sh` | Expose API via ngrok (OAuth testing) |
| `scripts/staging-setup.sh` | Bootstrap new staging server |
| `scripts/staging-deploy.sh` | Deploy to staging |
| `scripts/production-deploy.sh` | Deploy to production (with safety gates) |
| `scripts/trim-context.sh` | Audit context window + archive completed features |

### Pre-configured
- **Biome 1.9** — linting + formatting (never ESLint)
- **Husky + lint-staged** — auto-lint on commit
- **biome.json** — battle-tested config with NestJS decorator support
- **Jest** — test configuration ready (never Vitest)
- **VSCode** — Biome as formatter, Jest runner extension recommended

---

## Project Type System

Edit `PROJECT.md` (or run `/setup-project`) to configure:

| Type | What's active |
|------|--------------|
| `saas-web-app` | All layers: frontend + backend + DB + auth + optional integrations |
| `api-only` | Backend API only, no frontend |
| `fullstack-web` | Frontend + backend, no billing layer |
| `cli` | Command-line tool only |
| `library` | Reusable package (types, SDK, utilities) |
| `static-site` | Frontend only, no API |

Optional integrations (off by default, enable in PROJECT.md):
`payments` · `email` · `storage` · `llm` · `rag` · `queue` · `realtime`

---

## The 3 Rules Claude Follows Here

1. **Search before creating** — always checks for existing code before writing new code
2. **Write for reuse** — builds generically, puts shared code in `libs/shared/`
3. **One mission per session** — completes one step fully before moving to the next

---

## Directory Structure

```
claude-dev-starter/
├── SETUP.md                 ← you are here
├── PROJECT.md               ← project type + ports (configure via /setup-project)
├── CLAUDE.md                ← main rules (always loaded by Claude)
├── biome.json               ← linting config
├── docker-compose.yml       ← DB + Redis
├── package.json.template.md ← dependency reference
├── .env.example             ← env file documentation
│
├── .claude/
│   ├── brain.md             ← institutional memory (≤200 lines, always loaded)
│   ├── settings.json        ← Claude Code permissions
│   ├── commands/
│   │   ├── setup-project.md ← /setup-project wizard
│   │   └── trim-context.md  ← /trim-context intelligent cleanup
│   ├── knowledge/
│   │   ├── stack-gotchas.md ← critical pitfalls (loaded on-demand)
│   │   ├── patterns.md      ← reusable code patterns (loaded on-demand)
│   │   └── decisions.md     ← architecture decision log (loaded on-demand)
│   └── rules/
│       ├── ai-workflow.md   ← session protocol, feature workflow
│       ├── architecture.md  ← layers, reuse rules, import boundaries
│       ├── api.md           ← NestJS, Better Auth, validation
│       ├── database.md      ← Prisma, migrations, repositories
│       ├── frontend.md      ← React, TanStack Query, forms
│       ├── testing.md       ← Jest, patterns, requirements
│       ├── code-quality.md  ← Biome, pre-commit, naming
│       └── deployment.md    ← Docker, env files, deploy scripts
│
├── docs/
│   ├── FEATURE-STATUS.md    ← central feature dashboard
│   ├── WORKFLOW-GUIDE.md    ← complete workflow walkthrough
│   ├── ENTITY-CLASSIFICATION.md ← when to create what
│   ├── features/
│   │   ├── active/          ← work in progress
│   │   ├── completed/       ← archived features
│   │   └── backlog/         ← future ideas
│   └── architecture/
│       ├── modules/         ← per-module docs
│       ├── services/        ← per-service docs
│       └── processors/      ← per-processor docs
│
└── scripts/
    ├── setup-env.sh
    ├── dev.sh
    ├── start-db.sh
    ├── start-ngrok.sh
    ├── staging-setup.sh
    ├── staging-deploy.sh
    ├── production-deploy.sh
    └── trim-context.sh
```

---

## Detailed Guides

- **Complete workflow walkthrough:** `docs/WORKFLOW-GUIDE.md`
- **Entity classification:** `docs/ENTITY-CLASSIFICATION.md`
- **Stack gotchas:** `.claude/knowledge/stack-gotchas.md`
- **Reusable patterns:** `.claude/knowledge/patterns.md`
- **Architecture decisions log:** `.claude/knowledge/decisions.md`
