// Salin file ini menjadi `variables.dart` (folder yang sama), lalu isi nilainya.
// `variables.dart` tidak ikut ter-commit (.gitignore) karena berisi kredensial.
// Jangan isi nilai asli di file contoh ini: repo publik.

class Variables {
  // API lookup admin-be: GET {apiBase}/api/v1/external/service-applications/lookup/{nik}
  static const apiBase = 'http://172.27.169.128/admin-be';
  static const appId = '';
  static const accessKey = '';

  // NIK pemohon yang SKCK-nya ditampilkan sebagai VC
  static const nik = '';

  // Issuance API (token client_credentials + offers)
  static const issuerApi = 'https://issuer.polri.go.id';
  static const issuerTokenUrl = '$issuerApi/api/v1/token';
  static const clientId = '';
  static const clientSecret = '';

  // subject_ref untuk POST /api/v1/offers. Kosong = memakai nik.
  static const subjectRef = '';
}
