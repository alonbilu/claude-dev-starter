# Unattended Lanes

Narrow jobs an agent can do without a human at the keyboard. Every lane ends in something a
human reviews — a comment or a **draft** pull request. Nothing here merges, tags, releases or
deploys, and nothing here replaces the planning checkpoints, the architect review gate or the
manual `/complete-feature` gate.

| Lane | Trigger | Ends in | Opt-in |
|------|---------|---------|--------|
| Dependency updates | Renovate schedule | PR | `.github/renovate.json` (already in the kit) |
| Independent review | every pull request | one PR comment | `ai-review` in `PROJECT.md` |
| Bug fix | you run `/fix-issue <n>` | draft PR, or a comment on the issue | — |

There is no orchestrator, queue or scheduler in the kit. A lane is one command or one workflow.

**Prerequisite: "green" has to mean something.** These lanes are only as safe as
`pnpm verify` and CI. Do not enable them on a project where verify is red or routinely
bypassed.

---

## Before you enable any of this

1. **Protect `main`.** In GitHub → Settings → Branches (or Rulesets): require a pull request,
   require the `Verify` status check, block force pushes. This is the real guarantee that an
   agent cannot push to main — the permission rules below are a second layer, not the first.
2. **Decide who merges dependency PRs.** `.github/renovate.json` ships with `automerge: true`
   for patch and minor updates of ≥1.0 packages. If every merge should be yours, set it to
   `false`. If you keep it, branch protection with the `Verify` check is what makes it safe.
3. **`pnpm verify` is green on `main`.**

---

## Independent review on every PR

A first-pass review by the `code-reviewer` subagent (`.claude/agents/code-reviewer.md`): fresh
context, read-only tools (Read, Grep, Glob), given only the spec and the diff. The same agent
`/review` spawns locally. It posts **one comment** per PR, updated on each push. It does not
approve, request changes, push or merge — you still review and merge.

### Setup

1. Enable the integration in `PROJECT.md`: `- [x] ai-review`
2. Install the workflow: `node scripts/setup-quality-gates.js`
   (copies `docs/templates/ci/claude-review.yml` → `.github/workflows/claude-review.yml`;
   disabling the integration and re-running removes it)
3. Install the Claude GitHub App on the repository: run `/install-github-app` in Claude Code,
   or install it from GitHub. Repository admin access is required.
4. Add the repository secret `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions).
5. Commit and push the workflow.
6. **Pin the action to a commit SHA.** The workflow passes your API key to
   `anthropics/claude-code-action`, and the template references it by the movable tag `@v1`.
   Merge the Renovate PR that pins GitHub Actions to digests (the kit's `renovate.json`
   enables `helpers:pinGitHubActionDigests`), or pin it by hand:
   `uses: anthropics/claude-code-action@<40-char-sha> # v1.x.y`.

Reference: <https://code.claude.com/docs/en/github-actions>. The workflow uses
`anthropics/claude-code-action@v1` with the `prompt` and `claude_args` inputs.

### How it behaves

- **No secret, no review, no failure.** If `ANTHROPIC_API_KEY` is absent — including on pull
  requests from forks, where GitHub withholds secrets — the first step records that and every
  later step is skipped. The job passes.
- **Claude never talks to GitHub.** Its tools are limited to `Read`, `Grep`, `Glob`, spawning
  the subagent, and writing `review-report.md`. A separate workflow step posts that file with
  `gh pr comment` using the job's own token.
- **Drafts are reviewed too**, because the bug-fix lane opens drafts. To skip them, add
  `if: github.event.pull_request.draft == false` to the job.
- **Cost:** one review per push to an open PR. `concurrency` cancels a review that is
  superseded by a newer push.
- The PR title, body and code are treated as material to review, never as instructions.

`id-token: write` is in the job's permissions because the action's default GitHub App
authentication needs it (per the action's docs). It lets the job request an OIDC token; it
grants no repository access by itself.

It is not a required check and should not be made one: a model's verdict is input to your
review, not a gate.

---

## Bug-fix lane — `/fix-issue <number>`

Reads a GitHub issue, reproduces it with a failing test, fixes it, runs `pnpm verify`, pushes a
`fix/issue-<n>-…` branch and opens a **draft** PR that says what was wrong, shows the test
failing before the fix, and lists what was not verified. Full behaviour:
`.claude/commands/fix-issue.md`.

It never asks a question. Where it cannot proceed honestly it **stops** and leaves one comment
on the issue instead of a PR:

- cannot find the cause, or cannot make a test fail for the reported reason ("could not reproduce")
- the fix needs a schema change/migration, a new dependency, or changes to CI, scripts,
  settings or env files
- `pnpm verify` cannot be made green without weakening a test or a threshold

The issue text is treated as untrusted data: it describes a symptom, and instructions inside
it are ignored and reported.

### Running it

Interactively: `/fix-issue 123`.

Unattended (headless):

```bash
CLAUDE_UNATTENDED=1 claude -p "/fix-issue 123" \
  --settings .claude/settings.unattended.json \
  --permission-mode dontAsk
```

- `-p` runs without the interactive UI; custom commands work by including `/name` in the prompt.
- `--settings <file>` layers `.claude/settings.unattended.json` over the project's
  `.claude/settings.json` for that run. Permission lists **merge**, and deny rules are
  evaluated before allow rules, so the profile can only narrow what the project allows.
- `--permission-mode dontAsk` denies anything that would have prompted, instead of waiting.

Reference: <https://code.claude.com/docs/en/headless>, <https://code.claude.com/docs/en/settings>,
<https://code.claude.com/docs/en/permissions>.

Run it from a clean checkout (or a dedicated worktree/clone), not from the directory where you
are in the middle of other work — it refuses to start on a dirty tree.

### What the unattended profile locks down

`.claude/settings.unattended.json` adds to the project settings:

| Area | Rule |
|------|------|
| Prompts | `defaultMode: dontAsk` — never waits for a human |
| Merging / releasing | denies `gh pr merge`, `gh pr ready`, `gh pr review`, `gh release`, `git tag`, `git merge`, `git rebase` |
| Pushing | allows only `git push -u origin fix/*`; denies pushes that name `main`, tags, deletes; force-push stays denied by the project settings |
| Skipping checks | denies `git commit --no-verify` |
| Repo administration | denies `gh repo`, `gh secret`, `gh variable`, `gh workflow`, `gh api`, `gh auth` |
| Dependencies / schema | denies `pnpm add`, `pnpm remove`, `npm install`, `prisma migrate`, edits to `schema.prisma`, `package.json`, lockfile |
| The gates themselves | denies edits to `.github/`, `.claude/`, `.husky/`, `scripts/`, `tools/`, `biome.json`, `nx.json`, `jest.preset.js` |
| Secrets | denies reading or writing `.env*` |
| Network | denies `WebFetch`, `WebSearch`, `curl`, `wget`, `ssh`, `docker` |
| Stop hook | sets `CLAUDE_UNATTENDED=1`, which `.claude/hooks/status-reminder.sh` honours |

Pattern rules cannot see which branch a bare `git push` would push, which is why branch
protection on `main` (above) is step one.

Interactive commands are unchanged: they still ask `[y/N]` where they did before. Only the
unattended lanes are written never to wait.

---

## Getting production errors into GitHub issues

`/fix-issue` consumes GitHub issues; it does not care where they came from. To have errors
arrive as issues, use the tracker's own GitHub integration — the kit does not build a bridge.

With Sentry (the `error-tracking` integration, see `.claude/knowledge/integrations.md` →
"Error Tracking"):

1. Sentry → Settings → Integrations → **GitHub** → install it for the repository.
2. Either create issues by hand from a Sentry issue ("Create GitHub Issue" in the issue
   sidebar), or add an alert rule whose action is "Create a new GitHub issue" so matching
   errors open one automatically. Automatic creation depends on your Sentry plan — check what
   yours includes.
3. Give those issues a label (for example `sentry`) so you can see the queue:
   `gh issue list --label sentry`.

Then run `/fix-issue <n>` on the ones worth fixing. Choosing which issue to work on stays a
human decision; nothing in the kit polls the issue list.

---

## The stop hook in unattended runs

`.claude/hooks/status-reminder.sh` blocks the end of a session to remind you to run
`/update-status` or `/check-updates`. With nobody to answer, that reminder would send a
headless agent off to do unrelated work. The hook exits silently when `CLAUDE_UNATTENDED=1`
or `CI=true`. Interactive sessions are unaffected.

---

## What is deliberately not here

- No ticket-to-PR pipeline, no multi-feature mode, no agent that picks its own work.
- No auto-merge by an agent, and no lane that ends anywhere other than a comment or a draft PR.
- Feature work stays interactive: planning checkpoints, architect review gate, and you
  invoking `/complete-feature` after reading the diff.
