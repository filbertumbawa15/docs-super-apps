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
flutter run            # ke HP/emulator
flutter build apk      # hasil: build/app/outputs/flutter-apk/app-release.apk
```
Folder `android/` sengaja tidak di-commit; dibuat oleh `flutter create`.

## Foto profil
Taruh foto di `assets/profile/foto.jpg` sebelum `flutter run`. Folder ini sengaja tidak di-commit
karena repo publik. Tanpa foto, avatar menampilkan inisial nama.
