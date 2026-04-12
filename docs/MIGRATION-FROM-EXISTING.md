# Migrating an Existing Project to Claude Dev Starter Kit

You have an existing project and want to adopt this workflow. Here's how to do it incrementally without disrupting your current work.

---

## Quick Decision: All-at-Once vs Incremental?

| Approach | When | Effort | Risk |
|----------|------|--------|------|
| **All-at-once** | New project, small team, starting fresh | 4–6 hours | Low (no existing conflict) |
| **Incremental** | Existing project, active features, risk-averse | 2–3 hours per phase | Very low (can roll back) |

**Recommendation:** Start with incremental. You can always commit everything at once later.

---

## Phase 1: Setup (0.5 hours) — Do This First

Copy the essential files and directories from the template:

```bash
# Clone the template into a temporary location
git clone https://github.com/alonbilu/claude-dev-starter.git /tmp/starter-kit

# Copy required files to your project
cp -r /tmp/starter-kit/.claude/ your-project/.claude/
cp -r /tmp/starter-kit/docs/ your-project/docs/
cp /tmp/starter-kit/CLAUDE.md your-project/
cp /tmp/starter-kit/PROJECT.md your-project/
cp -r /tmp/starter-kit/scripts/ your-project/scripts/

# Update your .gitignore to include template patterns
cat >> your-project/.gitignore << 'EOF'
# Claude Dev Starter Kit
.claude/archived-docs/
.claude/memory/
.claude/.last-update-check
.claude/settings.local.json
.claude/plans/
docs/features/archive/
docs/services/archive/
docs/modules/archive/

# TypeScript incremental build cache (machine-local)
*.tsbuildinfo
EOF

# Commit Phase 1
git add .claude/ docs/ CLAUDE.md PROJECT.md scripts/
git commit -m "chore: initialize Claude Dev Starter Kit structure"
```

---

## Phase 2: Customize Project Configuration (0.5 hours)

Edit `PROJECT.md` to describe your project:

```markdown
configured: true

type: [saas-web-app / api-only / fullstack-web / cli / library / static-site / worker]

Active Layers:
- [x] frontend
- [x] backend
- [x] database
- [x] auth

Optional Integrations:
- [ ] payments
- [ ] email
- [ ] storage
- etc

Deployment Target:
target: [your-target]

Ports:
api: [YOUR_API_PORT]
client: [YOUR_CLIENT_PORT]
```

**Customize for your stack:**
- Update `CLAUDE.md` Stack Overview section with your actual ports
- Update `.claude/rules/` files to match your stack (replace NestJS with Express, Prisma with Drizzle, etc.)

```bash
git commit -m "chore: customize Claude Dev Starter Kit for this project"
```

---

## Phase 3: Adopt One Command (1 hour)

Pick ONE workflow command to start using. Recommended order:

### Option A: Start with `/new-feature` (Recommended for most projects)

1. **Understand the workflow:**
   - Read `docs/WORKFLOW-GUIDE.md` (if it exists, or examine `.claude/commands/new-feature.md`)
   - Read `.claude/rules/ai-workflow.md` for the full feature lifecycle

2. **Use on your next small feature:**
   - Run `/new-feature [feature-name]`
   - Complete `/discuss-feature`
   - Run `/generate-spec`
   - Try `/plan-execution` to auto-generate dev plan
   - Implement using `/start-coding`

3. **Evaluate:**
   - Does the workflow help?
   - What did you like/dislike?
   - Which parts are useful vs overhead?

### Option B: Start with `/trim-context` (If context is an issue)

1. Understand context bloat: `.claude/rules/ai-workflow.md`
2. Run `/trim-context` to audit your `.claude/` directory
3. See what can be archived/removed
4. Adopt selectively from Phase 5

### Option C: Start with `/update-status` (If tracking progress is your pain point)

1. Adopt the STATUS.md template (copy `docs/templates/feature/STATUS.md`)
2. Start using it for your current work
3. Let it guide improvements to other commands

```bash
# After using one command successfully:
git add docs/features/active/
git commit -m "feat: start using [feature-name] with new workflow"
```

---

## Phase 4: Consolidate Brain & Knowledge (1 hour)

Migrate your existing project context into Claude's memory system:

### Add to `.claude/brain.md`:
- Top 5 gotchas specific to YOUR project
- Current feature status (what you're working on)
- Key architectural decisions
- Latest patterns you've discovered

**Example:**
```markdown
## Project-Specific Insights

- **Custom auth flow** — We use NextAuth with Keycloak, not Better Auth. See auth rules in `.claude/rules/custom-auth.md`
- **No Prisma migrations** — We manage schema via Drizzle. See database setup in `setup-db.md`
- **GraphQL API** — We're transitioning from REST to GraphQL. See schema in `lib/graphql/schema.ts`
```

### Create custom rule files:
If your stack differs from the template, add custom rules:

```bash
# Example: you use Fastify not NestJS
cat > .claude/rules/api-custom.md << 'EOF'
# Custom API Rules (Fastify)

This project uses Fastify instead of NestJS.

## Decorators are NOT used

We don't have @Controller or @Get decorators. Instead:

\`\`\`typescript
// libs/domain/users/src/lib/routes.ts
app.get('/api/v1/users/:id', async (req, reply) => {
  const user = await userService.findById(req.params.id);
  reply.send(user);
});
\`\`\`

[rest of custom rules...]
EOF
```

```bash
git add .claude/brain.md .claude/rules/
git commit -m "chore: migrate project context to Claude memory system"
```

---

## Phase 5: Adopt Full Workflow (Ongoing)

Once Phase 1–4 are solid, gradually adopt more commands:

**Week 1:**
- Adopt `/new-feature` + `/discuss-feature` for all new work
- Commit after each feature planning phase

**Week 2:**
- Add `/start-coding` for atomic implementation (forces better commits)
- Start using `/update-status` religiously after each session

**Week 3:**
- Use `/complete-feature` when features ship
- Use `/release-milestone` for version bumps

**Week 4+:**
- Lean on `/resume-feature` for long-running work
- Use `/trim-context` monthly to keep context lean

---

## What You DON'T Need (At First)

These are nice-to-haves, not blockers:

- ❌ `/new-service` — only if you have dedicated background services
- ❌ `/new-module` / `/new-submodule` — only if you have explicit domain modules
- ❌ `/hotfix` — only if you have hotfix branches
- ❌ `/release-milestone` — only if you do semantic versioning
- ❌ `/scaffold` — useful but not required (you can write boilerplate manually)

**Start with:** `/new-feature` for planned work, `/quick` for small fixes, `/debug` for errors.

---

## Rollback Strategy

If something isn't working:

```bash
# Remove all template files and start over
git rm -r .claude/ docs/ CLAUDE.md PROJECT.md scripts/
git commit -m "chore: remove Claude Dev Starter Kit (rollback)"

# No harm done — your code is untouched
```

---

## Integration Checklist

- [ ] Phase 1: Copied `.claude/`, `docs/`, rules files
- [ ] Phase 2: Customized `PROJECT.md` for your project
- [ ] Phase 3: Tried one workflow command
- [ ] Phase 4: Added project-specific context to brain.md
- [ ] Phase 5: Adopted full workflow incrementally

---

## Common Integration Issues

### Issue: "My project structure doesn't match the template"

**Solution:** The template is a starting point. Adapt the rules to your structure.
- Update import rules in `architecture.md`
- Document your actual structure in `.claude/brain.md`
- Create custom rule files (e.g., `.claude/rules/api-custom.md`)

### Issue: "I don't have NestJS / Prisma / React"

**Solution:** Swap them out. The workflow itself (feature → discuss → spec → plan → implement) is stack-agnostic.
- Replace NestJS rules with Express / Fastify / Go
- Replace Prisma with Drizzle / TypeORM / Knex
- Replace React with Vue / Svelte / plain JS
- Update `.claude/rules/` files accordingly

### Issue: "The workflow is too heavyweight for small changes"

**Solution:** Don't use it for everything. Use for features, skip for bugfixes.
- Features use full workflow (`/new-feature` → `/plan-feature` → `/start-coding`)
- Bugfixes use simple commits (no workflow)
- Hotfixes use `/hotfix` command if needed

### Issue: "How do I handle existing features / in-progress work?"

**Solution:** Create backdated entries for existing work:
- Create `docs/features/archive/F[XXX]-[old-feature]/`
- Write a brief `3-spec.md` describing what was built
- Mark as "Completed" in brain.md
- Continue with `/new-feature` for all future work

---

## Success Metrics

You'll know the adoption is working when:

✅ New features have clear specs before implementation
✅ Context window stays <70k tokens across sessions
✅ You can pause and resume work without losing context
✅ Commits include feature ID (`F[XXX]`) and step number
✅ Team/future you can understand why decisions were made
✅ Onboarding new teammates gets faster

---

## Need Help?

- Read `CLAUDE.md` — the main instructions
- Check `.claude/brain.md` — what you've learned
- Refer to `.claude/rules/` — detailed rules for each layer
- Check `/view-features` — see all feature status
