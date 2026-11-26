import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wallet.dart';

/// Bottom sheet "semua layanan" (dibuka dari titik tiga di Jelajahi Layanan).
Future<void> showLayananSheet(BuildContext context) {
  final top = MediaQuery.of(context).padding.top;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(140),
    builder: (_) => Padding(
      padding: EdgeInsets.only(top: top + 21),
      child: const _LayananSheet(),
    ),
  );
}

class _C {
  static const bg = Color(0xFF07080D);
  static const tile = Color(0xFF0A0C13);
  static const field = Color(0xFF3C3F4B);
  static const fieldBorder = Color(0xFF8E7C4A);
  static const hint = Color(0xFF8F909A);
  static const gold = Color(0xFFFBD25C);
  static const goldTop = Color(0xFFFAE361);
  static const goldBottom = Color(0xFFDDA80E);
}

TextStyle _p(double s, {FontWeight w = FontWeight.w400, Color c = Colors.white, double? h}) =>
    GoogleFonts.poppins(fontSize: s, fontWeight: w, color: c, height: h);

class _Item {
  final String label;
  final IconData? icon;
  final bool filled; // ikon besar bergradasi tanpa kotak
  final bool sos;
  final String action; // '' | 'wallet'
  const _Item(this.label, this.icon, {this.filled = false, this.sos = false, this.action = ''});
}

class _Section {
  final String title;
  final List<_Item> items;
  const _Section(this.title, this.items);
}

const _sections = [
  _Section('Darurat', [
    _Item('110 Video Call', Icons.videocam_outlined),
    _Item('110 Dial Call', Icons.phone_in_talk, filled: true),
    _Item('110 Chat Whatsapp', Icons.chat, filled: true),
    _Item('110 VOIP Call', Icons.wifi_calling_3, filled: true),
    _Item('110 Live Chat', Icons.mark_unread_chat_alt, filled: true),
    _Item('SOS', null, sos: true),
    _Item('Riwayat 110', Icons.manage_history, filled: true),
  ]),
  _Section('Informasi', [
    _Item('TV/Radio Polri', Icons.live_tv_outlined),
    _Item('Informasi Polri', Icons.shield_outlined),
    _Item('Berita Polri', Icons.newspaper_outlined),
    _Item('Layanan Kesehatan', Icons.add_circle_outline),
    _Item('Kantor Polisi', Icons.local_police_outlined),
    _Item('Info Terkini', Icons.feed_outlined),
  ]),
  _Section('Pengecekan', [
    _Item('SKCK', Icons.article_outlined, action: 'wallet'),
    _Item('Izin Keramaian', Icons.groups_outlined),
    _Item('SIM', Icons.credit_card),
    _Item('STNK', Icons.directions_car_outlined),
  ]),
];

const _wilayah = ['Indonesia', 'DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'Banten', 'Bali', 'Sumatera Utara', 'Sulawesi Selatan'];

class _LayananSheet extends StatefulWidget {
  const _LayananSheet();

  @override
  State<_LayananSheet> createState() => _LayananSheetState();
}

class _LayananSheetState extends State<_LayananSheet> {
  final _search = TextEditingController();
  String _query = '';
  String _wilayahDipilih = 'Indonesia';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _tap(BuildContext ctx, _Item it) {
    if (it.action == 'wallet') {
      Navigator.of(ctx).pop();
      Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => const WalletScreen()));
      return;
    }
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${it.label}: segera hadir di versi demo.')));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final sections = [
      for (final s in _sections)
        _Section(s.title, s.items.where((i) => q.isEmpty || i.label.toLowerCase().contains(q)).toList()),
    ].where((s) => s.items.isNotEmpty).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: _C.bg,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 59, child: _searchField()),
                    const SizedBox(width: 9),
                    Expanded(flex: 41, child: _wilayahField()),
                  ],
                ),
              ),
              Expanded(
                child: sections.isEmpty
                    ? Center(child: Text('Layanan tidak ditemukan', style: _p(14, c: _C.hint)))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(24, 6, 24, 24 + MediaQuery.of(context).padding.bottom),
                        children: [
                          for (final s in sections) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 24),
                              child: Text(s.title, style: _p(20, w: FontWeight.w700)),
                            ),
                            Wrap(
                              runSpacing: 22,
                              children: [
                                for (final it in s.items)
                                  Builder(builder: (ctx) => _Tile(item: it, onTap: () => _tap(ctx, it))),
                              ],
                            ),
                            const SizedBox(height: 34),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldBox({required Widget child}) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: _C.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.fieldBorder, width: 0.8),
        ),
        child: child,
      );

  Widget _searchField() => _fieldBox(
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: _C.hint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                cursorColor: _C.gold,
                style: _p(15),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Cari Layanan',
                  hintStyle: _p(15, c: _C.hint),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );

  Widget _wilayahField() => PopupMenuButton<String>(
        color: const Color(0xFF1A1D2E),
        onSelected: (v) => setState(() => _wilayahDipilih = v),
        itemBuilder: (_) => [
          for (final w in _wilayah)
            PopupMenuItem(
              value: w,
              child: Text(w, style: _p(14, c: w == _wilayahDipilih ? _C.gold : Colors.white)),
            ),
        ],
        child: _fieldBox(
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.location_on, color: _C.gold, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_wilayahDipilih, maxLines: 1, overflow: TextOverflow.ellipsis, style: _p(14.5, w: FontWeight.w500)),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  final _Item item;
  final VoidCallback onTap;
  const _Tile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 4 kolom: lebar layar dikurangi padding 24 kiri-kanan.
    final w = (MediaQuery.of(context).size.width - 48) / 4;
    return SizedBox(
      width: w,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(width: 64, height: 64, child: _icon()),
            const SizedBox(height: 12),
            Text(item.label, textAlign: TextAlign.center, maxLines: 2, style: _p(13, w: FontWeight.w500, h: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    if (item.sos) {
      return _box(
        Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.gold, width: 2.4)),
          alignment: Alignment.center,
          child: Text('SOS', style: _p(10, w: FontWeight.w700, c: _C.gold)),
        ),
      );
    }
    if (item.filled) {
      return Center(
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.goldTop, _C.goldBottom],
          ).createShader(r),
          blendMode: BlendMode.srcIn,
          child: Icon(item.icon, size: 54, color: Colors.white),
        ),
      );
    }
    return _box(Icon(item.icon, size: 44, color: _C.gold));
  }

  Widget _box(Widget child) => Container(
        decoration: BoxDecoration(color: _C.tile, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: child,
      );
}
