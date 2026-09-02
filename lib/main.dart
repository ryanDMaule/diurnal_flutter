import 'package:flutter/material.dart';

import 'screens/today_screen.dart';
import 'services/app_settings_service.dart';
import 'theme/interface_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiurnalApp());
}

class DiurnalApp extends StatefulWidget {
  const DiurnalApp({super.key});

  @override
  State<DiurnalApp> createState() => _DiurnalAppState();
}

class _DiurnalAppState extends State<DiurnalApp> {
  late final InterfaceAppearanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InterfaceAppearanceController(AppSettingsService());
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InterfaceThemeScope(
      notifier: _controller,
      child: MaterialApp(
        title: 'Diurnal',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.indigo,
          fontFamily: 'Inter',
        ),
        home: const TodayScreen(),
      ),
    );
  }
}
