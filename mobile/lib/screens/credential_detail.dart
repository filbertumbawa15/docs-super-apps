import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'share.dart';

class CredentialDetailScreen extends StatelessWidget {
  final Credential cred;
  const CredentialDetailScreen({super.key, required this.cred});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(cred.kind == CredKind.skck ? 'Detail SKCK' : 'Detail Izin Keramaian')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          CredentialCard(cred: cred),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Penerbit', cred.issuer),
                  _row('Jenis kredensial', cred.vct, mono: true),
                  _row('Berlaku sejak', fmtDate(cred.validFrom)),
                  _row('Berlaku sampai', fmtDate(cred.validUntil)),
                  _row('Sisa masa berlaku', cred.daysRemaining == null ? '-' : '${cred.daysRemaining} hari', last: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Atribut (${cred.attributes.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Spacer(),
              const MinimizationTag('open'),
              const SizedBox(width: 4),
              const MinimizationTag('normal'),
              const SizedBox(width: 4),
              const MinimizationTag('restricted'),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'open selalu terlihat; normal dan restricted hanya dibagikan bila Anda memilihnya.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < cred.attributes.length; i++) ...[
                  if (i > 0) const Divider(),
                  _AttrTile(attr: cred.attributes[i]),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ShareScreen(cred: cred))),
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Bagikan untuk verifikasi'),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool mono = false, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Expanded(
            child: Text(v,
                style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500, fontFamily: mono ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }
}

class _AttrTile extends StatelessWidget {
  final Attr attr;
  const _AttrTile({required this.attr});

  @override
  Widget build(BuildContext context) {
    final isNik = attr.name == 'nik';
    final value = isNik ? citizen.maskedNik : attr.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attr.label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 3),
                if (attr.name == 'foto')
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      profilePhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 44, color: AppColors.muted),
                    ),
                  )
                else
                  Text(value,
                      style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w500,
                          fontFamily: isNik || attr.name.startsWith('nomor') || attr.name == 'nomer_paspor' ? 'monospace' : null)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          MinimizationTag(attr.minimization),
        ],
      ),
    );
  }
}
