// Bearer-token gate in front of Playwright MCP, which has no auth of its own.
// Listens on 0.0.0.0:8932 (ufw admits only the two Talos nodes) and forwards requests that
// carry "Authorization: Bearer <key>" to the MCP server on 127.0.0.1:8933. The key lives in
// ~/.config/local-ai/browser-mcp-key (mode 600) and in Open WebUI's "My Chrome" connection.
// Responses are piped through unbuffered: MCP's streamable HTTP uses long-lived SSE streams.
'use strict';
const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');

const LISTEN_PORT = 8932;
const UPSTREAM_PORT = 8933;
const keyFile = path.join(os.homedir(), '.config/local-ai/browser-mcp-key');
const expected = Buffer.from(`Bearer ${fs.readFileSync(keyFile, 'utf8').trim()}`);

function authorized(header) {
  const given = Buffer.from(header || '');
  return given.length === expected.length && crypto.timingSafeEqual(given, expected);
}

const server = http.createServer((req, res) => {
  if (!authorized(req.headers.authorization)) {
    console.log(`rejected ${req.method} ${req.url} from ${req.socket.remoteAddress}`);
    res.writeHead(401, { 'Content-Type': 'text/plain' });
    res.end('unauthorized\n');
    return;
  }
  const headers = { ...req.headers, host: `localhost:${UPSTREAM_PORT}` };
  delete headers.authorization;
  const upstream = http.request(
    { host: '127.0.0.1', port: UPSTREAM_PORT, method: req.method, path: req.url, headers },
    (up) => {
      res.writeHead(up.statusCode, up.headers);
      up.pipe(res);
    },
  );
  upstream.on('error', (err) => {
    console.log(`upstream error: ${err.message}`);
    if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('upstream error\n');
  });
  res.on('close', () => upstream.destroy());
  req.pipe(upstream);
});

server.requestTimeout = 0;
server.headersTimeout = 30000;
server.listen(LISTEN_PORT, '0.0.0.0', () => console.log(`browser-mcp-auth on :${LISTEN_PORT} -> 127.0.0.1:${UPSTREAM_PORT}`));
