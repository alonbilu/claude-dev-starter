#!/usr/bin/env node
//
// verify-zitadel.js — Smoke-test Zitadel credentials BEFORE you spend an hour
// debugging why your API returns 401.
//
// Zero dependencies. Reads .env from the workspace root (no dotenv).
//
// Checks (in order):
//   1. ZITADEL_ISSUER env vars present
//   2. .well-known/openid-configuration reachable + returns a valid issuer
//   3. ZITADEL_SERVICE_ACCOUNT_KEY file readable + valid JSON (if Management API needed)
//   4. JWT can be signed with the service-account key (RS256 from private key in the file)
//   5. Token endpoint accepts the JWT bearer (returns an access token)
//   6. Management API responds (lists projects for the org)
//
// Usage:
//   node scripts/verify-zitadel.js              # reads .env
//   node scripts/verify-zitadel.js .env.staging # explicit
//
// Exit codes:
//   0 — all checks passed
//   1 — config / env error (fix .env)
//   2 — network error
//   3 — Zitadel rejected credentials

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { URL } = require('node:url');

const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const DIM = '\x1b[2m';

const ok = (msg) => console.log(`${GREEN}✓${RESET} ${msg}`);
const fail = (msg, hint) => {
  console.log(`${RED}✗${RESET} ${msg}`);
  if (hint) console.log(`  ${DIM}${hint}${RESET}`);
};
const info = (msg) => console.log(`${YELLOW}→${RESET} ${msg}`);

// ─── Load .env (no dotenv dep) ────────────────────────────────────────────
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

// ─── Check 1: required env vars ───────────────────────────────────────────
console.log(`\nVerifying Zitadel credentials (reading ${envFile})\n`);

const required = ['ZITADEL_ISSUER'];
const missing = required.filter((k) => !env[k]);
if (missing.length) {
  fail(`missing env vars: ${missing.join(', ')}`, 'see .env.example for the Zitadel block');
  process.exit(1);
}
ok(`required env present (ZITADEL_ISSUER=${env.ZITADEL_ISSUER})`);

const issuer = env.ZITADEL_ISSUER.replace(/\/$/, '');

// ─── Check 2: .well-known/openid-configuration ────────────────────────────
async function checkDiscovery() {
  const url = `${issuer}/.well-known/openid-configuration`;
  info(`fetching ${url}`);
  const res = await fetch(url);
  if (!res.ok) {
    fail(`discovery returned ${res.status} ${res.statusText}`,
      `verify ZITADEL_ISSUER is correct + reachable`);
    process.exit(2);
  }
  const doc = await res.json();
  if (doc.issuer !== issuer && doc.issuer !== `${issuer}/`) {
    fail(`discovery doc issuer mismatch`, `got ${doc.issuer}, expected ${issuer}`);
    process.exit(3);
  }
  ok(`discovery doc reachable + issuer matches`);
  return doc;
}

// ─── Check 3 + 4: Management API via service-account JWT ──────────────────
function signRS256(headerObj, payloadObj, privateKeyPem) {
  const b64u = (s) =>
    Buffer.from(typeof s === 'string' ? s : JSON.stringify(s))
      .toString('base64')
      .replace(/=+$/, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

  const h = b64u(headerObj);
  const p = b64u(payloadObj);
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${h}.${p}`);
  signer.end();
  const sig = signer.sign(privateKeyPem).toString('base64')
    .replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${h}.${p}.${sig}`;
}

async function checkManagementAPI(discoveryDoc) {
  const keyPath = env.ZITADEL_SERVICE_ACCOUNT_KEY;
  if (!keyPath) {
    info('ZITADEL_SERVICE_ACCOUNT_KEY not set — skipping Management API checks');
    info('  (Auth-only setups don\'t need it; only set it if you query the Management API from the backend.)');
    return;
  }
  const resolved = path.isAbsolute(keyPath) ? keyPath : path.resolve(process.cwd(), keyPath);
  if (!fs.existsSync(resolved)) {
    fail(`service-account key file not found: ${resolved}`,
      'download the service-account keyfile from Zitadel → Service Users → Keys');
    process.exit(1);
  }
  let keyJson;
  try { keyJson = JSON.parse(fs.readFileSync(resolved, 'utf8')); }
  catch (e) { fail(`service-account keyfile is not valid JSON: ${e.message}`); process.exit(1); }
  if (!keyJson.key || !keyJson.userId || !keyJson.keyId) {
    fail('service-account keyfile missing fields',
      'expected: { type, keyId, key, userId }');
    process.exit(1);
  }
  ok(`service-account keyfile loaded (userId=${keyJson.userId}, keyId=${keyJson.keyId})`);

  // Build + sign the JWT (RFC 7523 client authentication)
  const now = Math.floor(Date.now() / 1000);
  const jwt = signRS256(
    { alg: 'RS256', typ: 'JWT', kid: keyJson.keyId },
    {
      iss: keyJson.userId,
      sub: keyJson.userId,
      aud: issuer,
      iat: now,
      exp: now + 60,
    },
    keyJson.key
  );
  ok('signed JWT with service-account private key (RS256)');

  // Exchange JWT for an access token (urn:ietf:params:oauth:client-assertion-type:jwt-bearer)
  const tokenUrl = discoveryDoc.token_endpoint;
  info(`exchanging JWT at ${tokenUrl}`);
  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    scope: 'openid urn:zitadel:iam:org:project:id:zitadel:aud',
    assertion: jwt,
  });
  const tokRes = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!tokRes.ok) {
    const errBody = await tokRes.text();
    fail(`token endpoint rejected JWT (${tokRes.status})`, errBody.slice(0, 400));
    process.exit(3);
  }
  const tok = await tokRes.json();
  if (!tok.access_token) {
    fail('token response had no access_token', JSON.stringify(tok));
    process.exit(3);
  }
  ok(`got access token (expires_in=${tok.expires_in}s)`);

  // Call Management API — listMyOrgs is a low-perms read that proves the token works
  const apiUrl = env.ZITADEL_API_URL || issuer;
  const mgmtUrl = `${apiUrl.replace(/\/$/, '')}/management/v1/orgs/me`;
  info(`calling Management API: ${mgmtUrl}`);
  const mgmtRes = await fetch(mgmtUrl, {
    headers: { Authorization: `Bearer ${tok.access_token}`, Accept: 'application/json' },
  });
  if (mgmtRes.status === 403) {
    fail('Management API returned 403',
      'the service account exists but has no permissions — grant it ORG_OWNER (or similar) in Zitadel');
    process.exit(3);
  }
  if (!mgmtRes.ok) {
    fail(`Management API returned ${mgmtRes.status}`, (await mgmtRes.text()).slice(0, 400));
    process.exit(3);
  }
  const org = await mgmtRes.json();
  ok(`Management API responding (org.name=${org.org?.name ?? '?'})`);
}

// ─── Main ─────────────────────────────────────────────────────────────────
(async () => {
  try {
    const doc = await checkDiscovery();
    await checkManagementAPI(doc);
    console.log(`\n${GREEN}All Zitadel checks passed.${RESET}\n`);
  } catch (e) {
    fail(`unexpected error: ${e.message}`);
    if (process.env.DEBUG) console.error(e.stack);
    process.exit(2);
  }
})();
