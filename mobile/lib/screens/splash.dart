import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/common.dart';
import 'dashboard.dart' show DashColors, poppins;
import 'home_shell.dart';
import 'onboarding.dart';

/// Splash -> Onboarding (pertama kali) -> Dashboard. Tanpa halaman login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool('onboarding_done') ?? false;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => seen ? const HomeShell() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [DashColors.headerA, DashColors.headerB]),
              ),
              child: Image.asset(
                'assets/logo/polri.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(child: Seal(size: 64, color: Color(0xFF6B4E06))),
              ),
            ),
            const SizedBox(height: 22),
            Text('Super Apps Polri', style: poppins(24, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Layanan kepolisian dalam satu genggaman', style: poppins(13.5, color: const Color(0xFFB9B2A0))),
            const Spacer(),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: DashColors.gold)),
            const SizedBox(height: 28),
            Text('Versi demo', style: poppins(12, color: DashColors.navGrey)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
