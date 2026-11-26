import 'package:flutter/material.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layanan')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = services[i];
          final emergency = s.name.startsWith('Darurat');
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emergency ? const Color(0xFFFBEBEB) : AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconFor(s.icon), color: emergency ? AppColors.red : AppColors.brown),
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.desc, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              trailing: s.live
                  ? const Icon(Icons.chevron_right, color: AppColors.muted)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Segera hadir', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.live ? '${s.name}: tersedia di versi berikutnya aplikasi demo.' : '${s.name}: segera hadir.')),
              ),
            ),
          );
        },
      ),
    );
  }
}
