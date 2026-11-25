# Docs Super Apps — API Lookup Layanan

Dokumentasi API lookup pengajuan SKCK dan Izin Keramaian, bergaya Bootstrap Docs.

- `portal.html` — portal layanan Polri (pola Super Apps), pintu masuk ke semua halaman
- `index.html` — dokumentasi endpoint `POST /api/v1/external/service-applications/lookup`
- `data.html` — halaman untuk menampilkan data dari endpoint (tabel, badge status, detail, paginasi)
- `assets/` — Bootstrap 5.3.3, CSS dan JS halaman
- `deploy/install-docs.sh` — script instalasi ke VPS (Nginx, 127.0.0.1:5173 + SSH tunnel)

## Jalankan di localhost (disarankan, tanpa masalah CORS)

Butuh Node.js 18+ dan GlobalProtect aktif di laptop. Server lokal menyajikan docs dan
meneruskan pencarian ke API, sehingga browser tidak terkena CORS dan Access-Key tidak dikirim ke browser.

```bash
git clone https://github.com/filbertumbawa15/docs-super-apps.git
cd docs-super-apps

# macOS / Linux
bash deploy/local/start-local.sh          # pertama kali: mengisi .env
bash deploy/local/start-local.sh --reconfig   # ganti host / key / port

# Windows: klik dua kali deploy\local\start-local.bat
```

Buka http://localhost:5173/portal.html. Konfigurasi ada di file `.env` di root repo
(format: `deploy/local/.env.example`).

## Instalasi di VPS

```bash
curl -fsSLO https://raw.githubusercontent.com/filbertumbawa15/docs-super-apps/main/deploy/install-docs.sh
sudo bash install-docs.sh
```

Saat pertama kali dijalankan, script menanyakan Host API, App-Id, Access-Key, dan login halaman,
lalu menyimpannya di `/etc/docs-super-apps/docs.env` (hanya bisa dibaca root). Dari ENV itu script
membuat `assets/config.js`, sehingga `data.html` langsung terhubung tanpa mengisi form.

Secara default situs hanya terbuka di `127.0.0.1:5173` di VPS. Buka dari laptop lewat SSH tunnel:

```bash
ssh -N -L 5173:127.0.0.1:5173 ubuntu@IP-VPS
# lalu buka http://localhost:5173/data.html
```

Origin di browser menjadi `http://localhost:5173`. Untuk membuka ke publik: `sudo BIND=0.0.0.0 bash install-docs.sh`.

- Perbarui setelah ada push baru: `sudo bash install-docs.sh`
- Ganti host, key, atau login: `sudo bash install-docs.sh --reconfig`

Lihat `.env.example` untuk format ENV.

## Logo

Taruh file logo resmi di `assets/logo-polri.png` (disarankan PNG transparan, tinggi minimal 72 px), lalu commit.
Jika file tidak ada, navbar menampilkan tanda teks "SKCK".

## Catatan

- API hanya bisa diakses lewat **GlobalProtect**. Browser pengguna harus tersambung VPN saat menekan "Cari ke API".
- Server API harus mengizinkan **CORS** dari origin halaman ini (mis. `http://IP-VPS:5173`).
- Access-Key ikut terkirim ke browser. Aktifkan login halaman (ditanyakan oleh script) agar hanya tim yang bisa membukanya.
