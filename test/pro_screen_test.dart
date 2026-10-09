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
    expect(find.text('Diurnus'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('Go deeper into the language.'), findsOneWidget);
    for (final title in [
      'Full Archive',
      'Recall Games',
      'Advanced Recall',
      'Premium Editions',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Enter Pro'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(ProScreen), findsNothing);
    harness.dispose();
  });

  testWidgets('entitlement control updates status and persistence', (
    tester,
  ) async {
    final harness = await _pumpProHarness(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pro-entitlement-toggle')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter Pro'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pro-entitlement-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Return to Free'), findsOneWidget);
    expect(harness.entitlementStorage.value, 'pro');

    await tester.tap(find.byKey(const Key('pro-entitlement-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Enter Pro'), findsOneWidget);
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
        interfaceColor: InterfaceColor.paper,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.black,
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('pro-entitlement-toggle')),
        250,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Return to Free'), findsOneWidget);
      expect(find.text('Premium Editions'), findsOneWidget);
      expect(find.byKey(const Key('pro-entitlement-toggle')), findsOneWidget);
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
  InterfaceColor interfaceColor = InterfaceColor.evergreen,
}) async {
  await tester.binding.setSurfaceSize(Size(700, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final entitlementStorage = _EntitlementStorage()..value = initialTier;
  final entitlementController = EntitlementController(
    EntitlementService(storage: entitlementStorage),
  );
  await entitlementController.load();
  final appController = InterfaceColorController(
    AppSettingsService(storage: _AppSettingsStorage()),
  );
  await appController.update(
    AppSettings.defaults.copyWith(interfaceColor: interfaceColor),
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
  final InterfaceColorController appController;

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
