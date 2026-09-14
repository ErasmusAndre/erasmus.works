// Authentik -> Umami login bridge.
//
// Umami has no OIDC support, but its dashboard trusts any token encrypted with
// APP_SECRET. This service logs the user in with Authentik, finds the Umami
// user with the same username, mints a token the same way Umami's own
// /api/auth/login does (src/app/api/auth/login/route.ts, src/lib/jwt.ts,
// src/lib/crypto.ts in Umami v3), and stores it in the browser.
//
// Re-check the token format after major Umami upgrades.

import crypto from 'node:crypto';
import http from 'node:http';
import { createRequire } from 'node:module';

const require = createRequire('/deps/index.js');
const pg = require('pg');

const {
  APP_SECRET,
  DATABASE_URL,
  OIDC_ISSUER,
  OIDC_CLIENT_ID,
  OIDC_CLIENT_SECRET,
  PUBLIC_URL,
  TOKEN_TTL_SECONDS = '43200',
  PORT = '3001',
} = process.env;

for (const [name, value] of Object.entries({
  APP_SECRET,
  DATABASE_URL,
  OIDC_ISSUER,
  OIDC_CLIENT_ID,
  OIDC_CLIENT_SECRET,
  PUBLIC_URL,
})) {
  if (!value) {
    console.error(`missing ${name}`);
    process.exit(1);
  }
}

const REDIRECT_URI = `${PUBLIC_URL}/oidc/callback`;
const STATE_COOKIE = 'umami_oidc_state';
const AUTH_TOKEN_KEY = 'umami.auth';

const db = new pg.Pool({ connectionString: DATABASE_URL, max: 2 });

// --- Umami token format -----------------------------------------------------

const sha512 = value => crypto.createHash('sha512').update(value).digest('hex');
const b64url = value => Buffer.from(value).toString('base64url');

// Umami's secret() is sha512(APP_SECRET), used as-is for both HS256 and AES.
const umamiSecret = sha512(APP_SECRET);

function signJwt(payload) {
  const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = b64url(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', umamiSecret)
    .update(`${header}.${body}`)
    .digest('base64url');
  return `${header}.${body}.${signature}`;
}

function encrypt(value) {
  const iv = crypto.randomBytes(16);
  const salt = crypto.randomBytes(64);
  const key = crypto.pbkdf2Sync(umamiSecret, salt, 10000, 32, 'sha512');
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return Buffer.concat([salt, iv, cipher.getAuthTag(), encrypted]).toString('base64');
}

function createUmamiToken(user) {
  const now = Math.floor(Date.now() / 1000);
  return encrypt(
    signJwt({
      userId: user.user_id,
      role: user.role,
      // Same fingerprint as Umami's login, so a password change revokes the token.
      pwd: sha512(user.password),
      iat: now,
      exp: now + Number(TOKEN_TTL_SECONDS),
    }),
  );
}

// --- OIDC -------------------------------------------------------------------

let discovery;

async function getDiscovery() {
  if (!discovery) {
    const res = await fetch(new URL('.well-known/openid-configuration', OIDC_ISSUER));
    if (!res.ok) throw new Error(`discovery failed: ${res.status}`);
    discovery = await res.json();
  }
  return discovery;
}

// The state cookie only needs integrity, not secrecy.
const stateKey = crypto.createHmac('sha256', APP_SECRET).update('umami-oidc-state').digest();

function sealState(data) {
  const body = b64url(JSON.stringify(data));
  const mac = crypto.createHmac('sha256', stateKey).update(body).digest('base64url');
  return `${body}.${mac}`;
}

function unsealState(value) {
  const [body, mac] = String(value || '').split('.');
  if (!body || !mac) return null;
  const expected = crypto.createHmac('sha256', stateKey).update(body).digest('base64url');
  if (mac.length !== expected.length || !crypto.timingSafeEqual(Buffer.from(mac), Buffer.from(expected))) {
    return null;
  }
  const data = JSON.parse(Buffer.from(body, 'base64url').toString());
  return data.expires > Date.now() ? data : null;
}

function readCookie(req, name) {
  for (const part of (req.headers.cookie || '').split(';')) {
    const [key, ...rest] = part.trim().split('=');
    if (key === name) return rest.join('=');
  }
  return null;
}

async function startLogin(res) {
  const { authorization_endpoint } = await getDiscovery();
  const state = crypto.randomBytes(16).toString('base64url');
  const nonce = crypto.randomBytes(16).toString('base64url');
  const verifier = crypto.randomBytes(32).toString('base64url');
  const challenge = crypto.createHash('sha256').update(verifier).digest('base64url');

  const url = new URL(authorization_endpoint);
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: OIDC_CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    scope: 'openid profile email',
    state,
    nonce,
    code_challenge: challenge,
    code_challenge_method: 'S256',
  }).toString();

  const cookie = sealState({ state, nonce, verifier, expires: Date.now() + 10 * 60 * 1000 });
  res.writeHead(302, {
    Location: url.toString(),
    'Set-Cookie': `${STATE_COOKIE}=${cookie}; Path=/oidc; Max-Age=600; HttpOnly; Secure; SameSite=Lax`,
    'Cache-Control': 'no-store',
  });
  res.end();
}

async function finishLogin(req, res, query) {
  const saved = unsealState(readCookie(req, STATE_COOKIE));
  if (!saved || !query.get('code') || query.get('state') !== saved.state) {
    return sendError(res, 400, 'Login expired or invalid. Please try again.');
  }

  const { token_endpoint, issuer } = await getDiscovery();
  const tokenRes = await fetch(token_endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code: query.get('code'),
      redirect_uri: REDIRECT_URI,
      client_id: OIDC_CLIENT_ID,
      client_secret: OIDC_CLIENT_SECRET,
      code_verifier: saved.verifier,
    }),
  });
  if (!tokenRes.ok) {
    console.error('token exchange failed', tokenRes.status, await tokenRes.text());
    return sendError(res, 502, 'Authentik token exchange failed.');
  }

  // The ID token came straight from the token endpoint over TLS, so its
  // signature does not need to be re-verified (OIDC Core 3.1.3.7).
  const { id_token } = await tokenRes.json();
  const claims = JSON.parse(Buffer.from(String(id_token).split('.')[1] || '', 'base64url').toString() || '{}');
  const audience = [].concat(claims.aud);
  if (
    claims.iss !== issuer ||
    !audience.includes(OIDC_CLIENT_ID) ||
    claims.nonce !== saved.nonce ||
    claims.exp * 1000 < Date.now()
  ) {
    return sendError(res, 401, 'Invalid ID token.');
  }

  const username = String(claims.preferred_username || '').toLowerCase();
  const { rows } = await db.query(
    'select user_id, username, role, password from "user" where username = $1 and deleted_at is null',
    [username],
  );
  if (!rows.length) {
    console.warn(`no Umami user for "${username}"`);
    return sendError(res, 403, `No Umami user named "${username}". Ask an Umami admin to create it.`);
  }

  console.log(`login: ${username}`);
  const token = JSON.stringify(JSON.stringify(createUmamiToken(rows[0])));
  res.writeHead(200, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
    'Set-Cookie': `${STATE_COOKIE}=; Path=/oidc; Max-Age=0; HttpOnly; Secure; SameSite=Lax`,
    'Referrer-Policy': 'no-referrer',
  });
  // Umami's frontend reads localStorage["umami.auth"] as JSON.
  res.end(
    `<!doctype html><script>localStorage.setItem(${JSON.stringify(AUTH_TOKEN_KEY)}, ${token});location.replace("/");</script>`,
  );
}

function sendError(res, status, message) {
  const safe = message.replace(/[&<>"]/g, c => `&#${c.charCodeAt(0)};`);
  res.writeHead(status, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(`<!doctype html><p>${safe}</p><p><a href="/login">Try again</a> · <a href="/login?local=1">Password login</a></p>`);
}

http
  .createServer(async (req, res) => {
    const url = new URL(req.url, PUBLIC_URL);
    try {
      if (req.method === 'GET' && url.pathname === '/healthz') {
        res.writeHead(200).end('ok');
      } else if (req.method === 'GET' && url.pathname === '/login') {
        await startLogin(res);
      } else if (req.method === 'GET' && url.pathname === '/oidc/callback') {
        await finishLogin(req, res, url.searchParams);
      } else {
        res.writeHead(404).end();
      }
    } catch (error) {
      console.error(error);
      if (!res.headersSent) sendError(res, 500, 'Login failed.');
    }
  })
  .listen(Number(PORT), () => console.log(`umami-sso listening on ${PORT}`));
