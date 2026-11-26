import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/variables.dart';

/// Token Issuance API (OAuth 2.0 client_credentials).
///   POST {ISSUER_TOKEN_URL}
///   Content-Type: application/x-www-form-urlencoded
///   grant_type=client_credentials&client_id=...&client_secret=...
/// Jawaban: {"access_token": "...", "token_type": "Bearer", "expires_in": 900}
///
/// Nilai dari lib/config/variables.dart (tidak disimpan di repo):
///   issuerTokenUrl, clientId, clientSecret
class IssuerAuth {
  static const tokenUrl = Variables.issuerTokenUrl;
  static const clientId = Variables.clientId;
  static const clientSecret = Variables.clientSecret;

  static String? accessToken;
  static DateTime? expiresAt;

  /// idle | loading | ok | error
  static final status = ValueNotifier<String>('idle');
  static String message = '';

  static bool get valid => accessToken != null && expiresAt != null && DateTime.now().isBefore(expiresAt!);

  /// Ambil token; memakai token yang tersimpan bila masih berlaku (sisa > 30 detik).
  static Future<String?> fetch({bool force = false}) async {
    if (!force && valid && expiresAt!.difference(DateTime.now()).inSeconds > 30) return accessToken;
    if (status.value == 'loading') return accessToken;
    status.value = 'loading';
    try {
      if (clientId.isEmpty || clientSecret.isEmpty) {
        throw Exception('clientId / clientSecret belum diisi di lib/config/variables.dart');
      }
      final res = await http
          .post(
            Uri.parse(tokenUrl),
            headers: const {'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json'},
            body: {'grant_type': 'client_credentials', 'client_id': clientId, 'client_secret': clientSecret},
          )
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic>? body;
      try {
        final d = jsonDecode(res.body);
        if (d is Map<String, dynamic>) body = d;
      } catch (_) {}
      if (res.statusCode != 200 || body == null || body['access_token'] is! String) {
        final err = body?['error'] ?? '';
        throw Exception('HTTP ${res.statusCode} $err'.trim());
      }
      accessToken = body['access_token'] as String;
      final exp = body['expires_in'] is num ? (body['expires_in'] as num).toInt() : 900;
      expiresAt = DateTime.now().add(Duration(seconds: exp));
      message = 'Token issuer aktif, berlaku ${exp ~/ 60} menit';
      debugPrint('[IssuerAuth] access_token diterima (${masked()}), expires_in=$exp');
      status.value = 'ok';
      return accessToken;
    } catch (e) {
      message = 'Gagal mengambil token issuer: ${e.toString().replaceFirst('Exception: ', '')}';
      debugPrint('[IssuerAuth] $message');
      status.value = 'error';
      return null;
    }
  }

  /// Token disamarkan untuk ditampilkan: 6 karakter awal + 4 akhir.
  static String masked() {
    final t = accessToken;
    if (t == null || t.length < 12) return '-';
    return '${t.substring(0, 6)}…${t.substring(t.length - 4)}';
  }
}
