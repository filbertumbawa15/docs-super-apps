import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample.dart';
import '../data/skck_repo.dart';
import '../screens/dashboard.dart' show DashColors, poppins;
import 'common.dart' show Seal, fmtDate;

/// Komponen bergaya Super Apps (biru tua + emas) untuk halaman VC.

class DarkPage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottom;
  const DarkPage({super.key, required this.title, required this.body, this.bottom});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: DashColors.bg,
        appBar: AppBar(
          backgroundColor: DashColors.bg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Text(title, style: poppins(17, weight: FontWeight.w600)),
        ),
        body: body,
        bottomNavigationBar: bottom == null
            ? null
            : Container(
                color: DashColors.bg,
                padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.of(context).padding.bottom),
                child: bottom,
              ),
      ),
    );
  }
}

/// Panel: latar kartu biru tua dengan bingkai emas tipis.
class GoldPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GoldPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DashColors.border.withAlpha(110), width: 1),
      ),
      child: child,
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  const GoldButton({super.key, required this.label, this.icon, this.onPressed, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? DashColors.gold : const Color(0xFF1B1B1B);
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: outlined ? Colors.transparent : (onPressed == null ? DashColors.goldPill.withAlpha(90) : DashColors.goldPill),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: outlined ? const BorderSide(color: DashColors.gold, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 8)],
              Text(label, style: poppins(15.5, weight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class DarkStatus extends StatelessWidget {
  final String validity; // active | soon | expired
  const DarkStatus(this.validity, {super.key});

  @override
  Widget build(BuildContext context) {
    final (String label, Color c) = switch (validity) {
      'expired' => ('Kedaluwarsa', const Color(0xFF9A9AA2)),
      'soon' => ('Segera berakhir', DashColors.gold),
      _ => ('Aktif', const Color(0xFF3DDC5C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(160)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: poppins(10.5, weight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

class DarkMinTag extends StatelessWidget {
  final String value;
  const DarkMinTag(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = switch (value) {
      'open' => const Color(0xFF3DDC5C),
      'restricted' => const Color(0xFFFF6B5E),
      _ => DashColors.gold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withAlpha(120))),
      child: Text(value, style: poppins(10, weight: FontWeight.w600, color: c)),
    );
  }
}

/// Foto pemegang dari assets/profile/foto.jpg, inisial bila belum ada.
class HolderPhoto extends StatelessWidget {
  final double width;
  final double height;
  const HolderPhoto({super.key, this.width = 62, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashColors.border, width: 1.5),
      ),
      child: Image.asset(
        profilePhoto,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.5),
        errorBuilder: (_, __, ___) => Center(
          child: Text(citizen.initials, style: poppins(width * 0.36, weight: FontWeight.w700, color: DashColors.gold)),
        ),
      ),
    );
  }
}

/// Kartu VC bergaya Super Apps: biru tua, bingkai emas, gradasi khaki, foto pemegang.
class VcCardDark extends StatelessWidget {
  final Credential cred;
  final VoidCallback? onTap;
  const VcCardDark({super.key, required this.cred, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSkck = cred.kind == CredKind.skck;
    return AspectRatio(
      aspectRatio: 1.586,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DashColors.border, width: 2),
            color: DashColors.card,
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: const Alignment(0.6, 0.7),
                        colors: isSkck
                            ? const [DashColors.khaki, DashColors.khakiMid, DashColors.khakiLow, DashColors.card]
                            : const [Color(0xFF8FA26A), Color(0xFF5E6B47), Color(0xFF2E3328), DashColors.card],
                        stops: const [0, 0.28, 0.6, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -50,
                  bottom: -70,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DashColors.border.withAlpha(40), width: 1.2)),
                  ),
                ),
                Positioned(
                  right: -20,
                  bottom: -40,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DashColors.border.withAlpha(30), width: 1.2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: DashColors.gold),
                            child: Image.asset('assets/logo/polri.png',
                                errorBuilder: (_, __, ___) => const Center(child: Seal(size: 22, color: Color(0xFF6B4E06)))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('KEPOLISIAN NEGARA\nREPUBLIK INDONESIA',
                                style: poppins(8.5, weight: FontWeight.w700, color: const Color(0xFF1B1B1B), height: 1.15)),
                          ),
                          DarkStatus(cred.validity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(isSkck ? 'SURAT KETERANGAN\nCATATAN KEPOLISIAN' : 'IZIN KERAMAIAN',
                          style: poppins(13.5, weight: FontWeight.w800, height: 1.15)),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const HolderPhoto(width: 52, height: 68),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _field('NAMA', cred.holder, big: true),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: _field('NOMOR', cred.number)),
                                    _field('BERLAKU S.D.', fmtDate(cred.validUntil)),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _field(String label, String value, {bool big = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: poppins(8.5, weight: FontWeight.w500, color: const Color(0xFFB9B2A0))),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: poppins(big ? 14 : 11, weight: FontWeight.w600, color: big ? Colors.white : DashColors.goldSoft)),
        ],
      );
}


/// Baris status sumber data VC SKCK (API / memuat / data contoh + coba lagi).
class SourceBanner extends StatelessWidget {
  const SourceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SkckRepo.status,
      builder: (_, st, __) {
        final (IconData icon, Color c, String text) = switch (st) {
          'api' => (Icons.cloud_done_outlined, const Color(0xFF3DDC5C), SkckRepo.message),
          'fallback' => (Icons.cloud_off_outlined, DashColors.gold, SkckRepo.message),
          'loading' => (Icons.sync, DashColors.goldSoft, 'Memuat data SKCK dari API...'),
          _ => (Icons.info_outline, DashColors.navGrey, 'Data contoh'),
        };
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: c.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withAlpha(90)),
          ),
          child: Row(
            children: [
              if (st == 'loading')
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c))
              else
                Icon(icon, size: 18, color: c),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: poppins(11.5, color: c, height: 1.4))),
              if (st == 'fallback' || st == 'api')
                TextButton(
                  onPressed: SkckRepo.load,
                  style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(st == 'api' ? 'Muat ulang' : 'Coba lagi', style: poppins(11.5, weight: FontWeight.w600, color: DashColors.gold)),
                ),
            ],
          ),
        );
      },
    );
  }
}
