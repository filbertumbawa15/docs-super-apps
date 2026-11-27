import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/variables.dart';
import 'sample.dart';

/// Mengambil VC SKCK dari API lookup admin-be:
///   GET {API_BASE}/api/v1/external/service-applications/lookup/{NIK}
///
/// Konfigurasi di lib/config/variables.dart (tidak disimpan di repo):
///   apiBase, appId, accessKey (kosongkan keduanya bila memakai gateway /proxy), nik
class SkckRepo {
  static const apiBase = Variables.apiBase;
  static const appId = Variables.appId;
  static const accessKey = Variables.accessKey;
  static const nik = Variables.nik;

  /// idle | loading | api | fallback
  static final status = ValueNotifier<String>('idle');
  static String message = '';

  static Future<void> load() async {
    if (status.value == 'loading') return;
    status.value = 'loading';
    try {
      if (nik.isEmpty) throw Exception('nik belum diisi di lib/config/variables.dart');
      final uri = Uri.parse('${apiBase.replaceAll(RegExp(r'/+$'), '')}/api/v1/external/service-applications/lookup/${Uri.encodeComponent(nik)}');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (appId.isNotEmpty) 'App-Id': appId,
        if (accessKey.isNotEmpty) 'Access-Key': accessKey,
      };
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
      // Selalu catat respons agar mudah dicek di terminal flutter run.
      debugPrint('[SkckRepo] ${res.statusCode} GET $uri -> ${res.body.length > 1500 ? '${res.body.substring(0, 1500)}...' : res.body}');
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = body is Map && body['message'] is Map ? (body['message']['description'] ?? body['message']['title'] ?? '') : '';
        throw Exception('HTTP ${res.statusCode} ${uri.path}${msg.toString().isNotEmpty ? ' - $msg' : ''}');
      }
      if (body == null) throw Exception('HTTP ${res.statusCode}, tetapi isi respons bukan JSON');

      // Bentuk respons yang diterima:
      //   {data: {user, skck: [..] | {..}}}  |  {data: [..]}  |  {data: {..baris skck..}}  |  {user, skck}
      final dynamic data = body is Map && body.containsKey('data') ? body['data'] : body;
      Map? user;
      dynamic skckRaw;
      if (data is List) {
        skckRaw = data;
      } else if (data is Map) {
        user = data['user'] is Map ? data['user'] as Map : null;
        skckRaw = data['skck'] ?? data['skck_applications'] ?? data['applications'] ?? data['items'];
        if (skckRaw == null && data.containsKey('registration_number')) skckRaw = data;
      } else {
        throw Exception('HTTP ${res.statusCode}, field "data" kosong atau tidak dikenali');
      }
      final rows = <Map>[
        if (skckRaw is List) ...skckRaw.whereType<Map>(),
        if (skckRaw is Map) skckRaw,
      ];
      if (rows.isEmpty) {
        final keys = data is Map ? data.keys.join(', ') : 'list kosong';
        throw Exception(user != null
            ? 'Tidak ada SKCK untuk NIK ini (pengguna: ${user['full_name'] ?? '-'})'
            : 'Data SKCK tidak ditemukan di respons (isi data: $keys)');
      }
      // Nama pemegang: dari data.user, atau dari baris SKCK bila tersedia.
      user ??= rows.first['user'] is Map ? rows.first['user'] as Map : {'full_name': rows.first['full_name'] ?? rows.first['name'] ?? ''};
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
    } catch (e, st) {
      debugPrint('[SkckRepo] gagal: $e\n$st');
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
      vct: 'id.idctf.skck.4',
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
