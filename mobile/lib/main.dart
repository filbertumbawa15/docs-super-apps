import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      // --dart-define=START=dashboard langsung membuka dashboard (dipakai untuk pratinjau otomatis).
      home: const String.fromEnvironment('START') == 'dashboard' ? const HomeShell() : const SplashScreen(),
    );
  }
}
