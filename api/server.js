#!/usr/bin/env node
// Gateway API Lookup Pengajuan SKCK & Izin Keramaian. Tanpa database dan tanpa dependensi.
// Data diambil dari API sumber (UPSTREAM_HOST, mis. admin-be); klien mitra dari CLIENTS_FILE.
// Kontrak sama dengan dokumentasi: POST /api/v1/external/service-applications/lookup
// Sekaligus menyajikan halaman Portal, Dokumentasi, Tampilan Data, dan VC.
//
//   node api/server.js
//
// Konfigurasi (variabel lingkungan atau file ENV_FILE, default /etc/docs-super-apps/api.env):
//   UPSTREAM_HOST=https://host/admin-be               API sumber data (wajib)
//   UPSTREAM_APP_ID=...  UPSTREAM_ACCESS_KEY=...       kredensial ke API sumber (wajib)
//   INSECURE_TLS=true                                 terima sertifikat HTTPS internal / self-signed
//   ATTR_FILE=data/atribut-skck.json                 atribut SKCK tambahan per NIK (diisi manual)
//   CLIENTS_FILE=/etc/docs-super-apps/clients.json     App-Id + hash Access-Key (dibuat create-client.js)
//   PORT=5173  BIND=127.0.0.1
//   UI_ENABLED=true     halaman web + jalur /proxy tanpa key (untuk tampilan internal)
//   RATE_LIMIT=60       permintaan per menit per App-Id
'use strict';

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// --- Konfigurasi --------------------------------------------------------------------
function loadEnv(file) {
  const out = {};
  try {
    for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
      if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch (e) { /* file opsional */ }
  return out;
}
const ENV_FILE = process.env.ENV_FILE || '/etc/docs-super-apps/api.env';
const env = { ...loadEnv(ENV_FILE), ...loadEnv(path.join(__dirname, '.env')), ...process.env };
const PORT = Number(env.PORT || 5173);
const BIND = env.BIND || '127.0.0.1';
const UI_ENABLED = !/^(0|false|no)$/i.test(env.UI_ENABLED || 'true');
const RATE_LIMIT = Number(env.RATE_LIMIT || 60);
const ROOT = path.resolve(__dirname, '..');
const LOOKUP_PATH = '/api/v1/external/service-applications/lookup';
const CREDENTIAL_PATH = '/api/v1/external/skck/credential';
const SERVICES = ['skck', 'crowd_permit'];

const UPSTREAM_HOST = String(env.UPSTREAM_HOST || '').replace(/\/+$/, '');
const UPSTREAM_APP_ID = env.UPSTREAM_APP_ID || '';
const UPSTREAM_ACCESS_KEY = env.UPSTREAM_ACCESS_KEY || '';
const INSECURE_TLS = /^(1|true|yes)$/i.test(env.INSECURE_TLS || '');
if (!/^https?:\/\//.test(UPSTREAM_HOST) || !UPSTREAM_APP_ID || !UPSTREAM_ACCESS_KEY) {
  console.error(`[GAGAL] UPSTREAM_HOST, UPSTREAM_APP_ID, dan UPSTREAM_ACCESS_KEY wajib diisi (${ENV_FILE}).`);
  process.exit(1);
}
const upstreamUrl = new URL(UPSTREAM_HOST);
const upstreamClient = upstreamUrl.protocol === 'https:' ? https : http;
const CLIENTS_FILE = path.resolve(env.CLIENTS_FILE || '/etc/docs-super-apps/clients.json');
const ATTR_FILE = path.resolve(ROOT, env.ATTR_FILE || 'data/atribut-skck.json');

// --- Penyimpanan berbasis file (dimuat ulang otomatis saat file berubah) -------------
function jsonStore(file, fallback, validate) {
  let cache = fallback, mtime = -1, lastError = null;
  return {
    get() {
      let st;
      try { st = fs.statSync(file); } catch (e) { lastError = `File tidak ditemukan: ${file}`; cache = fallback; mtime = -1; return cache; }
      if (st.mtimeMs !== mtime) {
        try { const v = JSON.parse(fs.readFileSync(file, 'utf8')); validate(v); cache = v; lastError = null; }
        catch (e) { lastError = `${path.basename(file)}: ${e.message}`; console.error('[DATA]', lastError); }
        mtime = st.mtimeMs;
      }
      return cache;
    },
    error() { this.get(); return lastError; }
  };
}
const attrStore = jsonStore(ATTR_FILE, { nik: {} }, v => { if (!v.nik || typeof v.nik !== 'object') throw new Error('harus berisi objek "nik"'); });
const clientStore = jsonStore(CLIENTS_FILE, { clients: [] }, v => { if (!Array.isArray(v.clients)) throw new Error('harus berisi array "clients"'); });

// --- Utilitas respons ----------------------------------------------------------------
function wibNow() {
  const d = new Date(Date.now() + 7 * 3600 * 1000);
  return d.toISOString().slice(0, 19) + '+07:00';
}
function envelope(code, title, description, data, info) {
  const body = { status: code >= 200 && code < 300, code, timestamp: wibNow(), message: { title, description } };
  if (data !== undefined) body.data = data;
  if (info !== undefined) body.info = info;
  return body;
}
function sendJson(res, code, obj, extra = {}) {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', ...extra });
  res.end(JSON.stringify(obj));
}
const fail = (res, code, description, extra) => sendJson(res, code, envelope(code, 'Pengajuan Layanan', description), extra);
const log = (...a) => console.log(new Date().toISOString(), ...a);
const sha256 = s => crypto.createHash('sha256').update(String(s), 'utf8').digest();

function readBody(req, limit = 16 * 1024) {
  return new Promise((resolve, reject) => {
    const chunks = []; let size = 0;
    req.on('data', c => { size += c.length; if (size > limit) { reject(Object.assign(new Error('too_large'), { code: 413 })); req.destroy(); } else chunks.push(c); });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

// --- Batas laju sederhana (per App-Id, per menit) -------------------------------------
const hits = new Map();
function rateLimited(key) {
  const now = Date.now(), win = 60000;
  const h = (hits.get(key) || []).filter(t => now - t < win);
  h.push(now); hits.set(key, h);
  return h.length > RATE_LIMIT;
}
setInterval(() => { const now = Date.now(); for (const [k, v] of hits) if (!v.some(t => now - t < 60000)) hits.delete(k); }, 60000).unref();

// --- Validasi permintaan -----------------------------------------------------------------
function parseLookup(raw) {
  let b;
  try { b = JSON.parse(raw || '{}'); } catch (e) { return { error: 'Body harus JSON yang valid.' }; }
  if (!b || typeof b !== 'object' || Array.isArray(b)) return { error: 'Body harus berupa objek JSON.' };
  const nik = typeof b.nik === 'string' ? b.nik.trim() : '';
  if (!/^\d{16}$/.test(nik)) return { error: 'Field nik wajib diisi 16 digit angka.' };
  let services = SERVICES;
  if (b.services !== undefined) {
    if (!Array.isArray(b.services) || !b.services.length || b.services.some(s => !SERVICES.includes(s)))
      return { error: 'Field services hanya boleh berisi "skck" dan/atau "crowd_permit".' };
    services = [...new Set(b.services)];
  }
  const page = b.page === undefined ? 1 : Number(b.page);
  const perPage = b.per_page === undefined ? 20 : Number(b.per_page);
  if (!Number.isInteger(page) || page < 1) return { error: 'Field page harus bilangan bulat >= 1.' };
  if (!Number.isInteger(perPage) || perPage < 1 || perPage > 100) return { error: 'Field per_page harus bilangan bulat 1 sampai 100.' };
  return { nik, services, page, perPage };
}

// --- Lookup ke API sumber ------------------------------------------------------------------
function upstreamRequest(method, apiPath, body, timeoutMs) {
  return new Promise((resolve, reject) => {
    const payload = body ? Buffer.from(JSON.stringify(body)) : null;
    const req = upstreamClient.request({
      protocol: upstreamUrl.protocol, hostname: upstreamUrl.hostname, port: upstreamUrl.port || undefined,
      path: upstreamUrl.pathname.replace(/\/+$/, '') + apiPath, method,
      headers: {
        Accept: 'application/json',
        ...(payload ? { 'Content-Type': 'application/json', 'Content-Length': payload.length, 'App-Id': UPSTREAM_APP_ID, 'Access-Key': UPSTREAM_ACCESS_KEY } : {})
      },
      rejectUnauthorized: !INSECURE_TLS, timeout: timeoutMs
    }, r => {
      const chunks = [];
      r.on('data', c => chunks.push(c));
      r.on('end', () => resolve({ status: r.statusCode, text: Buffer.concat(chunks).toString('utf8') }));
    });
    req.on('timeout', () => req.destroy(Object.assign(new Error('Waktu habis menghubungi API sumber'), { code: 'ETIMEDOUT' })));
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

function upstreamError(err) {
  const c = err.code || '';
  if (['ETIMEDOUT', 'ECONNREFUSED', 'EHOSTUNREACH', 'ENETUNREACH', 'ENOTFOUND', 'ECONNRESET'].includes(c)) return 'API sumber tidak dapat dijangkau dari server.';
  if (/CERT|SELF_SIGNED|UNABLE_TO_VERIFY/.test(c)) return 'Sertifikat HTTPS API sumber ditolak. Set INSECURE_TLS=true jika memakai sertifikat internal.';
  return 'Gagal menghubungi API sumber.';
}

class UpstreamFail extends Error { constructor(code, msg) { super(msg); this.httpCode = code; } }

async function lookup({ nik, services, page, perPage }) {
  const body = { nik, page, per_page: perPage };
  if (services.length < SERVICES.length) body.services = services;
  let r;
  try { r = await upstreamRequest('POST', LOOKUP_PATH, body, 30000); }
  catch (e) { log(`UPSTREAM gagal: ${e.code || ''} ${e.message}`); throw new UpstreamFail(502, upstreamError(e)); }
  let j = null;
  try { j = JSON.parse(r.text); } catch (e) { /* bukan JSON */ }
  if (r.status === 401 || r.status === 403) { log(`UPSTREAM ${r.status}: kredensial ditolak`); throw new UpstreamFail(502, 'Kredensial server ke API sumber ditolak. Periksa UPSTREAM_APP_ID dan UPSTREAM_ACCESS_KEY.'); }
  if (r.status === 422 && j && j.message) throw new UpstreamFail(422, j.message.description || j.message.title || 'Permintaan tidak valid.');
  if (r.status < 200 || r.status >= 300 || !j || !j.data) { log(`UPSTREAM ${r.status}: respons tidak valid`); throw new UpstreamFail(502, `API sumber membalas HTTP ${r.status}.`); }
  const d = j.data;
  return {
    data: { user: d.user ?? null, skck: services.includes('skck') ? d.skck || [] : [], crowd_permit: services.includes('crowd_permit') ? d.crowd_permit || [] : [] },
    info: j.info || { current_page: page, per_page: perPage, total: (d.skck || []).length + (d.crowd_permit || []).length, last_page: 1 }
  };
}

function auditLog(appId, nik, services, status, count, ip) {
  const nikRef = nik ? sha256(nik).toString('hex').slice(0, 12) : '-';
  log(`AUDIT app=${appId || 'ui'} nik#${nikRef} layanan=${(services || []).join(',') || '-'} status=${status} hasil=${count ?? '-'} ip=${ip || '-'}`);
}

function clientIp(req) {
  const ip = (req.socket.remoteAddress || '').replace(/^::ffff:/, '');
  return /^[0-9a-f:.]+$/i.test(ip) ? ip : null;
}

// --- Handler lookup ------------------------------------------------------------------------
// Autentikasi klien. Mengembalikan { appId, allowed } atau null (respons error sudah dikirim).
function authenticate(req, res, trustedUi, ip) {
  if (trustedUi) {
    if (rateLimited('ui:' + (ip || '-'))) { fail(res, 429, `Batas ${RATE_LIMIT} permintaan per menit terlampaui.`, { 'Retry-After': '60' }); return null; }
    return { appId: null, allowed: SERVICES };
  }
  const appId = String(req.headers['app-id'] || '').trim();
  const key = String(req.headers['access-key'] || '');
  if (!appId || !key) { fail(res, 401, 'Header App-Id dan Access-Key wajib diisi.'); return null; }
  if (/^bearer\s/i.test(key)) { fail(res, 401, 'Access-Key dikirim tanpa awalan Bearer.'); return null; }
  const keyHash = sha256(key);
  const c = clientStore.get().clients.find(x => x.app_id === appId && x.active !== false && typeof x.access_key_sha256 === 'string' && x.access_key_sha256.length === 64 &&
    crypto.timingSafeEqual(Buffer.from(x.access_key_sha256, 'hex'), keyHash));
  if (!c) { log(`401 ${appId}`); fail(res, 401, 'App-Id atau Access-Key tidak valid.'); return null; }
  if (rateLimited(appId)) { fail(res, 429, `Batas ${RATE_LIMIT} permintaan per menit terlampaui.`, { 'Retry-After': '60' }); return null; }
  return { appId, allowed: Array.isArray(c.services) && c.services.length ? c.services : SERVICES };
}

async function handleLookup(req, res, { trustedUi }) {
  const ip = clientIp(req);
  const auth = authenticate(req, res, trustedUi, ip); if (!auth) return;
  const { appId, allowed } = auth;

  let raw;
  try { raw = await readBody(req); } catch (e) { return fail(res, e.code === 413 ? 413 : 400, 'Body permintaan tidak dapat dibaca.'); }
  const q = parseLookup(raw);
  if (q.error) { auditLog(appId, null, [], 422, null, ip); return fail(res, 422, q.error); }
  const denied = q.services.filter(s => !allowed.includes(s));
  if (denied.length) { auditLog(appId, q.nik, q.services, 403, null, ip); return fail(res, 403, `App-Id ini tidak diizinkan mengakses layanan: ${denied.join(', ')}.`); }

  let result;
  try { result = await lookup(q); }
  catch (e) {
    if (!(e instanceof UpstreamFail)) throw e;
    auditLog(appId, q.nik, q.services, e.httpCode, null, ip);
    return fail(res, e.httpCode, e.message);
  }
  const { data, info } = result;
  const count = data.skck.length + data.crowd_permit.length;
  auditLog(appId, q.nik, q.services, 200, count, ip);
  log(`200 ${trustedUi ? 'ui' : appId} services=${q.services.join(',')} hasil=${count}`);
  sendJson(res, 200, envelope(200, 'Pengajuan Layanan', 'Lookup pengajuan selesai', data, info));
}

// --- Kredensial SKCK: API 1 + atribut manual -> katalog id.idctf.skck.1 ---------------------
const SKCK_ATTRS = ['nomor_skck', 'nama_lengkap', 'jenis_kelamin', 'kebangsaan', 'agama', 'tempat_dan_tanggal_lahir', 'tempat_tinggal_sekarang',
  'pekerjaan', 'nik', 'nomer_paspor', 'catatan_kepolisian', 'sejak_di_indonesia', 'sampai_dengan', 'untuk_keperluan', 'berlaku_dari_tanggal', 'end_date', 'foto'];
const FOTO_KOSONG = 'data:image/svg+xml;base64,' + Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 90 120"><rect width="90" height="120" fill="#e3ddd3"/><circle cx="45" cy="46" r="20" fill="#8a8f98"/><path d="M12 120c2-26 16-38 33-38s31 12 33 38z" fill="#8a8f98"/></svg>').toString('base64');

async function handleCredential(req, res, { trustedUi }) {
  const ip = clientIp(req);
  const auth = authenticate(req, res, trustedUi, ip); if (!auth) return;
  const { appId, allowed } = auth;
  if (!allowed.includes('skck')) { auditLog(appId, null, ['skck'], 403, null, ip); return fail(res, 403, 'App-Id ini tidak diizinkan mengakses layanan: skck.'); }

  let b;
  try { b = JSON.parse((await readBody(req)) || '{}'); } catch (e) { return fail(res, 422, 'Body harus JSON yang valid.'); }
  const nik = typeof b?.nik === 'string' ? b.nik.trim() : '';
  if (!/^\d{16}$/.test(nik)) return fail(res, 422, 'Field nik wajib diisi 16 digit angka.');
  const nomor = typeof b.nomor_skck === 'string' ? b.nomor_skck.trim() : '';

  // 1. Data dari API 1
  let r;
  try { r = await lookup({ nik, services: ['skck'], page: 1, perPage: 100 }); }
  catch (e) { if (!(e instanceof UpstreamFail)) throw e; auditLog(appId, nik, ['skck'], e.httpCode, null, ip); return fail(res, e.httpCode, e.message); }
  const list = r.data.skck || [];
  const row = nomor ? list.find(x => x.registration_number === nomor)
                    : list.filter(x => x.status === 'completed').sort((a, c) => String(c.submitted_at).localeCompare(String(a.submitted_at)))[0];
  if (!r.data.user || !row) {
    auditLog(appId, nik, ['skck'], 404, 0, ip);
    return fail(res, 404, nomor ? `SKCK ${nomor} tidak ditemukan untuk NIK ini.` : 'Tidak ada SKCK berstatus selesai (completed) untuk NIK ini.');
  }

  if (row.status !== 'completed') {
    auditLog(appId, nik, ['skck'], 409, 0, ip);
    return fail(res, 409, `SKCK ${row.registration_number} belum terbit (status: ${row.status}). Kredensial hanya untuk SKCK berstatus completed.`);
  }

  // 2. Atribut manual dari JSON
  const manual = attrStore.get().nik[nik];
  if (!manual) { auditLog(appId, nik, ['skck'], 404, 0, ip); return fail(res, 404, 'Atribut tambahan untuk NIK ini belum ada di file atribut.'); }

  // 3. Gabungkan sesuai urutan katalog
  const fromApi = {
    nomor_skck: row.registration_number,
    nama_lengkap: String(r.data.user.full_name || '').toUpperCase(),
    nik,
    untuk_keperluan: String(row.purpose || '').toUpperCase(),
    berlaku_dari_tanggal: String(row.submitted_at || '').slice(0, 10),
    end_date: row.estimated_expires_on || ''
  };
  const attributes = {};
  for (const k of SKCK_ATTRS) {
    const v = manual[k] !== undefined && manual[k] !== '' ? manual[k] : fromApi[k];
    attributes[k] = v === undefined || v === '' ? (k === 'foto' ? FOTO_KOSONG : null) : v;
  }
  const missing = SKCK_ATTRS.filter(k => attributes[k] === null);

  auditLog(appId, nik, ['skck_credential'], 200, 1, ip);
  sendJson(res, 200, envelope(200, 'Kredensial SKCK', missing.length ? `Atribut belum lengkap: ${missing.join(', ')}` : 'Atribut kredensial lengkap', {
    vct: 'id.idctf.skck.1',
    attributes,
    validity: {
      status: row.estimated_validity_status ?? null,
      expires_on: row.estimated_expires_on ?? null,
      days_remaining: row.estimated_days_remaining ?? null
    }
  }));
}

// --- File statis (UI) -------------------------------------------------------------------------
const MIME = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon', '.woff2': 'font/woff2' };
function serveStatic(req, res, urlPath) {
  let rel;
  try { rel = decodeURIComponent(urlPath); } catch (e) { return send404(res); }
  if (rel === '/') rel = '/portal.html';
  if (rel.endsWith('/')) rel += 'index.html';
  const parts = rel.split('/').filter(Boolean);
  if (parts.some(p => p.startsWith('.')) || ['deploy', 'api', 'data', 'node_modules'].includes(parts[0]) || /\.(md|sh|env|example|sql|ps1|bat)$/i.test(rel)) return send404(res);
  const file = path.join(ROOT, ...parts);
  if (!file.startsWith(ROOT + path.sep)) return send404(res);
  fs.readFile(file, (err, data) => {
    if (err) return send404(res);
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream', 'X-Content-Type-Options': 'nosniff' });
    res.end(req.method === 'HEAD' ? '' : data);
  });
}
function send404(res) { res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }); res.end('Tidak ditemukan'); }

// --- Router ------------------------------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  const p = new URL(req.url, 'http://localhost').pathname;
  try {
    if (p === LOOKUP_PATH) {
      if (req.method !== 'POST') return fail(res, 405, 'Gunakan metode POST.', { Allow: 'POST' });
      return await handleLookup(req, res, { trustedUi: false });
    }
    if (p === CREDENTIAL_PATH) {
      if (req.method !== 'POST') return fail(res, 405, 'Gunakan metode POST.', { Allow: 'POST' });
      return await handleCredential(req, res, { trustedUi: false });
    }
    if (p === '/health' || p === '/__health') {
      const nc = clientStore.get().clients.length;
      try {
        const r = await upstreamRequest('GET', '/', null, 8000);
        return sendJson(res, 200, { ok: r.status < 500, upstream: r.status < 500 ? 'ok' : 'error', upstream_status: r.status, klien: nc });
      } catch (e) {
        return sendJson(res, 200, { ok: false, upstream: 'gagal', error: upstreamError(e), klien: nc });
      }
    }
    if (!UI_ENABLED) return fail(res, 404, 'Endpoint tidak ditemukan.');

    if (p === '/proxy' + LOOKUP_PATH) {
      if (req.method !== 'POST') return fail(res, 405, 'Gunakan metode POST.', { Allow: 'POST' });
      return await handleLookup(req, res, { trustedUi: true });
    }
    if (p === '/proxy' + CREDENTIAL_PATH) {
      if (req.method !== 'POST') return fail(res, 405, 'Gunakan metode POST.', { Allow: 'POST' });
      return await handleCredential(req, res, { trustedUi: true });
    }
    if (p === '/assets/config.js') {
      res.writeHead(200, { 'Content-Type': 'text/javascript; charset=utf-8', 'Cache-Control': 'no-store' });
      return res.end(`window.APP_CONFIG = ${JSON.stringify({ apiHost: '/proxy', proxy: true, healthUrl: '/__health' })};\n`);
    }
    if (req.method !== 'GET' && req.method !== 'HEAD') return fail(res, 405, 'Metode tidak diizinkan.');
    return serveStatic(req, res, p);
  } catch (e) {
    console.error('[ERROR]', e);
    if (!res.headersSent) fail(res, 500, 'Terjadi kesalahan pada server.');
  }
});

server.on('error', err => {
  console.error(err.code === 'EADDRINUSE' ? `[GAGAL] Port ${PORT} sudah dipakai.` : `[GAGAL] ${err.message}`);
  process.exit(1);
});
server.listen(PORT, BIND, () => {
  log(`API SKCK berjalan di http://${BIND}:${PORT}  (UI ${UI_ENABLED ? 'aktif' : 'mati'})`);
  log(`Sumber: ${upstreamUrl.origin}${upstreamUrl.pathname} (TLS ${INSECURE_TLS ? 'tanpa verifikasi' : 'terverifikasi'})`);
  log(`Atribut: ${ATTR_FILE} (${attrStore.error() || Object.keys(attrStore.get().nik).length + ' NIK'})`);
  log(`Klien : ${CLIENTS_FILE} (${clientStore.error() || clientStore.get().clients.length + ' klien'})`);
});
const stop = () => { server.close(() => process.exit(0)); setTimeout(() => process.exit(0), 3000).unref(); };
process.on('SIGTERM', stop); process.on('SIGINT', stop);
