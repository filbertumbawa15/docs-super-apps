import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../data/skck_repo.dart';
import '../widgets/common.dart' show fmtDate;
import '../widgets/dark.dart';
import 'dashboard.dart' show DashColors, poppins;
import 'share.dart';

class CredentialDetailScreen extends StatelessWidget {
  final Credential cred;
  const CredentialDetailScreen({super.key, required this.cred});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SkckRepo.status,
      builder: (context, _, __) {
        // SKCK contoh otomatis diganti data API begitu tersedia.
        final c = cred.kind == CredKind.skck && !cred.fromApi
            ? credentials.firstWhere((x) => x.kind == CredKind.skck, orElse: () => cred)
            : cred;
        return _build(context, c);
      },
    );
  }

  Widget _build(BuildContext context, Credential cred) {
    final isSkck = cred.kind == CredKind.skck;
    final total = cred.validUntil == null ? 0 : cred.validUntil!.difference(cred.validFrom).inDays;
    final left = (cred.daysRemaining ?? 0).clamp(0, total == 0 ? 1 : total);
    final ratio = total == 0 ? 0.0 : left / total;

    return DarkPage(
      title: isSkck ? 'VC SKCK' : 'VC Izin Keramaian',
      bottom: GoldButton(
        label: 'Bagikan untuk verifikasi',
        icon: Icons.qr_code_2,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ShareScreen(cred: cred))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          VcCardDark(cred: cred),
          if (isSkck) ...[const SizedBox(height: 12), const SourceBanner()],
          if (cred.applicationStatus != 'completed') ...[
            const SizedBox(height: 10),
            GoldPanel(
              child: Text('Status pengajuan: ${cred.applicationStatus}. Kredensial berlaku penuh setelah SKCK terbit (completed).',
                  style: poppins(12, color: DashColors.gold, height: 1.4)),
            ),
          ],
          const SizedBox(height: 18),
          GoldPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Masa berlaku', style: poppins(14, weight: FontWeight.w600)),
                    const Spacer(),
                    DarkStatus(cred.validity),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(cred.daysRemaining == null ? '-' : '${cred.daysRemaining}',
                        style: poppins(30, weight: FontWeight.w700, color: DashColors.gold, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('hari lagi', style: poppins(13, color: const Color(0xFFB9B2A0))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2A2F45),
                    valueColor: const AlwaysStoppedAnimation(DashColors.gold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(fmtDate(cred.validFrom), style: poppins(11.5, color: DashColors.navGrey)),
                    const Spacer(),
                    Text(fmtDate(cred.validUntil), style: poppins(11.5, color: DashColors.navGrey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GoldPanel(
            child: Column(
              children: [
                _kv('Penerbit', cred.issuer),
                _kv('Jenis kredensial', cred.vct, mono: true),
                _kv('Format', 'SD-JWT VC'),
                _kv('Tanda tangan', 'Terverifikasi', good: true, last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool mono = false, bool good = false, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: poppins(12.5, color: DashColors.navGrey))),
          if (good) const Icon(Icons.verified, size: 16, color: Color(0xFF3DDC5C)),
          if (good) const SizedBox(width: 4),
          Expanded(
            child: Text(v,
                style: mono
                    ? poppins(12.5, weight: FontWeight.w500, color: DashColors.goldSoft)
                    : poppins(13, weight: FontWeight.w500, color: good ? const Color(0xFF3DDC5C) : Colors.white)),
          ),
        ],
      ),
    );
  }
}
