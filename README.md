# Docs Super Apps — API Lookup Layanan

Dokumentasi API lookup pengajuan SKCK dan Izin Keramaian, bergaya Bootstrap Docs.

- `index.html` — dokumentasi endpoint `POST /api/v1/external/service-applications/lookup`
- `data.html` — halaman untuk menampilkan data dari endpoint (tabel, badge status, detail, paginasi)
- `assets/` — Bootstrap 5.3.3, CSS dan JS halaman
- `deploy/install-docs.sh` — script instalasi ke VPS (Nginx, port 8075)

## Instalasi di VPS

```bash
curl -fsSLO https://raw.githubusercontent.com/filbertumbawa15/docs-super-apps/main/deploy/install-docs.sh
sudo bash install-docs.sh
```

Saat pertama kali dijalankan, script menanyakan Host API, App-Id, Access-Key, dan login halaman,
lalu menyimpannya di `/etc/docs-super-apps/docs.env` (hanya bisa dibaca root). Dari ENV itu script
membuat `assets/config.js`, sehingga `data.html` langsung terhubung tanpa mengisi form.

- Perbarui setelah ada push baru: `sudo bash install-docs.sh`
- Ganti host, key, atau login: `sudo bash install-docs.sh --reconfig`

Lihat `.env.example` untuk format ENV.

## Catatan

- API hanya bisa diakses lewat **GlobalProtect**. Browser pengguna harus tersambung VPN saat menekan "Cari ke API".
- Server API harus mengizinkan **CORS** dari origin halaman ini (mis. `http://IP-VPS:8075`).
- Access-Key ikut terkirim ke browser. Aktifkan login halaman (ditanyakan oleh script) agar hanya tim yang bisa membukanya.
