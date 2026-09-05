import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/launch_screen.dart';
import 'screens/today_screen.dart';
import 'services/app_settings_service.dart';
import 'services/entitlement_service.dart';
import 'services/edition_entitlement_coordinator.dart';
import 'services/edition_service.dart';
import 'services/widget_sync_service.dart';
import 'theme/interface_theme.dart';
import 'widgets/entitlement_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const DiurnalApp());
}

class DiurnalApp extends StatefulWidget {
  const DiurnalApp({super.key});

  @override
  State<DiurnalApp> createState() => _DiurnalAppState();
}

class _DiurnalAppState extends State<DiurnalApp> {
  late final InterfaceColorController _controller;
  late final EntitlementController _entitlementController;
  late final EditionEntitlementCoordinator _editionCoordinator;
  late final Future<void> _initialization;
  late final Completer<void> _initializationCompleter;
  late final Completer<TodayPublicationLoad> _publicationCompleter;

  @override
  void initState() {
    super.initState();
    _controller = InterfaceColorController(
      AppSettingsService(),
      widgetSyncService: WidgetSyncService(),
    );
    _entitlementController = EntitlementController(EntitlementService());
    _editionCoordinator = EditionEntitlementCoordinator(
      entitlementController: _entitlementController,
      editionService: EditionService(),
      widgetSyncService: WidgetSyncService(),
    );
    _initializationCompleter = Completer<void>();
    _initialization = _initializationCompleter.future;
    _publicationCompleter = Completer<TodayPublicationLoad>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final publicationLoad = loadTodayPublication();
        unawaited(publicationLoad.then(_publicationCompleter.complete));
        await _initialize(publicationLoad);
        _initializationCompleter.complete();
      } catch (error, stackTrace) {
        _initializationCompleter.completeError(error, stackTrace);
      }
    });
  }

  Future<void> _loadRequiredState() async {
    try {
      await Future.wait([
        _controller.load(syncWidget: false),
        _entitlementController.load(),
      ]);
    } catch (error) {
      debugPrint('Error loading startup state: $error');
    }
    _editionCoordinator.start();
    unawaited(_editionCoordinator.syncNow());
  }

  Future<void> _initialize(
    Future<TodayPublicationLoad> publicationLoad,
  ) async {
    final requiredState = _loadRequiredState();
    final preferredReadiness = Future.wait([
      requiredState,
      publicationLoad,
      Future<void>.delayed(const Duration(milliseconds: 850)),
    ]);
    await Future.any([
      preferredReadiness,
      Future<void>.delayed(const Duration(milliseconds: 2000)),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editionCoordinator.dispose();
    _entitlementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntitlementScope(
      notifier: _entitlementController,
      child: InterfaceThemeScope(
        notifier: _controller,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final palette = InterfacePalette.forColor(
              _controller.settings.interfaceColor,
            );
            return MaterialApp(
              title: 'Diurnal',
              theme: ThemeData(
                brightness: palette.brightness,
                primarySwatch: Colors.indigo,
                fontFamily: 'Inter',
              ),
              home: LaunchGate(
                initialization: _initialization,
                child: TodayScreen(
                  initialPublication: _publicationCompleter.future,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
