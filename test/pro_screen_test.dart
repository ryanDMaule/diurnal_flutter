import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/theme/interface_theme.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';

void main() {
  testWidgets('opens from Menu, shows value areas, and returns to Menu', (
    tester,
  ) async {
    final harness = await _pumpProHarness(tester, homeIsMenu: true);

    await tester.tap(find.text('Diurnus Pro'));
    await tester.pumpAndSettle();
    expect(find.byType(ProScreen), findsOneWidget);
    expect(find.text('Diurnus Pro'), findsOneWidget);
    expect(find.text('Go beyond the word of the day.'), findsOneWidget);
    expect(
      find.text('Remember more. Explore further. Make Diurnus yours.'),
      findsOneWidget,
    );
    for (final title in [
      'Full Archive',
      'Advanced Recall',
      'Match & Endless',
      'All Editions',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Diurnus Free'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(ProScreen), findsNothing);
    harness.dispose();
  });

  testWidgets('debug entitlement control updates status and persistence', (
    tester,
  ) async {
    final harness = await _pumpProHarness(tester);
    await tester.drag(
      find.byKey(const Key('pro-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('developer-entitlement-control')),
      findsOneWidget,
    );
    expect(find.text('Diurnus Free'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('developer-tier-pro')));
    await tester.tap(find.byKey(const Key('developer-tier-pro')));
    await tester.pumpAndSettle();
    expect(find.text('Diurnus Pro active'), findsOneWidget);
    expect(harness.entitlementStorage.value, 'pro');

    await tester.tap(find.byKey(const Key('developer-tier-free')));
    await tester.pumpAndSettle();
    expect(find.text('Diurnus Free'), findsOneWidget);
    expect(harness.entitlementStorage.value, 'free');
    harness.dispose();
  });

  testWidgets(
    'stored Pro is restored and short viewport scrolls without overflow',
    (tester) async {
      final harness = await _pumpProHarness(
        tester,
        height: 520,
        initialTier: 'pro',
        interfaceAppearance: InterfaceAppearance.light,
      );
      expect(find.text('Diurnus Pro active'), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        InterfacePalette.light.background,
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('developer-entitlement-control')),
        250,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('All Editions'), findsOneWidget);
      expect(
        find.byKey(const Key('developer-entitlement-control')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      harness.dispose();
    },
  );
}

Future<_Harness> _pumpProHarness(
  WidgetTester tester, {
  bool homeIsMenu = false,
  double height = 1100,
  String? initialTier,
  InterfaceAppearance interfaceAppearance = InterfaceAppearance.dark,
}) async {
  await tester.binding.setSurfaceSize(Size(430, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final entitlementStorage = _EntitlementStorage()..value = initialTier;
  final entitlementController = EntitlementController(
    EntitlementService(storage: entitlementStorage),
  );
  await entitlementController.load();
  final appController = InterfaceAppearanceController(
    AppSettingsService(storage: _AppSettingsStorage()),
  );
  await appController.update(
    AppSettings.defaults.copyWith(interfaceAppearance: interfaceAppearance),
  );
  await tester.pumpWidget(
    EntitlementScope(
      notifier: entitlementController,
      child: InterfaceThemeScope(
        notifier: appController,
        child: MaterialApp(
          home: homeIsMenu
              ? MenuScreen(entitlementController: entitlementController)
              : ProScreen(entitlementController: entitlementController),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(entitlementStorage, entitlementController, appController);
}

class _Harness {
  _Harness(
    this.entitlementStorage,
    this.entitlementController,
    this.appController,
  );

  final _EntitlementStorage entitlementStorage;
  final EntitlementController entitlementController;
  final InterfaceAppearanceController appController;

  void dispose() {
    entitlementController.dispose();
    appController.dispose();
  }
}

class _EntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
}

class _AppSettingsStorage implements AppSettingsStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}
