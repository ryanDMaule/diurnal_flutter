import 'package:flutter/material.dart';

import 'screens/today_screen.dart';
import 'services/app_settings_service.dart';
import 'services/entitlement_service.dart';
import 'theme/interface_theme.dart';
import 'widgets/entitlement_scope.dart';

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
  late final EntitlementController _entitlementController;

  @override
  void initState() {
    super.initState();
    _controller = InterfaceAppearanceController(AppSettingsService());
    _entitlementController = EntitlementController(EntitlementService());
    _controller.load();
    _entitlementController.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _entitlementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntitlementScope(
      notifier: _entitlementController,
      child: InterfaceThemeScope(
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
      ),
    );
  }
}
