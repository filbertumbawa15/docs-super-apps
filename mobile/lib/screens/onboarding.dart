import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/issuer_auth.dart';
import 'dashboard.dart' show DashColors, poppins;
import 'home_shell.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);
}

const _slides = [
  _Slide(Icons.apps_rounded, 'Semua layanan kepolisian di satu aplikasi',
      'Ajukan SKCK, izin keramaian, hingga panggilan darurat 110 tanpa perlu datang ke kantor polisi.'),
  _Slide(Icons.account_balance_wallet_outlined, 'Dokumen resmi di dompet digital',
      'SKCK yang sudah terbit tersimpan sebagai kredensial digital yang ditandatangani Polri dan dapat diverifikasi kapan saja.'),
  _Slide(Icons.verified_user_outlined, 'Bagikan data seperlunya',
      'Saat diminta menunjukkan SKCK, Anda memilih sendiri data yang dibagikan. Data lain tetap tersimpan di ponsel Anda.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    IssuerAuth.fetch(); // pakai token yang ada bila masih berlaku
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: DashColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Lewati', style: poppins(14, color: DashColors.navGrey)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? DashColors.gold : const Color(0xFF2A2F45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DashColors.goldPill,
                      foregroundColor: const Color(0xFF1B1B1B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Text(last ? 'Mulai' : 'Lanjut', style: poppins(16, weight: FontWeight.w600, color: const Color(0xFF1B1B1B))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [DashColors.khaki.withAlpha(90), DashColors.bg]),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DashColors.border.withAlpha(140), width: 1.5),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: DashColors.card,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: DashColors.border, width: 2),
                  ),
                  child: Icon(slide.icon, size: 50, color: DashColors.goldIcon),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(slide.title, textAlign: TextAlign.center, style: poppins(20, weight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 12),
          Text(slide.body, textAlign: TextAlign.center, style: poppins(14, color: const Color(0xFFB9B2A0), height: 1.55)),
        ],
      ),
    );
  }
}
