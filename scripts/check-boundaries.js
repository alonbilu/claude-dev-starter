#!/usr/bin/env node
/**
 * check-boundaries.js — fail when a project imports from a layer it must not.
 *
 * Enforces the import table in .claude/rules/architecture.md:
 *
 *     apps  →  libs/backend  →  libs/domain  →  libs/shared
 *
 *   - a project may import from layers BELOW it, and from its own layer (except apps → apps)
 *   - never from a layer above it
 *   - no circular dependencies between projects
 *
 * It reads Nx's own project graph, so path aliases (@app/*) and relative imports are resolved
 * exactly the way Nx resolves them. No extra dependency, no lint plugin.
 *
 * Usage:
 *   node scripts/check-boundaries.js                 # ask Nx for the graph
 *   node scripts/check-boundaries.js --graph f.json  # use a saved `nx graph --file` output
 *
 * Run by `pnpm verify`. Exit 0 = clean, 1 = violations, 2 = could not read the graph.
 */
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');

// Higher number = higher layer. A project may only import from a rank <= its own.
const LAYERS = [
  { prefix: 'apps/', name: 'apps', rank: 3 },
  { prefix: 'libs/backend/', name: 'libs/backend', rank: 2 },
  { prefix: 'libs/domain/', name: 'libs/domain', rank: 1 },
  { prefix: 'libs/shared/', name: 'libs/shared', rank: 0 },
];

function layerOf(projectRoot) {
  const rel = `${projectRoot.split(path.sep).join('/')}/`;
  return LAYERS.find((layer) => rel.startsWith(layer.prefix));
}

function loadGraph() {
  const flag = process.argv.indexOf('--graph');
  let file = flag !== -1 ? process.argv[flag + 1] : null;
  let temp = null;
  if (!file) {
    temp = fs.mkdtempSync(path.join(os.tmpdir(), 'nx-graph-'));
    file = path.join(temp, 'graph.json');
    const nx = path.join(
      ROOT,
      'node_modules',
      '.bin',
      process.platform === 'win32' ? 'nx.cmd' : 'nx'
    );
    if (!fs.existsSync(nx)) {
      console.error('check-boundaries: nx is not installed (run `pnpm install`).');
      process.exit(2);
    }
    try {
      execFileSync(nx, ['graph', `--file=${file}`], {
        cwd: ROOT,
        stdio: ['ignore', 'ignore', 'inherit'],
      });
    } catch {
      console.error('check-boundaries: `nx graph` failed — see the output above.');
      process.exit(2);
    }
  }
  try {
    const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
    return parsed.graph ?? parsed;
  } catch (error) {
    console.error(`check-boundaries: cannot read project graph from ${file}: ${error.message}`);
    process.exit(2);
  } finally {
    if (temp) fs.rmSync(temp, { recursive: true, force: true });
  }
}

/** Import aliases (from tsconfig.base.json `paths`) that point into a project root. */
function aliasesFor(projectRoot) {
  try {
    const raw = fs.readFileSync(path.join(ROOT, 'tsconfig.base.json'), 'utf8');
    const paths = JSON.parse(raw).compilerOptions?.paths ?? {};
    return Object.entries(paths)
      .filter(([, targets]) =>
        targets.some((t) => path.normalize(t).startsWith(path.normalize(projectRoot) + path.sep))
      )
      .map(([alias]) => alias.replace(/\/\*$/, ''));
  } catch {
    return [];
  }
}

/** Best-effort: the files in `fromRoot` whose import specifiers point at `toRoot`. */
function findImportSites(fromRoot, toRoot) {
  const aliases = aliasesFor(toRoot);
  const sites = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.name === 'node_modules' || entry.name === 'dist' || entry.name.startsWith('.'))
        continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (/\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$/.test(entry.name)) {
        const lines = fs.readFileSync(full, 'utf8').split('\n');
        lines.forEach((line, index) => {
          const match = line.match(
            /(?:from\s+|import\s*\(\s*|require\s*\(\s*|^\s*import\s+)['"]([^'"]+)['"]/
          );
          if (!match) return;
          const spec = match[1];
          const viaAlias = aliases.some((alias) => spec === alias || spec.startsWith(`${alias}/`));
          const viaPath =
            spec.startsWith('.') &&
            `${path
              .relative(ROOT, path.resolve(path.dirname(full), spec))
              .split(path.sep)
              .join('/')}/`.startsWith(`${toRoot.split(path.sep).join('/')}/`);
          if (viaAlias || viaPath)
            sites.push(`${path.relative(ROOT, full)}:${index + 1}  ${line.trim()}`);
        });
      }
    }
  };
  try {
    walk(path.join(ROOT, fromRoot));
  } catch {
    // Locations are a convenience; the violation itself comes from the Nx graph.
  }
  return sites;
}

function findCycles(nodes, edges) {
  const cycles = [];
  const state = new Map(); // undefined = unvisited, 1 = on stack, 2 = done
  const stack = [];
  const visit = (node) => {
    state.set(node, 1);
    stack.push(node);
    for (const next of edges.get(node) ?? []) {
      if (state.get(next) === 1) {
        cycles.push([...stack.slice(stack.indexOf(next)), next]);
      } else if (!state.get(next)) {
        visit(next);
      }
    }
    stack.pop();
    state.set(node, 2);
  };
  for (const node of nodes) if (!state.get(node)) visit(node);
  return cycles;
}

const graph = loadGraph();
const roots = new Map(Object.entries(graph.nodes).map(([name, node]) => [name, node.data.root]));
const violations = [];
const codeEdges = new Map();

for (const [source, deps] of Object.entries(graph.dependencies)) {
  const sourceRoot = roots.get(source);
  if (!sourceRoot) continue; // npm: packages
  for (const dep of deps) {
    // "implicit" edges are declared in project.json (e.g. an e2e project depending on the app
    // it tests) — they are not imports.
    if (dep.type === 'implicit') continue;
    const targetRoot = roots.get(dep.target);
    if (!targetRoot) continue;
    if (!codeEdges.has(source)) codeEdges.set(source, []);
    codeEdges.get(source).push(dep.target);

    const from = layerOf(sourceRoot);
    const to = layerOf(targetRoot);
    if (!from || !to) continue; // outside apps/ and libs/{backend,domain,shared} — not governed
    const upward = to.rank > from.rank;
    const appToApp = from.name === 'apps' && to.name === 'apps';
    if (upward || appToApp) {
      violations.push({
        source,
        sourceRoot,
        target: dep.target,
        targetRoot,
        from: from.name,
        to: to.name,
      });
    }
  }
}

const cycles = findCycles([...roots.keys()], codeEdges);

if (violations.length === 0 && cycles.length === 0) {
  console.log(`check-boundaries: OK (${roots.size} projects, no forbidden imports, no cycles)`);
  process.exit(0);
}

for (const v of violations) {
  console.error(`\n✗ ${v.sourceRoot} (${v.from}) must not import from ${v.targetRoot} (${v.to})`);
  const sites = findImportSites(v.sourceRoot, v.targetRoot);
  for (const site of sites) console.error(`    ${site}`);
  if (sites.length === 0)
    console.error(
      `    (Nx reports ${v.source} → ${v.target}; search ${v.sourceRoot} for the import)`
    );
}
for (const cycle of cycles) {
  console.error(`\n✗ circular dependency: ${cycle.join(' → ')}`);
}
console.error(
  `\ncheck-boundaries: ${violations.length} forbidden import(s), ${cycles.length} cycle(s).` +
    '\nAllowed direction: apps → libs/backend → libs/domain → libs/shared (see .claude/rules/architecture.md).' +
    '\nFix by moving the shared code DOWN a layer, not by importing up.'
);
process.exit(1);
