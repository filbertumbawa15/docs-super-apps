import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/sample.dart';
import '../widgets/dark.dart';
import 'dashboard.dart' show DashColors, poppins;

/// Tampilkan QR berisi atribut yang dibagikan (bawaan: atribut open + nama, keperluan, masa berlaku).
/// Versi demo: QR berisi ringkasan atribut terpilih, bukan presentasi SD-JWT bertanda tangan.
class ShareScreen extends StatefulWidget {
  final Credential cred;
  const ShareScreen({super.key, required this.cred});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.cred.attributes
        .where((a) => a.minimization == 'open' || ['nama_lengkap', 'end_date', 'untuk_keperluan', 'nama_kegiatan'].contains(a.name))
        .map((a) => a.name)
        .toSet();
  }

  String get _payload {
    final disclosed = {
      for (final a in widget.cred.attributes)
        if (_selected.contains(a.name) && a.name != 'foto') a.name: a.value,
    };
    return jsonEncode({'vct': widget.cred.vct, 'demo': true, 'disclosed': disclosed});
  }

  @override
  Widget build(BuildContext context) {
    final cred = widget.cred;
    return DarkPage(
      title: 'Tunjukkan ke petugas',
      body: _qrView(cred),
    );
  }

  Widget _qrView(Credential cred) {
    final shared = cred.attributes.where((a) => _selected.contains(a.name)).toList();
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: _payload,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF101320)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF101320)),
                ),
              ),
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
        const SizedBox(height: 20),
        Text('Data yang dibagikan (${shared.length})', style: poppins(14, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in shared)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DashColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DashColors.border.withAlpha(110)),
                ),
                child: Text(a.label, style: poppins(11.5, color: DashColors.goldSoft)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Versi demo: QR berisi ringkasan data terpilih. Pada versi produksi, QR berisi presentasi SD-JWT VC yang ditandatangani.',
            style: poppins(11, color: DashColors.navGrey, height: 1.45)),
      ],
    );
  }
}
