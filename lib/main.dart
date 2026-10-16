import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screens/launch_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'services/app_settings_service.dart';
import 'services/entitlement_service.dart';
import 'services/install_identity_service.dart';
import 'services/edition_entitlement_coordinator.dart';
import 'services/edition_service.dart';
import 'services/publication_api_service.dart';
import 'services/onboarding_service.dart';
import 'services/sound_effects_service.dart';
import 'services/widget_sync_service.dart';
import 'theme/interface_theme.dart';
import 'theme/motion_preferences.dart';
import 'widgets/entitlement_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const DiurnalApp());
}

class DiurnalApp extends StatefulWidget {
  const DiurnalApp({
    this.appSettingsService,
    this.entitlementService,
    this.editionService,
    this.onboardingService,
    this.installIdentityService,
    this.widgetSyncService,
    this.initialPublicationLoader,
    this.enableStartupAudio = true,
    super.key,
  });

  final AppSettingsService? appSettingsService;
  final EntitlementService? entitlementService;
  final EditionService? editionService;
  final OnboardingService? onboardingService;
  final InstallIdentityService? installIdentityService;
  final WidgetSyncService? widgetSyncService;
  final Future<TodayPublicationLoad> Function()? initialPublicationLoader;
  final bool enableStartupAudio;

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
  late final OnboardingService _onboardingService;
  late final InstallIdentityService _installIdentityService;
  bool _showOnboarding = false;
  bool _showMenuShimmer = false;
  int _onboardingInitialStep = 0;
  bool _useDefaultOnboardingAppearance = false;

  @override
  void initState() {
    super.initState();
    final widgetSyncService = widget.widgetSyncService ?? WidgetSyncService();
    _controller = InterfaceColorController(
      widget.appSettingsService ?? AppSettingsService(),
      widgetSyncService: widgetSyncService,
    );
    _entitlementController = EntitlementController(
      widget.entitlementService ?? EntitlementService(),
    );
    _onboardingService = widget.onboardingService ?? OnboardingService();
    _installIdentityService =
        widget.installIdentityService ?? const PlatformInstallIdentityService();
    _editionCoordinator = EditionEntitlementCoordinator(
      entitlementController: _entitlementController,
      editionService: widget.editionService ?? EditionService(),
      widgetSyncService: widgetSyncService,
    );
    _initializationCompleter = Completer<void>();
    _initialization = _initializationCompleter.future;
    _publicationCompleter = Completer<TodayPublicationLoad>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final publicationLoad =
            widget.initialPublicationLoader?.call() ?? loadTodayPublication();
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
      debugPrint('Error loading settings or entitlement state: $error');
    }
    try {
      final freshInstallation = await _installIdentityService
          .isFreshInstallation();
      final onboarding = await _onboardingService.resolve(
        isFreshInstallation: freshInstallation,
      );
      _showOnboarding = onboarding.shouldShow;
      _onboardingInitialStep = onboarding.initialStep;
      _showMenuShimmer = onboarding.shouldShowMenuShimmer;
      _useDefaultOnboardingAppearance = onboarding.useDefaultAppearance;
      if (kDebugMode) {
        final previewEnabled =
            onboarding.previewTokenStatus != PreviewTokenStatus.disabled;
        final previewStatus = switch (onboarding.previewTokenStatus) {
          PreviewTokenStatus.disabled => 'disabled',
          PreviewTokenStatus.newToken => 'new',
          PreviewTokenStatus.completedToken => 'completed',
        };
        debugPrint(
          'DiurnusStartup: preview=${previewEnabled ? 'enabled' : 'disabled'} '
          'previewToken=$previewStatus freshInstall=$freshInstallation '
          'onboardingComplete=${onboarding.onboardingComplete} '
          'destination=${onboarding.shouldShow ? 'onboarding' : 'today'}',
        );
      }
    } catch (error) {
      debugPrint('Error loading onboarding state: $error');
    }
    if (widget.enableStartupAudio) {
      SoundEffectsService.instance.setEnabled(
        _controller.settings.soundEffectsEnabled,
      );
      SoundEffectsService.instance.preload();
    }
    _editionCoordinator.start();
    unawaited(_editionCoordinator.syncNow());
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;
    setState(() {
      _showOnboarding = false;
      _showMenuShimmer = true;
    });
  }

  Future<void> _initialize(Future<TodayPublicationLoad> publicationLoad) async {
    await _loadRequiredState();
    final preferredReadiness = Future.wait([
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
                pageTransitionsTheme: diurnusPageTransitionsTheme,
              ),
              home: LaunchGate(
                initialization: _initialization,
                builder: (context) => _showOnboarding
                    ? OnboardingScreen(
                        initialStep: _onboardingInitialStep,
                        useDefaultAppearance: _useDefaultOnboardingAppearance,
                        onboardingService: _onboardingService,
                        onCompleted: _completeOnboarding,
                      )
                    : TodayScreen(
                        initialPublication: _publicationCompleter.future,
                        showMenuShimmer: _showMenuShimmer,
                        onMenuShimmerConsumed: () async {
                          await _onboardingService.consumeMenuShimmer();
                          _showMenuShimmer = false;
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
