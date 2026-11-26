import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'login.dart';
import 'onboarding.dart';

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
      MaterialPageRoute<void>(builder: (_) => seen ? const LoginScreen() : const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brownDark,
      body: SafeArea(
        child: Column(
          children: [
            Spacer(),
            Seal(size: 88),
            SizedBox(height: 20),
            Text('Super Apps Polri',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            SizedBox(height: 6),
            Text('Layanan kepolisian dalam satu genggaman',
                style: TextStyle(color: Color(0xFFD9CCB6), fontSize: 14)),
            Spacer(),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.goldLight)),
            SizedBox(height: 28),
            Text('Versi demo', style: TextStyle(color: Color(0xFFA8987E), fontSize: 12)),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
