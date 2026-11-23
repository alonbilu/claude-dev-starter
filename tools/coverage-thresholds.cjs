/**
 * Coverage minimums — the single place they are defined.
 *
 * Mirrors the table in .claude/rules/testing.md. `jest.preset.js` (backend + libs) and the
 * Vitest configs (frontend) both read from here, so changing a number in this file changes
 * what `pnpm verify` and CI enforce. Change the table in testing.md in the same commit.
 *
 * The percentage applies to LINES and STATEMENTS. Branch and function coverage are reported
 * but not gated.
 *
 * First match wins, so list specific paths before general ones.
 * `only` restricts the gate (and the files counted) to that sub-folder of the project.
 */
const fs = require('node:fs');
const path = require('node:path');

const LAYERS = [
  // testing.md: "libs/domain/database/repositories/ — 80%"
  { root: 'libs/domain/database', percent: 80, only: 'src/lib/repositories' },
  // testing.md: "libs/domain/* services — 70%"
  { root: 'libs/domain/', percent: 70 },
  // testing.md: "libs/shared/utils/ — 80%"
  { root: 'libs/shared/utils', percent: 80 },
  // testing.md: "libs/backend/* — 60%"
  { root: 'libs/backend/', percent: 60 },
  // Not gated (testing.md: controllers and presentational components are "not required"):
  // apps/*, libs/shared/types, libs/shared/config, libs/shared/ui.
];

const WORKSPACE_ROOT = path.resolve(__dirname, '..');

/** The layer rule for a project directory, or undefined when the layer is not gated. */
function layerFor(projectDir) {
  const rel = `${path.relative(WORKSPACE_ROOT, path.resolve(projectDir)).split(path.sep).join('/')}/`;
  return LAYERS.find((layer) =>
    rel.startsWith(layer.root.endsWith('/') ? layer.root : `${layer.root}/`)
  );
}

const NOT_SOURCE = [
  '!src/**/*.spec.{ts,tsx}',
  '!src/**/*.test.{ts,tsx}',
  '!src/**/*.d.ts',
  '!src/**/index.ts',
];

/**
 * Jest options for a project. Spread into the shared preset.
 * `collectCoverageFrom` matters as much as the threshold: without it Jest only counts files a
 * test happened to import, so a service with no test at all would not lower coverage.
 */
function jestCoverage(projectDir) {
  const layer = layerFor(projectDir);
  if (!layer) return {};
  const scope = layer.only ?? 'src';
  // A sub-folder gate only applies once the folder exists (Jest errors on a threshold path
  // that matches no files).
  if (layer.only && !fs.existsSync(path.join(projectDir, layer.only))) return {};
  return {
    collectCoverageFrom: [`${scope}/**/*.{ts,tsx}`, ...NOT_SOURCE],
    coverageThreshold: { global: { lines: layer.percent, statements: layer.percent } },
  };
}

/** Vitest `test.coverage` options for a project. Spread into the config's coverage block. */
function vitestCoverage(projectDir) {
  const layer = layerFor(projectDir);
  if (!layer) return {};
  const scope = layer.only ?? 'src';
  if (layer.only && !fs.existsSync(path.join(projectDir, layer.only))) return {};
  return {
    include: [`${scope}/**/*.{ts,tsx}`],
    exclude: [
      'src/**/*.spec.{ts,tsx}',
      'src/**/*.test.{ts,tsx}',
      'src/**/*.d.ts',
      'src/**/index.ts',
    ],
    thresholds: { lines: layer.percent, statements: layer.percent },
  };
}

module.exports = { LAYERS, layerFor, jestCoverage, vitestCoverage };
