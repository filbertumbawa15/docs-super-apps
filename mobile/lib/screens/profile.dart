import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample.dart';
import '../theme.dart';
import 'login.dart';
import 'splash.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cream,
                    child: Text(citizen.initials,
                        style: const TextStyle(color: AppColors.brown, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(citizen.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('NIK ${citizen.maskedNik}',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'monospace')),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Terverifikasi Dukcapil',
                              style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _item(context, Icons.lock_outline, 'Ubah PIN'),
                const Divider(),
                _item(context, Icons.fingerprint, 'Masuk dengan biometrik'),
                const Divider(),
                _item(context, Icons.history, 'Riwayat berbagi data'),
                const Divider(),
                _item(context, Icons.help_outline, 'Bantuan'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.replay, color: AppColors.brown),
                  title: const Text('Ulangi onboarding (demo)'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('onboarding_done');
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
                      (_) => false,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.red),
                  title: const Text('Keluar', style: TextStyle(color: AppColors.red)),
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('Super Apps Polri · versi demo 0.1.0', style: TextStyle(fontSize: 12, color: AppColors.muted))),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brown),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title: belum tersedia di versi demo.'))),
    );
  }
}
