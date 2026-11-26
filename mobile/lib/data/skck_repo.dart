import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'sample.dart';

/// Mengambil VC SKCK dari API lookup admin-be:
///   POST {API_BASE}/api/v1/external/service-applications/lookup
///   body: {"nik": NIK, "services": ["skck"]}
///
/// Konfigurasi lewat --dart-define (tidak disimpan di repo):
///   API_BASE    default http://172.27.169.128/admin-be
///   APP_ID      header App-Id      (kosongkan bila memakai gateway /proxy)
///   ACCESS_KEY  header Access-Key  (kosongkan bila memakai gateway /proxy)
///   NIK         NIK pemohon (wajib; tidak disimpan di repo karena data pribadi)
class SkckRepo {
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://172.27.169.128/admin-be');
  static const appId = String.fromEnvironment('APP_ID');
  static const accessKey = String.fromEnvironment('ACCESS_KEY');
  static const nik = String.fromEnvironment('NIK');

  /// idle | loading | api | fallback
  static final status = ValueNotifier<String>('idle');
  static String message = '';

  static Future<void> load() async {
    if (status.value == 'loading') return;
    status.value = 'loading';
    try {
      if (nik.isEmpty) throw Exception('NIK belum diisi (--dart-define=NIK=...)');
      final uri = Uri.parse('${apiBase.replaceAll(RegExp(r'/+$'), '')}/api/v1/external/service-applications/lookup');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (appId.isNotEmpty) 'App-Id': appId,
        if (accessKey.isNotEmpty) 'Access-Key': accessKey,
      };
      final res = await http
          .post(uri, headers: headers, body: jsonEncode({'nik': nik, 'services': ['skck']}))
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body is! Map || body['data'] is! Map) {
        final msg = body is Map && body['message'] is Map ? (body['message']['description'] ?? '') : '';
        throw Exception('HTTP ${res.statusCode} $msg'.trim());
      }
      final data = body['data'] as Map;
      final user = data['user'] is Map ? data['user'] as Map : null;
      final rows = (data['skck'] is List ? data['skck'] as List : const []).whereType<Map>().toList();
      if (rows.isEmpty) throw Exception('Tidak ada SKCK untuk NIK ini');
      // Utamakan SKCK yang sudah terbit (completed), terbaru lebih dulu.
      rows.sort((a, b) {
        final ca = a['status'] == 'completed' ? 0 : 1, cb = b['status'] == 'completed' ? 0 : 1;
        if (ca != cb) return ca - cb;
        return '${b['submitted_at']}'.compareTo('${a['submitted_at']}');
      });
      final fromApi = rows.map((r) => _toCredential(r, user)).toList();
      credentials
        ..removeWhere((c) => c.kind == CredKind.skck)
        ..insertAll(0, fromApi);
      message = 'Data dari API (NIK ${_mask(nik)})';
      status.value = 'api';
    } catch (e) {
      message = 'Gagal memuat dari API: ${e.toString().replaceFirst('Exception: ', '')}. Menampilkan data contoh.';
      status.value = 'fallback';
    }
  }

  static String _mask(String n) => n.length == 16 ? '${n.substring(0, 6)}••••••${n.substring(12)}' : n;

  static DateTime? _date(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v.length >= 10 ? v.substring(0, 10) : v);
  }

  static Credential _toCredential(Map r, Map? user) {
    final name = '${user?['full_name'] ?? ''}'.toUpperCase();
    final purpose = '${r['purpose'] ?? ''}';
    final classification = '${r['classification'] ?? ''}';
    final validFrom = _date(r['submitted_at']) ?? DateTime.now();
    final validUntil = _date(r['estimated_expires_on']);
    final apiVals = <String, String>{
      'nomor_skck': '${r['registration_number'] ?? ''}',
      'nama_lengkap': name,
      'nik': nik,
      'untuk_keperluan': purpose.toUpperCase(),
      'berlaku_dari_tanggal': '${r['submitted_at'] ?? ''}'.split('T').first,
      if (validUntil != null) 'end_date': '${r['estimated_expires_on']}',
    };
    // Atribut katalog id.idctf.skck.1: yang ada di API diisi dari API, sisanya data contoh.
    final attrs = [
      for (final a in sampleSkck.attributes)
        apiVals.containsKey(a.name) ? Attr(a.name, a.label, a.minimization, apiVals[a.name]!, source: 'api') : a,
    ];
    final vs = r['estimated_validity_status'];
    return Credential(
      id: 'skck-${r['id']}',
      kind: CredKind.skck,
      vct: 'id.idctf.skck.1',
      title: 'Surat Keterangan Catatan Kepolisian',
      subtitle: [classification, purpose].where((s) => s.isNotEmpty).join(' · '),
      number: '${r['registration_number'] ?? '-'}',
      holder: name.isEmpty ? '-' : name,
      issuer: issuerName,
      validFrom: validFrom,
      validUntil: validUntil,
      attributes: attrs,
      validityOverride: vs is String && vs.isNotEmpty && vs != 'active' ? 'expired' : null,
      applicationStatus: '${r['status'] ?? ''}',
      fromApi: true,
    );
  }
}
