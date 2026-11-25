#!/usr/bin/env node
// Buat / kelola klien API (App-Id + Access-Key).
//
//   node api/create-client.js buat "Nama Aplikasi" [--services skck,crowd_permit]
//   node api/create-client.js daftar
//   node api/create-client.js nonaktifkan <app_id>
//   node api/create-client.js ganti-key <app_id>
//
// Access-Key hanya ditampilkan SEKALI. Database hanya menyimpan hash SHA-256-nya.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Client } = require('pg');

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
if (!env.DATABASE_URL) { console.error('[GAGAL] DATABASE_URL belum diisi.'); process.exit(1); }

const sha256 = s => crypto.createHash('sha256').update(s, 'utf8').digest();
const newKey = () => crypto.randomBytes(32).toString('hex');
const [cmd, ...args] = process.argv.slice(2);

function usage() {
  console.log('Pemakaian:\n  buat "Nama Aplikasi" [--services skck,crowd_permit]\n  daftar\n  nonaktifkan <app_id>\n  ganti-key <app_id>');
  process.exit(1);
}

(async () => {
  const db = new Client({ connectionString: env.DATABASE_URL });
  await db.connect();
  try {
    if (cmd === 'buat') {
      const name = args.find(a => !a.startsWith('--'));
      if (!name) usage();
      const i = args.indexOf('--services');
      const services = i >= 0 ? String(args[i + 1] || '').split(',').map(s => s.trim()).filter(Boolean) : ['skck', 'crowd_permit'];
      if (!services.length || services.some(s => !['skck', 'crowd_permit'].includes(s))) { console.error('[GAGAL] --services hanya skck dan/atau crowd_permit'); process.exit(1); }
      const appId = crypto.randomBytes(16).toString('hex');
      const key = newKey();
      await db.query('INSERT INTO layanan.api_client (app_id, name, access_key_hash, allowed_services) VALUES ($1, $2, $3, $4)', [appId, name, sha256(key), services]);
      console.log(`\nKlien "${name}" dibuat. Simpan Access-Key sekarang, karena tidak bisa ditampilkan lagi.\n`);
      console.log(`  App-Id     : ${appId}`);
      console.log(`  Access-Key : ${key}`);
      console.log(`  Layanan    : ${services.join(', ')}\n`);
    } else if (cmd === 'daftar') {
      const r = await db.query("SELECT app_id, name, array_to_string(allowed_services, ',') AS layanan, active, to_char(last_used_at, 'YYYY-MM-DD HH24:MI') AS terakhir FROM layanan.api_client ORDER BY created_at");
      if (!r.rows.length) console.log('Belum ada klien.');
      else console.table(r.rows);
    } else if (cmd === 'nonaktifkan') {
      if (!args[0]) usage();
      const r = await db.query('UPDATE layanan.api_client SET active = false WHERE app_id = $1', [args[0]]);
      console.log(r.rowCount ? 'Klien dinonaktifkan.' : 'App-Id tidak ditemukan.');
    } else if (cmd === 'ganti-key') {
      if (!args[0]) usage();
      const key = newKey();
      const r = await db.query('UPDATE layanan.api_client SET access_key_hash = $2, active = true WHERE app_id = $1', [args[0], sha256(key)]);
      if (!r.rowCount) console.log('App-Id tidak ditemukan.');
      else console.log(`\nAccess-Key baru (simpan sekarang):\n  ${key}\nKey lama langsung tidak berlaku.\n`);
    } else usage();
  } finally {
    await db.end();
  }
})().catch(e => { console.error('[GAGAL]', e.message); process.exit(1); });
