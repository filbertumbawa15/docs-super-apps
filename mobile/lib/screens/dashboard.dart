import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common.dart';
import 'services.dart';
import 'wallet.dart';

/// Warna dashboard, diukur dari tangkapan layar Super Apps.
class DashColors {
  static const bg = Color(0xFF101320);
  static const card = Color(0xFF141827);
  static const inner = Color(0xFF10131F);
  static const tile = Color(0xFF131624);
  static const border = Color(0xFFF6C337);
  static const gold = Color(0xFFF7C538);
  static const goldPill = Color(0xFFDBAB26);
  static const goldIcon = Color(0xFFFBD25C);
  static const goldSoft = Color(0xFFE6CF8C);
  static const headerA = Color(0xFFF7C538);
  static const headerB = Color(0xFFFBD86A);
  static const circuit = Color(0xFFE5A92B);
  static const khaki = Color(0xFFC8B375);
  static const khakiMid = Color(0xFF95865F);
  static const khakiLow = Color(0xFF373636);
  static const nav = Color(0xFF1A1D2E);
  static const navGrey = Color(0xFF737373);
  static const navActive = Color(0xFFFFDC79);
  static const dial = Color(0xFFFBCF51);
  static const dialTop = Color(0xFFFFD96E);
  static const online = Color(0xFF22C52D);
}

TextStyle poppins(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.white, double? height}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenBerita;
  final VoidCallback onOpenRiwayat;
  const DashboardScreen({super.key, required this.onOpenBerita, required this.onOpenRiwayat});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: ColoredBox(
        color: DashColors.bg,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const _Header(name: 'Guest'),
            const SizedBox(height: 17),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ExploreCard(
                    onSearch: () => _push(context, const ServicesScreen()),
                    onSkck: () => _push(context, const WalletScreen()),
                    onMore: () => _push(context, const ServicesScreen()),
                  ),
                  const SizedBox(height: 17),
                  _HistoryCard(onOpen: onOpenRiwayat),
                  const SizedBox(height: 17),
                  _DiscoveryCard(onOpen: onOpenBerita),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------
// Header emas: motif sirkuit, ikon samar di kanan, avatar, nama, titik online.
class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(42)),
      child: Container(
        height: top + 55,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [DashColors.headerA, DashColors.headerA, DashColors.headerB],
            stops: [0, 0.5, 1],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CircuitPainter(DashColors.circuit.withAlpha(150)))),
            Positioned(right: 168, top: top - 16, child: _ghostIcon(Icons.chat_bubble_outline, 46, -0.08)),
            Positioned(right: 128, top: top + 10, child: _ghostIcon(Icons.credit_card, 64, 0)),
            Positioned(right: 104, top: -20, child: _ghostIcon(Icons.phone_in_talk_outlined, 56, 0.1)),
            Positioned(right: 18, top: top - 26, child: _ghostIcon(Icons.language, 60, 0.05)),
            Positioned(
              left: 25,
              top: (top - 22).clamp(8.0, 200.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Container(
                        color: DashColors.gold,
                        child: Image.asset(
                          'assets/logo/polri.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(child: Seal(size: 40, color: Color(0xFF8A6A08))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 23),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: poppins(20, weight: FontWeight.w700, color: const Color(0xFF1B1B1B), height: 1.15)),
                        const SizedBox(height: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: DashColors.online, shape: BoxShape.circle),
                        ),
                      ],
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

  Widget _ghostIcon(IconData icon, double size, double angle) => Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(size * 0.24),
            border: Border.all(color: Colors.white.withAlpha(70), width: 1.2),
          ),
          child: Icon(icon, size: size * 0.5, color: const Color(0xFFB8860B).withAlpha(110)),
        ),
      );
}

/// Garis-garis bergaya jalur sirkuit dengan titik di ujungnya.
class _CircuitPainter extends CustomPainter {
  final Color color;
  _CircuitPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final w = size.width, h = size.height;
    final paths = <List<Offset>>[
      [Offset(0, h * .30), Offset(w * .10, h * .30), Offset(w * .14, h * .18), Offset(w * .30, h * .18)],
      [Offset(0, h * .62), Offset(w * .06, h * .62), Offset(w * .10, h * .74), Offset(w * .22, h * .74)],
      [Offset(w * .04, h), Offset(w * .04, h * .86), Offset(w * .16, h * .86)],
      [Offset(w * .20, 0), Offset(w * .20, h * .10), Offset(w * .34, h * .10), Offset(w * .38, h * .02)],
      [Offset(w * .30, h), Offset(w * .30, h * .82), Offset(w * .42, h * .82), Offset(w * .46, h * .70)],
      [Offset(w * .36, h * .30), Offset(w * .50, h * .30), Offset(w * .54, h * .40), Offset(w * .60, h * .40)],
      [Offset(w * .48, h), Offset(w * .52, h * .90), Offset(w * .64, h * .90)],
    ];
    for (final p in paths) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      for (final o in p.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, line);
      canvas.drawCircle(p.last, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------------
// Kartu dasar: latar biru tua, bingkai emas, gradasi khaki di kiri atas, sirkuit samar di kanan.
class _GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double fade; // seberapa jauh gradasi khaki menjangkau (0..1)
  const _GoldCard({required this.child, this.padding = const EdgeInsets.fromLTRB(26, 26, 18, 18), this.fade = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DashColors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment(0.35 * fade, 0.55 * fade),
                    colors: const [DashColors.khaki, DashColors.khakiMid, DashColors.khakiLow, DashColors.card],
                    stops: const [0.0, 0.35, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _CardCircuitPainter())),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _CardCircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2A2F45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    for (var i = 0; i < 5; i++) {
      final x = w * (0.62 + i * 0.07);
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.16), p);
      canvas.drawLine(Offset(x, h), Offset(x, h * 0.88), p);
    }
    canvas.drawLine(Offset(w * 0.94, h * 0.10), Offset(w * 0.99, h * 0.45), p);
    canvas.drawCircle(Offset(w * 0.69, h * 0.16), 3, p);
    canvas.drawCircle(Offset(w * 0.69, h * 0.88), 3, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ArrowPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashColors.goldPill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(width: 48, height: 32, child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF1B1B1B))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------
class _ExploreCard extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onSkck;
  final VoidCallback onMore;
  const _ExploreCard({required this.onSearch, required this.onSkck, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return _GoldCard(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jelajahi Layanan', maxLines: 1, style: poppins(16.5, weight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 4),
                    Text('Mau urus apa hari ini?', maxLines: 1, style: poppins(12, color: DashColors.goldSoft)),
                  ],
                ),
              ),
              Material(
                color: DashColors.goldPill,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 18, color: Color(0xFF1B1B1B)),
                        const SizedBox(width: 6),
                        Text('Cari disini', style: poppins(13.5, weight: FontWeight.w500, color: const Color(0xFF1B1B1B))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: DashColors.inner,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DashColors.border, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ServiceItem(icon: Icons.article_outlined, label: 'SKCK', onTap: onSkck),
                _ServiceItem(icon: Icons.credit_card, label: 'SIM', onTap: () => _soon(context, 'SIM')),
                _ServiceItem(icon: Icons.chat_outlined, label: 'STNK', onTap: () => _soon(context, 'STNK')),
                _ServiceItem(icon: Icons.videocam_outlined, label: '110 Video Call', onTap: () => _soon(context, '110 Video Call')),
                _ServiceItem(dots: true, label: '', onTap: onMore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String name) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name: segera hadir di versi demo.')));
}

class _ServiceItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool dots;
  final VoidCallback onTap;
  const _ServiceItem({this.icon, required this.label, required this.onTap, this.dots = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: DashColors.tile, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: dots
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: const BoxDecoration(color: DashColors.goldIcon, shape: BoxShape.circle),
                        ),
                      ),
                    )
                  : Icon(icon, size: 28, color: DashColors.goldIcon),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 16,
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: poppins(11, weight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------
class _HistoryCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _HistoryCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _GoldCard(
      padding: const EdgeInsets.fromLTRB(24, 16, 22, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Riwayat Aktivitas', maxLines: 1, style: poppins(16.5, weight: FontWeight.w700))),
              _ArrowPill(onTap: onOpen),
            ],
          ),
          const SizedBox(height: 14),
          Text('Belum ada riwayat', style: poppins(12.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------
class _DiscoveryCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _DiscoveryCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _GoldCard(
      fade: 0.8,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 0),
      child: SizedBox(
        height: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 52,
              child: _Poster(asset: 'assets/discovery/1.png', subtitle: 'PESAWAT TANPA AWAK', icon: Icons.flight, caption: 'DRONE MC-I BAAZ\nHYBRID VTOL UAS'),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(child: Text('Discovery', maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: poppins(17.5, weight: FontWeight.w700, color: DashColors.gold))),
                      _ArrowPill(onTap: onOpen),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Expanded(
                    child: _Poster(asset: 'assets/discovery/2.png', subtitle: '', icon: Icons.airplanemode_active, caption: 'SIAP MENJAGA KEAMANAN\nNUSANTARA MELALUI UDARA'),
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

/// Poster Discovery. Memakai gambar dari assets/discovery/ bila ada; bila tidak, placeholder bergaya sama.
class _Poster extends StatelessWidget {
  final String asset;
  final String subtitle;
  final IconData icon;
  final String caption;
  const _Poster({required this.asset, required this.subtitle, required this.icon, required this.caption});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2B93C), Color(0xFFE8A93A), Color(0xFFF4D27A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Column(
        children: [
          const Row(
            children: [
              Seal(size: 26, color: Color(0xFF9A6E0C)),
              Spacer(),
              Icon(Icons.shield, size: 24, color: Color(0xFFB3261E)),
            ],
          ),
          const SizedBox(height: 14),
          Text('TEKNOLOGI', style: poppins(21, weight: FontWeight.w800, height: 1, color: Colors.white)),
          Text('KEPOLISIAN', style: poppins(13, weight: FontWeight.w800, color: const Color(0xFF2A3A8C))),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(subtitle, style: poppins(9.5, weight: FontWeight.w700, color: Colors.white)),
          ],
          const Spacer(),
          Icon(icon, size: 64, color: const Color(0xFF4A4F5C)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6A6F80), width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(caption,
                textAlign: TextAlign.center, style: poppins(9, weight: FontWeight.w800, color: Colors.white, height: 1.2)),
          ),
        ],
      ),
    );
  }
}

/// Navigasi bawah gaya Super Apps: Beranda, Berita, Dial 110 (tombol bulat), Riwayat, Profil.
class SuperNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onDial;
  const SuperNavBar({super.key, required this.index, required this.onSelect, required this.onDial});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 66 + bottom + 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 66 + bottom,
            child: Container(
              color: DashColors.nav,
              padding: EdgeInsets.only(bottom: bottom),
              child: Row(
                children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
                  _navItem(1, Icons.newspaper, Icons.newspaper_outlined, 'Berita'),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text('Dial 110', textAlign: TextAlign.center, style: poppins(12, weight: FontWeight.w500, color: DashColors.navGrey)),
                    ),
                  ),
                  _navItem(2, Icons.history, Icons.history, 'Riwayat'),
                  _navItem(3, Icons.person, Icons.person_outline, 'Profil'),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onDial,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF262626), width: 2),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [DashColors.dialTop, DashColors.dial],
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.phone, size: 28, color: Color(0xFF111111)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData active, IconData inactive, String label) {
    final sel = i == index;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? active : inactive, size: 26, color: sel ? DashColors.navActive : DashColors.navGrey),
            const SizedBox(height: 4),
            Text(label, style: poppins(12, weight: FontWeight.w500, color: sel ? Colors.white : DashColors.navGrey)),
          ],
        ),
      ),
    );
  }
}

/// Halaman Berita (placeholder).
class BeritaScreen extends StatelessWidget {
  const BeritaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DashColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Berita', style: poppins(22, weight: FontWeight.w700)),
              const Spacer(),
              Center(child: Text('Belum ada berita', style: poppins(15, color: DashColors.navGrey))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

