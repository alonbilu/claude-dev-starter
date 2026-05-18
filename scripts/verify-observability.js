#!/usr/bin/env node
//
// verify-observability.js — Send a real test event to whichever observability
// provider(s) you've configured in .env. Catches credential / network /
// region-binding issues BEFORE production traffic surfaces them.
//
// Zero dependencies. Auto-detects providers from .env keys:
//
//   AXIOM_TOKEN + AXIOM_DATASET           → POST a test event to Axiom
//   GRAFANA_LOKI_URL + GRAFANA_CLOUD_API_KEY + GRAFANA_CLOUD_USER → POST to Loki
//   BETTERSTACK_SOURCE_TOKEN              → POST to Better Stack
//   SENTRY_DSN                            → POST a test event to Sentry
//
// Per-provider OK / FAIL with the exact response status + body snippet.
//
// Usage:
//   node scripts/verify-observability.js              # reads .env
//   node scripts/verify-observability.js .env.staging # explicit

'use strict';

const fs = require('node:fs');
const path = require('node:path');

const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const DIM = '\x1b[2m';

const ok = (m) => console.log(`${GREEN}✓${RESET} ${m}`);
const fail = (m, hint) => {
  console.log(`${RED}✗${RESET} ${m}`);
  if (hint) console.log(`  ${DIM}${hint}${RESET}`);
};
const info = (m) => console.log(`${YELLOW}→${RESET} ${m}`);
const dim = (m) => console.log(`  ${DIM}${m}${RESET}`);

function loadEnv(file) {
  if (!fs.existsSync(file)) return {};
  const out = {};
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^#]*))\s*(?:#.*)?$/);
    if (m) out[m[1]] = (m[2] ?? m[3] ?? m[4] ?? '').trim();
  }
  return out;
}

const envFile = process.argv[2] || '.env';
const env = { ...loadEnv(envFile), ...process.env };
const REQ_ID = `verify-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
const HOSTNAME = require('node:os').hostname();

console.log(`\nVerifying observability providers (reading ${envFile})`);
console.log(`Test event ID: ${REQ_ID}\n`);

let failed = 0;
const ran = [];

// ─── Axiom ────────────────────────────────────────────────────────────────
async function checkAxiom() {
  if (!env.AXIOM_TOKEN || !env.AXIOM_DATASET) return;
  ran.push('axiom');
  info(`Axiom: posting test event → dataset "${env.AXIOM_DATASET}"`);
  // Axiom EU vs US: token-binding is region-specific. If EU 403s, try US (see
  // .claude/knowledge/integrations.md → "Axiom EU-region 403 bug").
  const url = `https://api.axiom.co/v1/datasets/${env.AXIOM_DATASET}/ingest`;
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.AXIOM_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([{
        _time: new Date().toISOString(),
        level: 'info',
        message: 'kit verify-observability test event',
        verifyId: REQ_ID,
        host: HOSTNAME,
      }]),
    });
    if (res.status === 200 || res.status === 201) {
      const body = await res.json().catch(() => ({}));
      ok(`Axiom: 200 OK (ingested=${body.ingested ?? '?'})`);
      dim(`query in Axiom UI: ['${REQ_ID}']`);
    } else {
      const body = await res.text();
      fail(`Axiom: ${res.status} ${res.statusText}`, body.slice(0, 300));
      if (res.status === 403) {
        dim('If your workspace is in EU region, try the US region — known token-binding bug.');
        dim('See .claude/knowledge/integrations.md → Logging Gotchas → "Axiom EU-region 403".');
      }
      failed++;
    }
  } catch (e) {
    fail(`Axiom: network error — ${e.message}`);
    failed++;
  }
}

// ─── Grafana Cloud Loki ───────────────────────────────────────────────────
async function checkGrafanaLoki() {
  if (!env.GRAFANA_LOKI_URL || !env.GRAFANA_CLOUD_API_KEY || !env.GRAFANA_CLOUD_USER) return;
  ran.push('grafana-cloud');
  info(`Grafana Cloud (Loki): posting test line → ${env.GRAFANA_LOKI_URL}`);
  const auth = Buffer.from(`${env.GRAFANA_CLOUD_USER}:${env.GRAFANA_CLOUD_API_KEY}`).toString('base64');
  try {
    const res = await fetch(env.GRAFANA_LOKI_URL, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        streams: [{
          stream: { service: 'kit-verify', host: HOSTNAME, verifyId: REQ_ID },
          values: [[`${Date.now() * 1e6}`, `kit verify-observability test (${REQ_ID})`]],
        }],
      }),
    });
    if (res.status === 204 || res.status === 200) {
      ok('Grafana Cloud (Loki): 204 No Content (accepted)');
      dim(`query: {service="kit-verify", verifyId="${REQ_ID}"}`);
    } else {
      fail(`Grafana Cloud (Loki): ${res.status} ${res.statusText}`, (await res.text()).slice(0, 300));
      failed++;
    }
  } catch (e) {
    fail(`Grafana Cloud (Loki): network error — ${e.message}`);
    failed++;
  }
}

// ─── Better Stack ─────────────────────────────────────────────────────────
async function checkBetterStack() {
  if (!env.BETTERSTACK_SOURCE_TOKEN) return;
  ran.push('better-stack');
  info('Better Stack: posting test event');
  try {
    const res = await fetch('https://in.logs.betterstack.com/', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.BETTERSTACK_SOURCE_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        dt: new Date().toISOString(),
        message: 'kit verify-observability test event',
        verifyId: REQ_ID,
        host: HOSTNAME,
        level: 'info',
      }),
    });
    if (res.status === 202 || res.status === 200) {
      ok('Better Stack: 202 Accepted');
      dim(`search in Better Stack UI for verifyId="${REQ_ID}"`);
    } else {
      fail(`Better Stack: ${res.status} ${res.statusText}`, (await res.text()).slice(0, 300));
      failed++;
    }
  } catch (e) {
    fail(`Better Stack: network error — ${e.message}`);
    failed++;
  }
}

// ─── Sentry ───────────────────────────────────────────────────────────────
async function checkSentry() {
  if (!env.SENTRY_DSN) return;
  ran.push('sentry');
  info(`Sentry: posting test event to ${env.SENTRY_DSN}`);
  // Parse the DSN — Sentry's POST URL is derived from it.
  // DSN format: https://<publicKey>@<host>/<projectId>
  let dsn;
  try { dsn = new URL(env.SENTRY_DSN); } catch { fail('SENTRY_DSN is not a valid URL'); failed++; return; }
  const publicKey = dsn.username;
  const projectId = dsn.pathname.replace(/^\//, '');
  const storeUrl = `${dsn.protocol}//${dsn.host}/api/${projectId}/store/`;
  const sentryAuth = `Sentry sentry_version=7, sentry_key=${publicKey}, sentry_client=kit-verify/1`;
  try {
    const res = await fetch(storeUrl, {
      method: 'POST',
      headers: { 'X-Sentry-Auth': sentryAuth, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'kit verify-observability test event',
        level: 'info',
        platform: 'node',
        tags: { verifyId: REQ_ID, host: HOSTNAME, source: 'kit-verify' },
        timestamp: new Date().toISOString(),
      }),
    });
    if (res.status === 200) {
      const body = await res.json().catch(() => ({}));
      ok(`Sentry: 200 OK (event id ${body.id ?? '?'})`);
    } else {
      fail(`Sentry: ${res.status} ${res.statusText}`, (await res.text()).slice(0, 300));
      failed++;
    }
  } catch (e) {
    fail(`Sentry: network error — ${e.message}`);
    failed++;
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────
(async () => {
  await checkAxiom();
  await checkGrafanaLoki();
  await checkBetterStack();
  await checkSentry();
  console.log('');
  if (ran.length === 0) {
    info('No observability providers configured in .env — skipping all checks.');
    info('  (If you enabled the `logging` integration in PROJECT.md, populate the matching env vars.)');
    process.exit(0);
  }
  if (failed > 0) {
    console.log(`${RED}${failed} of ${ran.length} provider check(s) failed.${RESET}\n`);
    process.exit(3);
  }
  console.log(`${GREEN}All ${ran.length} provider check(s) passed.${RESET}\n`);
})();
