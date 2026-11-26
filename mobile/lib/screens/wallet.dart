import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'credential_detail.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet Kredensial')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: credentials.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, i) {
          if (i == credentials.length) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: AppColors.brown, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kredensial disimpan di ponsel ini dan ditandatangani oleh penerbitnya. '
                      'Anda memilih sendiri data yang dibagikan saat verifikasi.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }
          final c = credentials[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CredentialCard(
                cred: c,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CredentialDetailScreen(cred: c)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.daysRemaining == null
                          ? 'Tanpa masa berlaku'
                          : c.daysRemaining! < 0
                              ? 'Berakhir ${fmtDate(c.validUntil)}'
                              : 'Berlaku ${c.daysRemaining} hari lagi · s.d. ${fmtDate(c.validUntil)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
