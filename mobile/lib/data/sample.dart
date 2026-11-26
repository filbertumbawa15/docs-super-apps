// Data contoh untuk demo. Semua nama dan nomor fiktif.
// Atribut SKCK mengikuti katalog id.idctf.skck.1 (SD-JWT VC).

class Attr {
  final String name;
  final String label;
  final String minimization; // open | normal | restricted
  final String value;
  final String source; // api | demo
  const Attr(this.name, this.label, this.minimization, this.value, {this.source = 'demo'});
}

enum CredKind { skck, izinKeramaian }

class Credential {
  final String id;
  final CredKind kind;
  final String vct;
  final String title;
  final String subtitle;
  final String number;
  final String holder;
  final String issuer;
  final DateTime validFrom;
  final DateTime? validUntil;
  final List<Attr> attributes;
  final String? validityOverride; // mis. 'expired' dari estimated_validity_status
  final String applicationStatus;
  final bool fromApi;

  const Credential({
    required this.id,
    required this.kind,
    required this.vct,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.holder,
    required this.issuer,
    required this.validFrom,
    required this.validUntil,
    required this.attributes,
    this.validityOverride,
    this.applicationStatus = 'completed',
    this.fromApi = false,
  });

  int? get daysRemaining {
    if (validUntil == null) return null;
    final today = DateTime.now();
    final d = DateTime(validUntil!.year, validUntil!.month, validUntil!.day);
    return d.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  /// active | soon | expired
  String get validity {
    if (validityOverride != null) return validityOverride!;
    final d = daysRemaining;
    if (d == null) return 'active';
    if (d < 0) return 'expired';
    if (d <= 30) return 'soon';
    return 'active';
  }
}

class Citizen {
  final String name;
  final String nik;
  const Citizen(this.name, this.nik);

  String get firstName => name.split(' ').first;
  String get initials => name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();
  String get maskedNik => nik.length == 16 ? '${nik.substring(0, 6)}••••••${nik.substring(12)}' : nik;
}

const citizen = Citizen('Denice', '0000000026112501');
const profilePhoto = 'assets/profile/foto.jpg';
const issuerName = 'Kepolisian Negara Republik Indonesia';

/// Daftar kredensial di dompet. SKCK diganti data API saat SkckRepo.load() berhasil.
final credentials = <Credential>[sampleSkck, sampleIzin];

final sampleSkck = Credential(
    id: 'skck-01M88FSD82AZ6FCJ97N58C8CNV',
    kind: CredKind.skck,
    vct: 'id.idctf.skck.1',
    title: 'Surat Keterangan Catatan Kepolisian',
    subtitle: 'LUAR NEGERI · Studi di luar negeri',
    number: 'SKCK-2026-0912502',
    holder: 'DENICE',
    issuer: issuerName,
    validFrom: DateTime(2026, 11, 23),
    validUntil: DateTime(2027, 5, 25),
    attributes: const [
      Attr('nomor_skck', 'Nomor SKCK', 'open', 'SKCK-2026-0912502'),
      Attr('nama_lengkap', 'Nama Lengkap', 'normal', 'DENICE'),
      Attr('jenis_kelamin', 'Jenis Kelamin', 'normal', 'LAKI-LAKI'),
      Attr('kebangsaan', 'Kebangsaan', 'normal', 'INDONESIA'),
      Attr('agama', 'Agama', 'normal', 'ISLAM'),
      Attr('tempat_dan_tanggal_lahir', 'Tempat dan Tanggal Lahir', 'normal', 'JAKARTA, 14-03-1998'),
      Attr('tempat_tinggal_sekarang', 'Tempat Tinggal Sekarang', 'normal', 'JL. MELATI NO. 12, RT 003/RW 005, KEBAYORAN BARU, JAKARTA SELATAN'),
      Attr('pekerjaan', 'Pekerjaan', 'normal', 'PELAJAR/MAHASISWA'),
      Attr('nik', 'NIK', 'normal', '0000000026112501'),
      Attr('nomer_paspor', 'Nomor Paspor', 'normal', 'X1234567'),
      Attr('catatan_kepolisian', 'Catatan Kepolisian', 'normal', 'TIDAK MEMILIKI CATATAN ATAU KETERLIBATAN DALAM KEGIATAN KRIMINAL APAPUN'),
      Attr('sejak_di_indonesia', 'Sejak di Indonesia', 'normal', 'SEJAK LAHIR'),
      Attr('sampai_dengan', 'Sampai Dengan', 'normal', 'SEKARANG'),
      Attr('untuk_keperluan', 'Untuk Keperluan', 'normal', 'STUDI DI LUAR NEGERI'),
      Attr('berlaku_dari_tanggal', 'Berlaku dari Tanggal', 'normal', '2026-11-23'),
      Attr('end_date', 'Berlaku sampai Tanggal', 'normal', '2027-05-25'),
      Attr('foto', 'Foto', 'restricted', '(foto pemegang)'),
    ],
  );

final sampleIzin = Credential(
    id: 'ik-73',
    kind: CredKind.izinKeramaian,
    vct: 'id.idctf.izin-keramaian.1',
    title: 'Izin Keramaian',
    subtitle: 'Pertemuan · Pertemuan warga RW 05',
    number: 'IK-2026-000073',
    holder: 'DENICE',
    issuer: issuerName,
    validFrom: DateTime(2026, 11, 23),
    validUntil: DateTime(2026, 12, 6),
    attributes: const [
      Attr('nomor_izin', 'Nomor Izin', 'open', 'IK-2026-000073'),
      Attr('nama_penanggung_jawab', 'Penanggung Jawab', 'normal', 'DENICE'),
      Attr('nama_kegiatan', 'Nama Kegiatan', 'normal', 'PERTEMUAN WARGA RW 05'),
      Attr('jenis_kegiatan', 'Jenis Kegiatan', 'normal', 'PERTEMUAN'),
      Attr('tanggal_peninjauan', 'Tanggal Peninjauan', 'normal', '2026-11-26'),
      Attr('status', 'Status', 'open', 'JADWAL DIKONFIRMASI'),
    ],
  );

class Service {
  final String name;
  final String desc;
  final String icon; // nama ikon Material
  final bool live;
  const Service(this.name, this.desc, this.icon, {this.live = false});
}

const services = <Service>[
  Service('SKCK', 'Ajukan dan cek status', 'description', live: true),
  Service('Izin Keramaian', 'Izin kegiatan masyarakat', 'groups', live: true),
  Service('SIM', 'Buat dan perpanjang', 'badge'),
  Service('Kendaraan', 'STNK, BPKB, pajak', 'directions_car'),
  Service('Kehilangan', 'Surat tanda lapor', 'search'),
  Service('Pengaduan', 'Sampaikan laporan', 'forum'),
  Service('SP2HP', 'Perkembangan perkara', 'fact_check'),
  Service('Darurat 110', 'Panggilan darurat', 'emergency', live: true),
];

class Activity {
  final String title;
  final String time;
  final String icon;
  const Activity(this.title, this.time, this.icon);
}

const activities = <Activity>[
  Activity('Kredensial SKCK diterima di dompet', '23 Nov 2026, 11.40', 'wallet'),
  Activity('SKCK SKCK-2026-0912502 selesai diproses', '23 Nov 2026, 11.34', 'check_circle'),
  Activity('Jadwal peninjauan izin keramaian dikonfirmasi', '23 Nov 2026, 08.10', 'event_available'),
];
