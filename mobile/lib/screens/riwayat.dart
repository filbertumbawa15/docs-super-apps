import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/sample.dart';
import '../widgets/common.dart';
import 'wallet.dart';

/// Riwayat aktivitas, dengan pintasan ke dompet kredensial (VC).
class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  static const _bg = Color(0xFF101320);
  static const _card = Color(0xFF141827);
  static const _gold = Color(0xFFF7C538);

  @override
  Widget build(BuildContext context) {
    TextStyle p(double s, {FontWeight w = FontWeight.w400, Color c = Colors.white}) =>
        GoogleFonts.poppins(fontSize: s, fontWeight: w, color: c);
    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Riwayat', style: p(22, w: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            Material(
              color: _card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _gold, width: 1.5)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: const Icon(Icons.account_balance_wallet_outlined, color: _gold),
                title: Text('Dompet Kredensial', style: p(15, w: FontWeight.w600)),
                subtitle: Text('${credentials.length} kredensial digital', style: p(12.5, c: const Color(0xFFB9B2A0))),
                trailing: const Icon(Icons.chevron_right, color: _gold),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen())),
              ),
            ),
            const SizedBox(height: 20),
            for (final a in activities) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(iconFor(a.icon), color: _gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: p(14, w: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(a.time, style: p(12, c: const Color(0xFF8F909A))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
