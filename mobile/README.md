# Super Apps Polri (Demo) – Flutter Android

Demo aplikasi: Splash → Onboarding (3 slide, sekali saja) → Dashboard (tanpa login),
dengan Dompet Kredensial, detail VC SKCK (17 atribut katalog `id.idctf.skck.1`),
dan berbagi data seperlunya lewat QR. Semua data fiktif dan tersimpan di aplikasi.

## Unduh APK
Setiap push ke `mobile/` membangun APK lewat GitHub Actions:
tab **Actions** → *Build APK (mobile demo)* → run terbaru → **Artifacts** → `super-apps-polri-demo-apk`.

## Build sendiri (butuh Flutter + Android SDK)
```bash
cd mobile
flutter create --platforms=android --org id.polri.demo --project-name super_apps_polri_demo .
rm -rf test
flutter pub get
dart run flutter_launcher_icons   # ikon aplikasi dari logo Polri
dart run flutter_native_splash:create   # latar biru tua saat aplikasi dibuka
flutter run            # ke HP/emulator
flutter build apk      # hasil: build/app/outputs/flutter-apk/app-release.apk
```
Folder `android/` sengaja tidak di-commit; dibuat oleh `flutter create`.

## Foto profil
Taruh foto di `assets/profile/foto.jpg` sebelum `flutter run`. Folder ini sengaja tidak di-commit
karena repo publik. Tanpa foto, avatar menampilkan inisial nama.

## Data VC SKCK dari API

Saat dashboard dibuka, aplikasi memanggil `POST {API_BASE}/api/v1/external/service-applications/lookup`
dengan body `{"nik": NIK, "services": ["skck"]}`. NIK, App-Id, dan Access-Key **tidak** disimpan
di repo (repo publik); berikan saat menjalankan:

Cara termudah: salin `.env.example` menjadi `.env`, isi nilainya, lalu:

```powershell
flutter run --dart-define-from-file=.env
```

Di VS Code, konfigurasi "Super Apps Polri (Demo) + .env" (F5) sudah memakai file ini.
Bisa juga satu per satu: `--dart-define=NIK=... --dart-define=APP_ID=... --dart-define=ACCESS_KEY=...`.

- HP harus bisa menjangkau host API (GlobalProtect aktif di HP).
- `android/app/src/main/AndroidManifest.xml` perlu izin internet dan `http://`:
  tambahkan `<uses-permission android:name="android.permission.INTERNET"/>` di dalam `<manifest>`,
  dan `android:usesCleartextTraffic="true"` pada tag `<application>`.
- Bila API gagal dijangkau, aplikasi menampilkan data contoh dengan keterangan di layar.
- Atribut yang tidak ada di API (agama, alamat, dll.) tetap data contoh, ditandai "contoh".

## Logo
Satu path untuk semua logo di aplikasi: `assets/logo/polri.png` (splash, kartu VC, poster).
Ikon aplikasi dibuat dari `assets/logo/app_icon.png` dan `app_icon_foreground.png`.

## Token Issuance API
Saat aplikasi dibuka, aplikasi meminta token: `POST {ISSUER_TOKEN_URL}` (form-urlencoded,
`grant_type=client_credentials`, `client_id`, `client_secret` dari `.env`) dan menyimpan
`access_token` (berlaku `expires_in` detik). Status token terlihat di Profil → Token Issuer.
