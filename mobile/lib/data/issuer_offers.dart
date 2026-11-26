import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/variables.dart';
import 'issuer_auth.dart';
import 'skck_repo.dart';

/// Penawaran kredensial (OpenID4VCI) di Issuance API.
///   POST {ISSUER_API}/api/v1/offers                 (Bearer access_token)
///        {"credential_type":"id.idctf.skck.3","subject_ref":SUBJECT_REF,"expires_in":600}
///   GET  {ISSUER_API}/api/v1/offers/{offer_id}/qr.png (Bearer access_token)
///   GET  {ISSUER_API}/api/v1/offers/{offer_id}        (status: used / expired / invalidated)
///
/// Dari lib/config/variables.dart: issuerApi, subjectRef (kosong = memakai nik).
class IssuerOffers {
  static const apiBase = Variables.issuerApi;
  static const _subjectRefEnv = Variables.subjectRef;
  static const credentialType = 'id.idctf.skck.3';

  static String get subjectRef => _subjectRefEnv.isNotEmpty ? _subjectRefEnv : SkckRepo.nik;
  static String get _base => apiBase.replaceAll(RegExp(r'/+$'), '');

  /// Jalankan request ber-Bearer; bila 401 (token habis/diganti), minta token baru sekali lalu ulangi.
  static Future<http.Response> _authed(Future<http.Response> Function(String token) call) async {
    var token = await IssuerAuth.fetch();
    if (token == null) throw Exception(IssuerAuth.message);
    var res = await call(token).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401) {
      token = await IssuerAuth.fetch(force: true);
      if (token == null) throw Exception(IssuerAuth.message);
      res = await call(token).timeout(const Duration(seconds: 20));
    }
    return res;
  }

  static String _err(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map && d['error'] != null) return 'HTTP ${r.statusCode}: ${d['error']}';
    } catch (_) {}
    return 'HTTP ${r.statusCode}';
  }

  static Future<OfferInfo> create({int expiresIn = 600}) async {
    if (subjectRef.isEmpty) throw Exception('subjectRef / nik belum diisi di lib/config/variables.dart');
    final res = await _authed((t) => http.post(
          Uri.parse('$_base/api/v1/offers'),
          headers: {'Authorization': 'Bearer $t', 'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'credential_type': credentialType, 'subject_ref': subjectRef, 'expires_in': expiresIn}),
        ));
    if (res.statusCode != 201 && res.statusCode != 200) {
      debugPrint('[IssuerOffers] POST offers ${res.statusCode}: ${res.body}');
      throw Exception(_err(res));
    }
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    final info = OfferInfo.fromJson(d);
    debugPrint('[IssuerOffers] offer_id=${info.id} expires_at=${info.expiresAt}');
    return info;
  }

  static Future<Uint8List> qrPng(String offerId) async {
    final res = await _authed((t) => http.get(
          Uri.parse('$_base/api/v1/offers/${Uri.encodeComponent(offerId)}/qr.png'),
          headers: {'Authorization': 'Bearer $t', 'Accept': 'image/png'},
        ));
    if (res.statusCode != 200) {
      debugPrint('[IssuerOffers] GET qr.png ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
      throw Exception(res.statusCode == 410 ? 'QR sudah tidak berlaku (dipakai, kedaluwarsa, atau dibatalkan)' : _err(res));
    }
    return res.bodyBytes;
  }

  static Future<OfferInfo> status(String offerId) async {
    final res = await _authed((t) => http.get(
          Uri.parse('$_base/api/v1/offers/${Uri.encodeComponent(offerId)}'),
          headers: {'Authorization': 'Bearer $t', 'Accept': 'application/json'},
        ));
    if (res.statusCode != 200) throw Exception(_err(res));
    return OfferInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}

class OfferInfo {
  final String id;
  final String? txCode;
  final DateTime? expiresAt;
  final bool used;
  final bool expired;
  final bool invalidated;

  const OfferInfo({required this.id, this.txCode, this.expiresAt, this.used = false, this.expired = false, this.invalidated = false});

  factory OfferInfo.fromJson(Map<String, dynamic> d) => OfferInfo(
        id: '${d['offer_id'] ?? ''}',
        txCode: d['tx_code'] is String ? d['tx_code'] as String : null,
        expiresAt: d['expires_at'] is String ? DateTime.tryParse(d['expires_at'] as String)?.toLocal() : null,
        used: d['used'] == true,
        expired: d['expired'] == true,
        invalidated: d['invalidated'] == true,
      );

  /// waiting | used | expired | invalidated
  String get state => invalidated ? 'invalidated' : (used ? 'used' : (expired ? 'expired' : 'waiting'));
}
