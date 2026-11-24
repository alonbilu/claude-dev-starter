#!/usr/bin/env node
/**
 * setup-quality-gates.js — wire the kit's enforced checks into a generated workspace.
 *
 * Idempotent. Run by scripts/init-workspace.sh; safe to re-run by hand, and the way to add
 * the gates to a project created from an older version of the kit:
 *
 *     node scripts/setup-quality-gates.js
 *
 * What it does:
 *   1. package.json  — adds the `verify`, `verify:all`, `check`, `check:fix`, `format`,
 *                      `format:check` scripts (existing scripts with those names are kept)
 *   2. jest.preset.js — every Jest project inherits the coverage minimums for its layer
 *                      (tools/coverage-thresholds.cjs)
 *   3. Vitest configs — same, via the config's `coverage` block
 *   4. Opt-in CI workflows — copies docs/templates/ci/<name>.yml to .github/workflows/ when
 *                      the matching integration is `[x]` in PROJECT.md, and removes a
 *                      previously-installed copy when it is not:
 *                        e2e        → e2e.yml            (Playwright smoke test)
 *                        ai-review  → claude-review.yml  (independent Claude review on PRs)
 *
 * Exit code is non-zero only when the workspace is missing (no package.json).
 */
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const rel = (p) => path.relative(ROOT, p) || '.';
const log = (msg) => console.log(`  ${msg}`);

// ── 1. package.json scripts ────────────────────────────────────────────────────────────
const SCRIPTS = {
  verify: 'bash scripts/verify.sh',
  'verify:all': 'bash scripts/verify.sh --all',
  check: 'biome check .',
  'check:fix': 'biome check --write .',
  format: 'biome format --write .',
  'format:check': 'biome format .',
};

function patchPackageJson() {
  const file = path.join(ROOT, 'package.json');
  if (!fs.existsSync(file)) {
    console.error('setup-quality-gates: no package.json — run scripts/init-workspace.sh first.');
    process.exit(1);
  }
  const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
  pkg.scripts = pkg.scripts ?? {};
  const added = [];
  for (const [name, command] of Object.entries(SCRIPTS)) {
    if (pkg.scripts[name] === undefined) {
      pkg.scripts[name] = command;
      added.push(name);
    } else if (pkg.scripts[name] !== command) {
      log(`package.json: kept existing "${name}" script (${pkg.scripts[name]})`);
    }
  }
  if (added.length) {
    fs.writeFileSync(file, `${JSON.stringify(pkg, null, 2)}\n`);
    log(`package.json: added scripts ${added.join(', ')}`);
  } else {
    log('package.json: scripts already present');
  }
}

// ── 2. Jest preset ─────────────────────────────────────────────────────────────────────
const JEST_PRESET = `const nxPreset = require('@nx/jest/preset').default;
const { jestCoverage } = require('./tools/coverage-thresholds.cjs');

// Coverage minimums per layer come from tools/coverage-thresholds.cjs and are enforced
// whenever Jest runs with --coverage (\`pnpm verify\` and CI always do).
// Nx runs Jest with the project directory as cwd, which is how the layer is resolved.
module.exports = { ...nxPreset, ...jestCoverage(process.cwd()) };
`;

function patchJestPreset() {
  const file = path.join(ROOT, 'jest.preset.js');
  if (!fs.existsSync(file)) {
    log('jest.preset.js: not present (no Jest projects) — skipped');
    return;
  }
  const current = fs.readFileSync(file, 'utf8');
  if (current.includes('coverage-thresholds')) {
    log('jest.preset.js: coverage minimums already wired');
    return;
  }
  const stock =
    current.replace(/\s+/g, '') ===
    "constnxPreset=require('@nx/jest/preset').default;module.exports={...nxPreset};";
  if (!stock) {
    log('! jest.preset.js has been customised — NOT overwritten. Add this by hand:');
    log("    const { jestCoverage } = require('./tools/coverage-thresholds.cjs');");
    log('    module.exports = { ...yourPreset, ...jestCoverage(process.cwd()) };');
    return;
  }
  fs.writeFileSync(file, JEST_PRESET);
  log('jest.preset.js: coverage minimums wired');
}

// ── 3. Vitest configs ──────────────────────────────────────────────────────────────────
function findConfigs(dir, found = []) {
  if (!fs.existsSync(dir)) return found;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === 'node_modules' || entry.name === 'dist' || entry.name.startsWith('.'))
      continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) findConfigs(full, found);
    else if (/^(vite|vitest)\.config\.(m?ts|m?js|cts|cjs)$/.test(entry.name)) found.push(full);
  }
  return found;
}

function patchVitestConfigs() {
  const configs = [
    ...findConfigs(path.join(ROOT, 'apps')),
    ...findConfigs(path.join(ROOT, 'libs')),
  ];
  for (const file of configs) {
    let source = fs.readFileSync(file, 'utf8');
    if (source.includes('vitestCoverage')) {
      log(`${rel(file)}: coverage minimums already wired`);
      continue;
    }
    const coverageBlock = /(\bcoverage\s*:\s*\{)/;
    if (!coverageBlock.test(source)) continue; // not a test config
    const helper = path
      .relative(path.dirname(file), path.join(ROOT, 'tools', 'coverage-thresholds.cjs'))
      .split(path.sep)
      .join('/');
    const esm = /\.(mts|mjs)$/.test(file) || /import\.meta/.test(source);
    const here = esm ? 'import.meta.dirname' : '__dirname';
    const header = esm
      ? `import { createRequire } from 'node:module';\n\n// Coverage minimums per layer — see tools/coverage-thresholds.cjs\nconst { vitestCoverage } = createRequire(import.meta.url)('${helper}');\n`
      : `// Coverage minimums per layer — see tools/coverage-thresholds.cjs\nconst { vitestCoverage } = require('${helper}');\n`;
    // Insert after the last top-level import line.
    const lines = source.split('\n');
    let lastImport = -1;
    lines.forEach((line, index) => {
      if (/^import\s/.test(line) || /^\/\/\/\s*<reference/.test(line)) lastImport = index;
    });
    lines.splice(lastImport + 1, 0, header);
    source = lines.join('\n').replace(coverageBlock, `$1\n      ...vitestCoverage(${here}),`);
    fs.writeFileSync(file, source);
    log(`${rel(file)}: coverage minimums wired`);
  }
}

// ── 4. Opt-in CI workflows ─────────────────────────────────────────────────────────────
const OPT_IN_WORKFLOWS = [
  { integration: 'e2e', file: 'e2e.yml' },
  { integration: 'ai-review', file: 'claude-review.yml' },
];
const INSTALLED_MARKER = '# Installed by scripts/setup-quality-gates.js';

function integrationEnabled(name) {
  const project = path.join(ROOT, 'PROJECT.md');
  if (!fs.existsSync(project)) return false;
  return new RegExp(`^- \\[x\\] ${name}(\\s|$)`, 'm').test(fs.readFileSync(project, 'utf8'));
}

function syncWorkflows() {
  for (const { integration, file } of OPT_IN_WORKFLOWS) {
    const template = path.join(ROOT, 'docs', 'templates', 'ci', file);
    const target = path.join(ROOT, '.github', 'workflows', file);
    if (!fs.existsSync(template)) continue; // template not shipped in this kit version
    if (integrationEnabled(integration)) {
      const content = `${INSTALLED_MARKER} from docs/templates/ci/${file} (\`${integration}\` is enabled in PROJECT.md).\n${fs.readFileSync(template, 'utf8')}`;
      if (fs.existsSync(target) && fs.readFileSync(target, 'utf8') === content) {
        log(`.github/workflows/${file}: up to date`);
      } else if (
        fs.existsSync(target) &&
        !fs.readFileSync(target, 'utf8').startsWith(INSTALLED_MARKER)
      ) {
        log(`! .github/workflows/${file} exists and was not installed by this script — left alone`);
      } else {
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content);
        log(`.github/workflows/${file}: installed (${integration} enabled)`);
      }
    } else if (
      fs.existsSync(target) &&
      fs.readFileSync(target, 'utf8').startsWith(INSTALLED_MARKER)
    ) {
      fs.rmSync(target);
      log(`.github/workflows/${file}: removed (${integration} not enabled)`);
    } else {
      log(`.github/workflows/${file}: not installed (${integration} not enabled)`);
    }
  }
}

console.log('setup-quality-gates:');
patchPackageJson();
patchJestPreset();
patchVitestConfigs();
syncWorkflows();
