import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../data/skck_repo.dart';
import '../widgets/common.dart' show fmtDate;
import '../widgets/dark.dart';
import 'credential_detail.dart';
import 'dashboard.dart' show DashColors, poppins;

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Dompet Kredensial',
      body: ValueListenableBuilder<String>(
        valueListenable: SkckRepo.status,
        builder: (context, _, __) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SourceBanner(),
          const SizedBox(height: 16),
          for (final c in credentials) ...[
            VcCardDark(
              cred: c,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CredentialDetailScreen(cred: c))),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: DashColors.navGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.daysRemaining == null
                        ? 'Tanpa masa berlaku'
                        : c.daysRemaining! < 0
                            ? 'Berakhir ${fmtDate(c.validUntil)}'
                            : 'Berlaku ${c.daysRemaining} hari lagi · s.d. ${fmtDate(c.validUntil)}',
                    style: poppins(12, color: DashColors.navGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],
          GoldPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, color: DashColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kredensial disimpan di ponsel ini dan ditandatangani oleh penerbitnya. '
                    'Anda memilih sendiri data yang dibagikan saat verifikasi.',
                    style: poppins(12.5, color: const Color(0xFFB9B2A0), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
