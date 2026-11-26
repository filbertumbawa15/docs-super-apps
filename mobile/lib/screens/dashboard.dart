import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'credential_detail.dart';
import 'share.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenServices;
  const DashboardScreen({super.key, required this.onOpenWallet, required this.onOpenServices});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final skck = credentials.first;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(context, skck)),
        SliverToBoxAdapter(
          child: SectionTitle('Layanan',
              trailing: TextButton(onPressed: onOpenServices, child: const Text('Semua', style: TextStyle(color: AppColors.brown)))),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ServiceTile(service: services[i]),
              childCount: services.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _emergency(context)),
        const SliverToBoxAdapter(child: SectionTitle('Aktivitas terbaru')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = activities[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.cream,
                    child: Icon(iconFor(a.icon), color: AppColors.brown, size: 20),
                  ),
                  title: Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(a.time, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _header(BuildContext context, Credential skck) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brownDark,
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.gold,
                    child: Text(citizen.initials,
                        style: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: const TextStyle(color: Color(0xFFD9CCB6), fontSize: 13)),
                        Text(citizen.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Badge(
                      smallSize: 8,
                      backgroundColor: AppColors.goldLight,
                      child: Icon(Icons.notifications_none, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text('Kredensial saya',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: onOpenWallet,
                    child: Text('Lihat dompet (${credentials.length})',
                        style: const TextStyle(color: AppColors.goldLight)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CredentialCard(
                cred: skck,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CredentialDetailScreen(cred: skck)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HeaderAction(
                      icon: Icons.qr_code_2,
                      label: 'Tunjukkan SKCK',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => ShareScreen(cred: skck)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderAction(
                      icon: Icons.qr_code_scanner,
                      label: 'Pindai penawaran',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menerima VC dari Issuer Core (OpenID4VCI) belum tersedia di versi demo.')),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emergency(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Material(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demo: panggilan ke 110 tidak dilakukan.')),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.phone_in_talk, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Darurat? Hubungi 110',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Panggilan darurat Polri, gratis 24 jam',
                          style: TextStyle(color: Color(0xFFF6D6D3), fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(20),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldLight.withAlpha(90)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.goldLight, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(service.live ? '${service.name}: tersedia di versi berikutnya aplikasi demo.' : '${service.name}: segera hadir.')),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: service.name.startsWith('Darurat') ? const Color(0xFFFBEBEB) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(iconFor(service.icon),
                color: service.name.startsWith('Darurat') ? AppColors.red : AppColors.brown, size: 26),
          ),
          const SizedBox(height: 6),
          Text(service.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.2)),
        ],
      ),
    );
  }
}
