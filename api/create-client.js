#!/usr/bin/env node
// Kelola klien API (App-Id + Access-Key) di file CLIENTS_FILE (default /etc/docs-super-apps/clients.json).
//
//   node api/create-client.js buat "Nama Aplikasi" [--services skck,crowd_permit]
//   node api/create-client.js daftar
//   node api/create-client.js nonaktifkan <app_id>
//   node api/create-client.js ganti-key <app_id>
//
// Access-Key hanya ditampilkan SEKALI. File hanya menyimpan hash SHA-256-nya.
// Server membaca ulang file ini otomatis; tidak perlu restart.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function loadEnv(file) {
  const out = {};
  try {
    for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
      if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  } catch (e) { /* opsional */ }
  return out;
}
const env = { ...loadEnv(process.env.ENV_FILE || '/etc/docs-super-apps/api.env'), ...loadEnv(path.join(__dirname, '.env')), ...process.env };
const FILE = path.resolve(env.CLIENTS_FILE || '/etc/docs-super-apps/clients.json');

const sha256hex = s => crypto.createHash('sha256').update(s, 'utf8').digest('hex');
const newKey = () => crypto.randomBytes(32).toString('hex');

function load() {
  try { const v = JSON.parse(fs.readFileSync(FILE, 'utf8')); if (Array.isArray(v.clients)) return v; } catch (e) { if (e.code !== 'ENOENT') throw e; }
  return { clients: [] };
}
function save(v) {
  fs.mkdirSync(path.dirname(FILE), { recursive: true });
  const tmp = FILE + '.tmp';
  let mode = 0o640;
  try { mode = fs.statSync(FILE).mode & 0o777; } catch (e) { /* file baru */ }
  fs.writeFileSync(tmp, JSON.stringify(v, null, 2) + '\n', { mode });
  try { const st = fs.statSync(FILE); fs.chownSync(tmp, st.uid, st.gid); } catch (e) { /* file baru */ }
  fs.renameSync(tmp, FILE);
}
function usage() {
  console.log('Pemakaian:\n  buat "Nama Aplikasi" [--services skck,crowd_permit]\n  daftar\n  nonaktifkan <app_id>\n  ganti-key <app_id>');
  process.exit(1);
}

const [cmd, ...args] = process.argv.slice(2);
try {
  const db = load();
  if (cmd === 'buat') {
    const name = args.find((a, i) => !a.startsWith('--') && args[i - 1] !== '--services');
    if (!name) usage();
    const i = args.indexOf('--services');
    const services = i >= 0 ? String(args[i + 1] || '').split(',').map(s => s.trim()).filter(Boolean) : ['skck', 'crowd_permit'];
    if (!services.length || services.some(s => !['skck', 'crowd_permit'].includes(s))) { console.error('[GAGAL] --services hanya skck dan/atau crowd_permit'); process.exit(1); }
    const appId = crypto.randomBytes(16).toString('hex');
    const key = newKey();
    db.clients.push({ app_id: appId, name, access_key_sha256: sha256hex(key), services, active: true, created_at: new Date().toISOString() });
    save(db);
    console.log(`\nKlien "${name}" dibuat. Simpan Access-Key sekarang, karena tidak bisa ditampilkan lagi.\n`);
    console.log(`  App-Id     : ${appId}`);
    console.log(`  Access-Key : ${key}`);
    console.log(`  Layanan    : ${services.join(', ')}\n`);
  } else if (cmd === 'daftar') {
    if (!db.clients.length) console.log(`Belum ada klien di ${FILE}`);
    else console.table(db.clients.map(c => ({ app_id: c.app_id, nama: c.name, layanan: (c.services || []).join(','), aktif: c.active !== false })));
  } else if (cmd === 'nonaktifkan' || cmd === 'ganti-key') {
    if (!args[0]) usage();
    const c = db.clients.find(x => x.app_id === args[0]);
    if (!c) { console.log('App-Id tidak ditemukan.'); process.exit(1); }
    if (cmd === 'nonaktifkan') { c.active = false; save(db); console.log('Klien dinonaktifkan.'); }
    else { const key = newKey(); c.access_key_sha256 = sha256hex(key); c.active = true; save(db); console.log(`\nAccess-Key baru (simpan sekarang):\n  ${key}\nKey lama langsung tidak berlaku.\n`); }
  } else usage();
} catch (e) {
  console.error('[GAGAL]', e.code === 'EACCES' ? `Tidak punya izin menulis ${FILE}. Jalankan dengan sudo.` : e.message);
  process.exit(1);
}
