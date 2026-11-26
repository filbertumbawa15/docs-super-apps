import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/sample.dart';
import 'screens/credential_detail.dart';
import 'screens/home_shell.dart';
import 'screens/splash.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SuperAppsDemo());
}

class SuperAppsDemo extends StatelessWidget {
  const SuperAppsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Apps Polri (Demo)',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Pratinjau otomatis: --dart-define=START=... atau, di web, ?start=dashboard / ?start=layanan.
      home: switch (_startScreen()) {
        'dashboard' => const HomeShell(),
        'layanan' => const HomeShell(openLayanan: true),
        'splash' => const SplashScreen(hold: true),
        'vc' => CredentialDetailScreen(cred: credentials.first),
        _ => const SplashScreen(),
      },
    );
  }
}

String _startScreen() {
  const fromDefine = String.fromEnvironment('START');
  if (fromDefine.isNotEmpty) return fromDefine;
  if (kIsWeb) return Uri.base.queryParameters['start'] ?? '';
  return '';
}
