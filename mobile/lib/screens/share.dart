import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Pilih atribut yang dibagikan (selective disclosure), lalu tampilkan QR.
/// Versi demo: QR berisi ringkasan atribut terpilih, bukan presentasi SD-JWT bertanda tangan.
class ShareScreen extends StatefulWidget {
  final Credential cred;
  const ShareScreen({super.key, required this.cred});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final Set<String> _selected;
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    // Bawaan: atribut 'open' + nama dan masa berlaku (umum diminta pemberi kerja).
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
    return Scaffold(
      appBar: AppBar(title: Text(_showQr ? 'Tunjukkan ke petugas' : 'Pilih data yang dibagikan')),
      body: _showQr ? _qrView(cred) : _pickView(cred),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        child: _showQr
            ? OutlinedButton(onPressed: () => setState(() => _showQr = false), child: const Text('Ubah data yang dibagikan'))
            : FilledButton(
                onPressed: _selected.isEmpty ? null : () => setState(() => _showQr = true),
                child: Text('Tampilkan QR (${_selected.length} atribut)'),
              ),
      ),
    );
  }

  Widget _pickView(Credential cred) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppColors.brown, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Bagikan seperlunya. Data yang tidak dipilih tidak ikut terkirim dan tetap tersimpan di ponsel Anda.',
                    style: TextStyle(fontSize: 13, color: AppColors.brownDark, height: 1.45)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < cred.attributes.length; i++) ...[
                if (i > 0) const Divider(),
                _checkTile(cred.attributes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkTile(Attr a) {
    final locked = a.minimization == 'open';
    final value = a.name == 'nik' ? citizen.maskedNik : a.value;
    return CheckboxListTile(
      value: _selected.contains(a.name),
      onChanged: locked
          ? null
          : (v) => setState(() => v == true ? _selected.add(a.name) : _selected.remove(a.name)),
      activeColor: AppColors.brown,
      controlAffinity: ListTileControlAffinity.trailing,
      title: Row(
        children: [
          Flexible(child: Text(a.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          MinimizationTag(a.minimization),
        ],
      ),
      subtitle: Text(a.name == 'foto' ? 'Foto pemegang' : value,
          maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
    );
  }

  Widget _qrView(Credential cred) {
    final shared = cred.attributes.where((a) => _selected.contains(a.name)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: _payload,
              size: 240,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.brownDark),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.brownDark),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(cred.title,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cred.number, style: const TextStyle(fontFamily: 'monospace', color: AppColors.muted)),
            const SizedBox(width: 8),
            StatusChip(validity: cred.validity),
          ],
        ),
        const SizedBox(height: 20),
        Text('Data yang dibagikan (${shared.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in shared)
              Chip(
                label: Text(a.label, style: const TextStyle(fontSize: 12.5)),
                backgroundColor: AppColors.cream,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Versi demo: QR berisi ringkasan data terpilih. Pada versi produksi, QR berisi presentasi SD-JWT VC yang ditandatangani.',
          style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}
