#!/usr/bin/env node
// Server lokal docs-super-apps: menyajikan file docs + proxy ke API SKCK.
// Browser hanya memanggil localhost, jadi tidak ada CORS, dan Access-Key tetap di server.
// Butuh Node.js 18+. Tanpa dependensi.
//
//   node deploy/local/server.js
//
// Konfigurasi dibaca dari file .env di root repo (lihat deploy/local/.env.example).
'use strict';

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const ENV_PATH = process.env.ENV_FILE || path.join(ROOT, '.env');

// --- .env -----------------------------------------------------------------------
function loadEnv(file) {
  const out = {};
  if (!fs.existsSync(file)) return out;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    out[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
  return out;
}
const env = { ...loadEnv(ENV_PATH), ...process.env };
const PORT = Number(env.PORT || 5173);
const BIND = env.BIND || '127.0.0.1';
const API_HOST = String(env.API_HOST || '').replace(/\/+$/, '');
const APP_ID = env.APP_ID || '';
const ACCESS_KEY = env.ACCESS_KEY || '';
const INSECURE_TLS = /^(1|true|yes)$/i.test(env.INSECURE_TLS || '');

if (!/^https?:\/\//.test(API_HOST) || !APP_ID || !ACCESS_KEY) {
  console.error(`[GAGAL] API_HOST, APP_ID, dan ACCESS_KEY wajib diisi di ${ENV_PATH}`);
  process.exit(1);
}
const api = new URL(API_HOST);
const client = api.protocol === 'https:' ? https : http;

// Hanya endpoint ini yang boleh diteruskan
const ALLOWED = new Set(['POST /api/v1/external/service-applications/lookup']);

const MIME = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon',
  '.woff2': 'font/woff2', '.map': 'application/json'
};

const send = (res, code, body, type = 'text/plain; charset=utf-8', extra = {}) => {
  res.writeHead(code, { 'Content-Type': type, 'X-Content-Type-Options': 'nosniff', ...extra });
  res.end(body);
};
const sendJson = (res, code, obj) => send(res, code, JSON.stringify(obj), 'application/json; charset=utf-8', { 'Cache-Control': 'no-store' });
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);

// --- Proxy ----------------------------------------------------------------------
function upstream(method, apiPath, body, headers, timeoutMs) {
  return new Promise((resolve, reject) => {
    const req = client.request({
      protocol: api.protocol, hostname: api.hostname, port: api.port || undefined,
      path: api.pathname.replace(/\/+$/, '') + apiPath, method,
      headers, rejectUnauthorized: !INSECURE_TLS, timeout: timeoutMs
    }, r => {
      const chunks = [];
      r.on('data', c => chunks.push(c));
      r.on('end', () => resolve({ status: r.statusCode, headers: r.headers, body: Buffer.concat(chunks) }));
    });
    req.on('timeout', () => req.destroy(new Error('Waktu habis menghubungi API')));
    req.on('error', reject);
    if (body && body.length) req.write(body);
    req.end();
  });
}

function readBody(req, limit = 64 * 1024) {
  return new Promise((resolve, reject) => {
    const chunks = []; let size = 0;
    req.on('data', c => { size += c.length; if (size > limit) { reject(new Error('Body terlalu besar')); req.destroy(); } else chunks.push(c); });
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function friendly(err) {
  const c = err.code || '';
  if (['ETIMEDOUT', 'ECONNREFUSED', 'EHOSTUNREACH', 'ENETUNREACH', 'ENOTFOUND'].includes(c) || /Waktu habis/.test(err.message))
    return 'API tidak bisa dijangkau. Pastikan GlobalProtect aktif.';
  if (/CERT|SELF_SIGNED|UNABLE_TO_VERIFY/.test(c))
    return 'Sertifikat HTTPS API tidak dipercaya. Set INSECURE_TLS=true di .env jika API memakai sertifikat internal.';
  return err.message;
}

async function handleProxy(req, res, apiPath) {
  if (!ALLOWED.has(`${req.method} ${apiPath}`)) return sendJson(res, 404, { status: false, code: 404, message: { title: 'Proxy', description: 'Endpoint tidak diizinkan lewat proxy lokal.' } });
  try {
    const body = await readBody(req);
    const r = await upstream(req.method, apiPath, body, {
      'Content-Type': 'application/json', 'Accept': 'application/json',
      'App-Id': APP_ID, 'Access-Key': ACCESS_KEY, 'Content-Length': body.length
    }, 30000);
    log(`${req.method} ${apiPath} -> ${r.status}`);
    send(res, r.status, r.body, r.headers['content-type'] || 'application/json', { 'Cache-Control': 'no-store' });
  } catch (err) {
    log(`${req.method} ${apiPath} -> GAGAL: ${err.code || ''} ${err.message}`);
    sendJson(res, 502, { status: false, code: 502, message: { title: 'Gagal Menghubungkan ke API SKCK', description: friendly(err) } });
  }
}

async function handleHealth(res) {
  try {
    const r = await upstream('GET', '/', null, { Accept: '*/*' }, 8000);
    sendJson(res, 200, { ok: r.status < 500, status: r.status });
  } catch (err) {
    sendJson(res, 200, { ok: false, error: friendly(err) });
  }
}

// --- File statis ----------------------------------------------------------------
function serveStatic(req, res, urlPath) {
  let rel = decodeURIComponent(urlPath);
  if (rel.endsWith('/')) rel += 'index.html';
  const parts = rel.split('/').filter(Boolean);
  if (parts.some(p => p.startsWith('.')) || parts[0] === 'deploy' || /\.(md|sh|env|example)$/i.test(rel))
    return send(res, 404, 'Tidak ditemukan');
  const file = path.join(ROOT, ...parts);
  if (!file.startsWith(ROOT + path.sep)) return send(res, 404, 'Tidak ditemukan');
  fs.readFile(file, (err, data) => {
    if (err) return send(res, 404, 'Tidak ditemukan');
    send(res, 200, req.method === 'HEAD' ? '' : data, MIME[path.extname(file).toLowerCase()] || 'application/octet-stream');
  });
}

// --- Server ---------------------------------------------------------------------
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const p = url.pathname;

  if (p === '/assets/config.js') {
    // Tanpa App-Id/Access-Key: keduanya ditambahkan oleh proxy di server.
    return send(res, 200, `window.APP_CONFIG = ${JSON.stringify({ apiHost: '/proxy', proxy: true, healthUrl: '/__health' })};\n`,
      'text/javascript; charset=utf-8', { 'Cache-Control': 'no-store' });
  }
  if (p === '/__health') return handleHealth(res);
  if (p.startsWith('/proxy/')) return handleProxy(req, res, p.slice('/proxy'.length));
  if (req.method !== 'GET' && req.method !== 'HEAD') return send(res, 405, 'Metode tidak diizinkan');
  serveStatic(req, res, p);
});

server.on('error', err => {
  if (err.code === 'EADDRINUSE') console.error(`[GAGAL] Port ${PORT} sudah dipakai. Ganti PORT di .env.`);
  else console.error('[GAGAL]', err.message);
  process.exit(1);
});

server.listen(PORT, BIND, () => {
  console.log('');
  console.log(`  Docs Super Apps berjalan`);
  console.log(`  Dokumentasi  : http://localhost:${PORT}/`);
  console.log(`  Tampilan data: http://localhost:${PORT}/data.html`);
  console.log(`  API          : ${api.origin} (TLS ${INSECURE_TLS ? 'tanpa verifikasi' : 'terverifikasi'})`);
  console.log('');
  console.log('  Pastikan GlobalProtect aktif. Tekan Ctrl+C untuk berhenti.');
  console.log('');
});
