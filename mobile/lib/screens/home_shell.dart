import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'layanan_sheet.dart';
import 'profile.dart';
import 'riwayat.dart';

class HomeShell extends StatefulWidget {
  final bool openLayanan; // untuk pratinjau otomatis
  const HomeShell({super.key, this.openLayanan = false});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // 0 Beranda, 1 Berita, 2 Riwayat, 3 Profil

  @override
  void initState() {
    super.initState();
    if (widget.openLayanan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLayananSheet(context);
      });
    }
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onOpenBerita: () => _go(1), onOpenRiwayat: () => _go(2)),
      const BeritaScreen(),
      const RiwayatScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: DashColors.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SuperNavBar(
        index: _index,
        onSelect: _go,
        onDial: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo: panggilan ke 110 tidak dilakukan.')),
        ),
      ),
    );
  }
}
