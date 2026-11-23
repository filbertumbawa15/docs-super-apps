# Docs Super Apps — API Lookup Layanan

Dokumentasi API lookup pengajuan SKCK dan Izin Keramaian, bergaya Bootstrap Docs.

- `index.html` — dokumentasi endpoint `POST /api/v1/external/service-applications/lookup`
- `data.html` — halaman contoh untuk menampilkan data dari endpoint (tabel, badge status, detail, paginasi)
- `assets/` — Bootstrap 5.3.3, CSS dan JS halaman

Cukup buka `index.html` di browser, atau sajikan folder ini dari web server statis.

Catatan: tombol "Cari ke API" di `data.html` memanggil API langsung dari browser, jadi server API harus mengizinkan CORS. Untuk produksi, panggil API lewat backend agar Access-Key tidak terlihat di browser.
