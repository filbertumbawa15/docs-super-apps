import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Masuk simulasi: NIK + PIN 6 digit. Tidak ada autentikasi sungguhan (demo).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nik = TextEditingController(text: citizen.nik);
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nik.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nik = _nik.text.trim();
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      setState(() => _error = 'NIK harus 16 digit angka.');
      return;
    }
    if (_pin.text.length != 6) {
      setState(() => _error = 'PIN harus 6 digit.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Row(
              children: [
                Seal(size: 44, color: AppColors.brown),
                SizedBox(width: 12),
                Text('Super Apps Polri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
            const SizedBox(height: 36),
            const Text('Masuk ke akun Anda',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text('Gunakan NIK yang terdaftar di Dukcapil dan PIN aplikasi.',
                style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 28),
            const Text('NIK', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _nik,
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace', letterSpacing: 1),
              decoration: const InputDecoration(counterText: '', hintText: '16 digit NIK', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 18),
            const Text('PIN', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(counterText: '', hintText: '6 digit PIN', prefixIcon: Icon(Icons.lock_outline)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 14)),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Masuk'),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Lupa PIN?', style: TextStyle(color: AppColors.brown)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Versi demo. Masukkan PIN 6 digit apa saja untuk masuk. Semua data di aplikasi ini fiktif.',
                        style: TextStyle(fontSize: 13, color: AppColors.amber, height: 1.4)),
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
