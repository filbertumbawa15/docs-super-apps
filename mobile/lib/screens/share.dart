import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/issuer_offers.dart';
import '../data/sample.dart';
import '../widgets/dark.dart';
import 'dashboard.dart' show DashColors, poppins;

/// "Tunjukkan ke petugas".
/// SKCK: QR penawaran kredensial dari Issuance API (POST /offers -> GET /offers/{id}/qr.png).
/// Kredensial lain: QR ringkasan lokal (demo).
class ShareScreen extends StatefulWidget {
  final Credential cred;
  const ShareScreen({super.key, required this.cred});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  // loading | ready | error
  String _phase = 'loading';
  String _error = '';
  OfferInfo? _offer;
  Uint8List? _qr;
  Timer? _tick;
  Timer? _poll;
  Duration _left = Duration.zero;

  bool get _isSkck => widget.cred.kind == CredKind.skck;

  @override
  void initState() {
    super.initState();
    if (_isSkck) _createOffer();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _createOffer() async {
    _tick?.cancel();
    _poll?.cancel();
    setState(() {
      _phase = 'loading';
      _error = '';
      _offer = null;
      _qr = null;
    });
    try {
      final offer = await IssuerOffers.create(expiresIn: 600);
      final png = await IssuerOffers.qrPng(offer.id);
      if (!mounted) return;
      setState(() {
        _offer = offer;
        _qr = png;
        _phase = 'ready';
      });
      _startTimers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = 'error';
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startTimers() {
    void updateLeft() {
      final exp = _offer?.expiresAt;
      setState(() => _left = exp == null ? Duration.zero : exp.difference(DateTime.now()));
      if (exp != null && _left.isNegative && _offer!.state == 'waiting') {
        _tick?.cancel();
        _poll?.cancel();
        setState(() => _offer = OfferInfo(id: _offer!.id, txCode: _offer!.txCode, expiresAt: exp, expired: true));
      }
    }

    updateLeft();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => updateLeft());
    // Cek status penawaran tiap 4 detik selama QR ditampilkan.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      final id = _offer?.id;
      if (id == null) return;
      try {
        final s = await IssuerOffers.status(id);
        if (!mounted) return;
        if (s.state != 'waiting') {
          _tick?.cancel();
          _poll?.cancel();
          setState(() => _offer = OfferInfo(id: s.id, txCode: _offer?.txCode, expiresAt: s.expiresAt, used: s.used, expired: s.expired, invalidated: s.invalidated));
        }
      } catch (_) {/* abaikan; coba lagi di putaran berikutnya */}
    });
  }

  @override
  Widget build(BuildContext context) {
    final finalState = _offer != null && _offer!.state != 'waiting';
    return DarkPage(
      title: 'Tunjukkan ke petugas',
      bottom: _isSkck && (_phase == 'error' || finalState)
          ? GoldButton(label: 'Buat QR baru', icon: Icons.refresh, onPressed: _createOffer)
          : null,
      body: _isSkck ? _offerView() : _localView(),
    );
  }

  // ---------------------------------------------------------------- SKCK (Issuer)
  Widget _offerView() {
    final cred = widget.cred;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: DashColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashColors.border, width: 2),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(10),
                  child: _qrContent(),
                ),
              ),
              const SizedBox(height: 14),
              _statusLine(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const HolderPhoto(width: 44, height: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cred.holder, style: poppins(15, weight: FontWeight.w700)),
                        Text(cred.number, style: poppins(12, color: DashColors.goldSoft)),
                      ],
                    ),
                  ),
                  DarkStatus(cred.validity),
                ],
              ),
            ],
          ),
        ),
        if (_phase == 'ready' && _offer?.txCode != null && _offer!.state == 'waiting') ...[
          const SizedBox(height: 16),
          GoldPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kode transaksi', style: poppins(13, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_offer!.txCode!.split('').join(' '),
                    style: poppins(28, weight: FontWeight.w700, color: DashColors.gold).copyWith(letterSpacing: 2)),
                const SizedBox(height: 6),
                Text('Masukkan kode ini di wallet setelah QR dipindai. Jangan bagikan selain kepada pemilik SKCK.',
                    style: poppins(11.5, color: DashColors.navGrey, height: 1.4)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        GoldPanel(
          child: Column(
            children: [
              _kv('Jenis kredensial', IssuerOffers.credentialType),
              _kv('Referensi', IssuerOffers.subjectRef.isEmpty ? '-' : _mask(IssuerOffers.subjectRef)),
              _kv('Offer ID', _offer?.id ?? '-', last: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qrContent() {
    switch (_phase) {
      case 'loading':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFDBAB26)),
              const SizedBox(height: 12),
              Text('Membuat QR dari Issuer...', style: poppins(12.5, color: const Color(0xFF555555))),
            ],
          ),
        );
      case 'error':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFB3261E), size: 40),
                const SizedBox(height: 10),
                Text('Gagal membuat QR', style: poppins(14, weight: FontWeight.w700, color: const Color(0xFF1B1B1B))),
                const SizedBox(height: 6),
                Text(_error, textAlign: TextAlign.center, style: poppins(12, color: const Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        );
      default:
        final st = _offer!.state;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: st == 'waiting' ? 1 : 0.12, child: Image.memory(_qr!, fit: BoxFit.contain, gaplessPlayback: true)),
            if (st != 'waiting')
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(st == 'used' ? Icons.check_circle : Icons.timer_off_outlined,
                        size: 56, color: st == 'used' ? const Color(0xFF2F8A46) : const Color(0xFF8A7A60)),
                    const SizedBox(height: 8),
                    Text(
                      switch (st) {
                        'used' => 'Sudah diambil wallet',
                        'expired' => 'QR kedaluwarsa',
                        _ => 'QR dibatalkan',
                      },
                      style: poppins(15, weight: FontWeight.w700, color: const Color(0xFF1B1B1B)),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget _statusLine() {
    if (_phase != 'ready') return const SizedBox(height: 18);
    final st = _offer!.state;
    if (st != 'waiting') {
      return Text(
        st == 'used' ? 'Kredensial telah diterima wallet.' : 'Buat QR baru untuk menampilkan lagi.',
        style: poppins(12.5, color: DashColors.goldSoft),
      );
    }
    final m = _left.inMinutes, s = _left.inSeconds % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 18, color: DashColors.gold),
        const SizedBox(width: 6),
        Text('Berlaku ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: poppins(14, weight: FontWeight.w600, color: DashColors.gold)),
        const SizedBox(width: 10),
        Text('· pindai dengan wallet', style: poppins(12.5, color: DashColors.navGrey)),
      ],
    );
  }

  Widget _kv(String k, String v, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 8),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(k, style: poppins(12, color: DashColors.navGrey))),
            Expanded(child: Text(v, style: poppins(12.5, weight: FontWeight.w500, color: DashColors.goldSoft))),
          ],
        ),
      );

  String _mask(String v) => v.length == 16 ? '${v.substring(0, 6)}••••••${v.substring(12)}' : v;

  // ---------------------------------------------------------------- Kredensial lain (QR lokal)
  Widget _localView() {
    final cred = widget.cred;
    final disclosed = {
      for (final a in cred.attributes)
        if (a.minimization == 'open' || ['nama_penanggung_jawab', 'nama_kegiatan', 'tanggal_peninjauan'].contains(a.name)) a.name: a.value,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DashColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashColors.border, width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: jsonEncode({'vct': cred.vct, 'demo': true, 'disclosed': disclosed}),
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(cred.holder, style: poppins(15, weight: FontWeight.w700)),
              Text(cred.number, style: poppins(12, color: DashColors.goldSoft)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Versi demo: QR berisi ringkasan data izin keramaian.', style: poppins(11, color: DashColors.navGrey)),
      ],
    );
  }
}
