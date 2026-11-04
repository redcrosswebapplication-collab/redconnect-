'use strict';
const http = require('node:http');
const config = require('./config');
const db = require('./db');
const { HttpError } = require('./http');
db.assertSupabaseConfig();
const { routes, adminClient, profileForAuthId } = require('./routes');

const MAX_BODY = 14 * 1024 * 1024; // two base64 ID photos fit comfortably

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = []; let size = 0;
    req.on('data', (c) => {
      size += c.length;
      if (size > MAX_BODY) { reject(new HttpError(413, 'Request too large')); req.destroy(); return; }
      chunks.push(c);
    });
    req.on('end', () => {
      if (!chunks.length) return resolve({});
      try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
      catch { reject(new HttpError(400, 'Body must be valid JSON')); }
    });
    req.on('error', reject);
  });
}

function send(res, status, payload, headers = {}) {
  const isBuf = Buffer.isBuffer(payload);
  const data = isBuf ? payload : Buffer.from(JSON.stringify(payload));
  res.writeHead(status, {
    'Content-Type': isBuf ? headers.contentType : 'application/json; charset=utf-8',
    'Content-Length': data.length,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
    'X-Content-Type-Options': 'nosniff',
    'Cache-Control': 'no-store',
  });
  res.end(data);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, {});
  try {
    const url = new URL(req.url, 'http://localhost');
    if (url.pathname === '/health') return send(res, 200, { ok: true, time: new Date().toISOString() });

    let matched = null; let pathMatched = false;
    for (const r of routes) {
      const m = r.re.exec(url.pathname);
      if (!m) continue;
      pathMatched = true;
      if (r.method !== req.method) continue;
      matched = { r, params: Object.fromEntries(r.keys.map((k, i) => [k, decodeURIComponent(m[i + 1])])) };
      break;
    }
    if (!matched) throw new HttpError(pathMatched ? 405 : 404, pathMatched ? 'Method not allowed' : 'Route not found');

    let user = null;
    if (matched.r.auth || matched.r.admin) {
      const m = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (m) {
        const { data: result, error } = await adminClient.auth.getUser(m[1]);
        if (!error && result.user) {
          const profile = await profileForAuthId(result.user.id);
          if (profile) user = { ...profile, authUserId: result.user.id, accessToken: m[1] };
        }
      }
      if (!user) throw new HttpError(401, 'Please log in again');
      if (matched.r.admin && user.role !== 'admin') throw new HttpError(403, 'Admins only');
    }
    const body = ['POST', 'PATCH', 'PUT'].includes(req.method) ? await readBody(req) : {};
    const out = await matched.r.handler({
      req, user, body, params: matched.params, query: Object.fromEntries(url.searchParams),
      ip: req.socket.remoteAddress || 'unknown',
    });
    if (out.raw) return send(res, 200, out.raw, { contentType: out.contentType });
    send(res, out.status || 200, out.body);
  } catch (err) {
    if (err instanceof HttpError) return send(res, err.status, { error: err.message, fields: err.fields });
    console.error(err);
    send(res, 500, { error: 'Something went wrong on our side' });
  }
});

server.listen(config.port, '0.0.0.0', () => {
  console.log(`RedCross Connect+ API listening on http://0.0.0.0:${config.port}  (Supabase)`);
});
module.exports = server;
