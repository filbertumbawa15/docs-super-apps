import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../theme.dart';

IconData iconFor(String name) {
  switch (name) {
    case 'description':
      return Icons.description_outlined;
    case 'groups':
      return Icons.groups_outlined;
    case 'badge':
      return Icons.badge_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    case 'search':
      return Icons.manage_search_outlined;
    case 'forum':
      return Icons.forum_outlined;
    case 'fact_check':
      return Icons.fact_check_outlined;
    case 'emergency':
      return Icons.emergency_outlined;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'check_circle':
      return Icons.check_circle_outline;
    case 'event_available':
      return Icons.event_available_outlined;
    default:
      return Icons.circle_outlined;
  }
}

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fmtDate(DateTime? d) => d == null ? '-' : '${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';

/// Satu path logo untuk seluruh aplikasi.
const kPolriLogo = 'assets/logo/polri.png';

/// Logo Polri dari [kPolriLogo]; ikon perisai bila file tidak ada.
class Seal extends StatelessWidget {
  final double size;
  final Color color;
  const Seal({super.key, this.size = 32, this.color = AppColors.goldLight});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kPolriLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
        alignment: Alignment.center,
        child: Icon(Icons.shield_outlined, size: size * 0.55, color: color),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String validity; // active | soon | expired
  final bool onDark;
  const StatusChip({super.key, required this.validity, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (validity) {
      case 'expired':
        label = 'Kedaluwarsa';
        bg = const Color(0xFF8A7A60);
        fg = Colors.white;
        break;
      case 'soon':
        label = 'Segera berakhir';
        bg = AppColors.goldLight;
        fg = AppColors.brownDark;
        break;
      default:
        label = 'Aktif';
        bg = AppColors.green;
        fg = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class MinimizationTag extends StatelessWidget {
  final String value;
  const MinimizationTag(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    switch (value) {
      case 'open':
        fg = const Color(0xFF1F5E30);
        bg = AppColors.greenBg;
        break;
      case 'restricted':
        fg = const Color(0xFF8C1D16);
        bg = const Color(0xFFFBEBEB);
        break;
      default:
        fg = AppColors.amber;
        bg = AppColors.amberBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(value, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Kartu kredensial bergaya kartu identitas.
class CredentialCard extends StatelessWidget {
  final Credential cred;
  final VoidCallback? onTap;
  const CredentialCard({super.key, required this.cred, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSkck = cred.kind == CredKind.skck;
    final colors = isSkck
        ? const [Color(0xFF4A2C12), AppColors.brownDark, AppColors.brownDeep]
        : const [AppColors.ikGreen, Color(0xFF26321D), AppColors.ikGreenDeep];
    return AspectRatio(
      aspectRatio: 1.586,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, color: AppColors.gold)),
                  Positioned(
                    right: -60,
                    bottom: -90,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldLight.withAlpha(46)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Seal(size: 26),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(issuerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            StatusChip(validity: cred.validity, onDark: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(cred.title,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.15)),
                        const SizedBox(height: 2),
                        Text(cred.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFD9CCB6), fontSize: 11.5)),
                        const Spacer(),
                        const Text('PEMEGANG', style: TextStyle(color: Color(0xFFC8B89C), fontSize: 9.5, letterSpacing: 0.6)),
                        Text(cred.holder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _mini('NOMOR', cred.number)),
                            _mini(isSkck ? 'BERLAKU S.D.' : 'BERLAKU S.D.', fmtDate(cred.validUntil)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFC8B89C), fontSize: 9.5, letterSpacing: 0.6)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFF6ECD6), fontSize: 12.5, fontFamily: 'monospace')),
        ],
      );
}
