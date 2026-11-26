import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/issuer_auth.dart';
import '../widgets/common.dart';
import 'dashboard.dart' show DashColors, poppins;
import 'home_shell.dart';
import 'onboarding.dart';

/// Layar pertama: logo Polri + "SUPER APP POLRI".
/// Lalu Onboarding (pertama kali) atau langsung Dashboard. Tanpa halaman login.
class SplashScreen extends StatefulWidget {
  final bool hold; // true: tetap di layar ini (untuk pratinjau)
  const SplashScreen({super.key, this.hold = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void initState() {
    super.initState();
    if (!widget.hold) {
      IssuerAuth.fetch(); // POST /api/v1/token -> access_token
      _next();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool('onboarding_done') ?? false;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => seen ? const HomeShell() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: DashColors.bg,
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF131625), Color(0xFF0F111D), Color(0xFF0A0C16)],
              stops: [0, 0.48, 1],
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
            child: const Column(
              children: [
                Spacer(flex: 323),
                Seal(size: 86, color: DashColors.gold),
                SizedBox(height: 17),
                _GoldText('SUPER APP', size: 19.5),
                SizedBox(height: 6),
                _GoldText('POLRI', size: 27.5),
                Spacer(flex: 375),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teks emas bergradasi dengan cahaya lembut.
class _GoldText extends StatelessWidget {
  final String text;
  final double size;
  const _GoldText(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    final style = poppins(size, weight: FontWeight.w800, height: 1.1).copyWith(
      letterSpacing: 0.4,
      shadows: [Shadow(color: const Color(0xFFE8B92A).withAlpha(70), blurRadius: 12)],
    );
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEEC347), Color(0xFFDCA810)],
      ).createShader(r),
      child: Text(text, style: style),
    );
  }
}
