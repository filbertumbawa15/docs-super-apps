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

## Konfigurasi: `lib/config/variables.dart`

Semua alamat API dan kredensial ada di `lib/config/variables.dart`. File ini **tidak** ikut
ter-commit (repo publik). Buat dari contoh lalu isi nilainya:

```powershell
Copy-Item lib\config\variables.example.dart lib\config\variables.dart
flutter run
```

| Variabel | Untuk |
|---|---|
| `apiBase`, `appId`, `accessKey` | `GET {apiBase}/api/v1/external/service-applications/lookup/{nik}` |
| `nik` | NIK pemohon yang SKCK-nya ditampilkan |
| `issuerApi`, `issuerTokenUrl`, `clientId`, `clientSecret` | token Issuance API (`client_credentials`) |
| `subjectRef` | `subject_ref` pada `POST /api/v1/offers` (kosong = `nik`) |

- HP harus bisa menjangkau host API (GlobalProtect aktif di HP).
- `android/app/src/main/AndroidManifest.xml` perlu izin internet dan `http://`:
  `<uses-permission android:name="android.permission.INTERNET"/>` di dalam `<manifest>`,
  dan `android:usesCleartextTraffic="true"` pada tag `<application>`.
- Bila API gagal dijangkau, aplikasi menampilkan data contoh dengan keterangan di layar.

## Logo
Satu path untuk semua logo di aplikasi: `assets/logo/polri.png` (splash, kartu VC, poster).
Ikon aplikasi dibuat dari `assets/logo/app_icon.png` dan `app_icon_foreground.png`.

## Token Issuance API
Saat aplikasi dibuka, aplikasi meminta token (`POST {issuerTokenUrl}`, form-urlencoded,
`grant_type=client_credentials`) dan menyimpan `access_token`. Status: Profil → Token Issuer.

## QR VC SKCK dari Issuer
Tombol "Bagikan untuk verifikasi" membuat penawaran dan menampilkan QR dari Issuance API:
1. `POST {ISSUER_API}/api/v1/offers` (Bearer `access_token`) dengan
   `{"credential_type":"id.idctf.skck.4","subject_ref": SUBJECT_REF,"expires_in":600}` → `offer_id`
2. `GET {ISSUER_API}/api/v1/offers/{offer_id}/qr.png` (Bearer) → gambar QR
3. `GET {ISSUER_API}/api/v1/offers/{offer_id}` tiap 4 detik → status (diambil / kedaluwarsa / dibatalkan)

Bila token ditolak (401), token diminta ulang sekali. `tx_code` (bila dikembalikan) ditampilkan
di bawah QR karena wallet memintanya setelah QR dipindai.
