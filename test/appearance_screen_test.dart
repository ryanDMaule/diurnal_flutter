import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/edition.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/screens/appearance_screen.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/edition_entitlement_coordinator.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/widgets/edition_background.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';

void main() {
  testWidgets('shows all Editions in order in a vertical scrollable list', (
    tester,
  ) async {
    final service = EditionService(storage: _MemoryEditionStorage());
    final widgetCache = _MemoryWidgetCache();
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppearanceScreen(
          editionService: service,
          widgetSyncService: WidgetSyncService(cache: widgetCache),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appearance-edition-list')), findsOneWidget);
    expect(find.byType(EditionBackground), findsNWidgets(6));
    expect(Editions.all.map((edition) => edition.name), [
      'Library',
      'Evergreen',
      'Midnight',
      'Atrium',
      'Archive',
      'Gallery',
    ]);

    final list = tester.widget<ListView>(
      find.byKey(const Key('appearance-edition-list')),
    );
    expect(list.scrollDirection, Axis.vertical);
  });

  testWidgets('represents selection and persists a newly selected Edition', (
    tester,
  ) async {
    final storage = _MemoryEditionStorage();
    final service = EditionService(storage: storage);
    final widgetCache = _MemoryWidgetCache();
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppearanceScreen(
          editionService: service,
          widgetSyncService: WidgetSyncService(cache: widgetCache),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edition-selection-library')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('edition-selection-library')),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('edition-evergreen')));
    await tester.pumpAndSettle();

    expect(await service.loadSelectedEdition(), same(Editions.evergreen));
    expect(widgetCache.values[WidgetSyncService.editionKey], 'evergreen');
    expect(widgetCache.redrawCount, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('edition-selection-library')),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('edition-selection-evergreen')),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Free locks Pro Editions without persisting or syncing them', (
    tester,
  ) async {
    final storage = _MemoryEditionStorage();
    final service = EditionService(storage: storage);
    final widgetCache = _MemoryWidgetCache();
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EntitlementScope(
        notifier: controller,
        child: MaterialApp(
          home: AppearanceScreen(
            editionService: service,
            widgetSyncService: WidgetSyncService(cache: widgetCache),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EditionBackground), findsNWidgets(6));
    expect(find.byKey(const Key('edition-lock-atrium')), findsOneWidget);
    expect(find.byKey(const Key('edition-lock-archive')), findsOneWidget);
    expect(find.byKey(const Key('edition-lock-gallery')), findsOneWidget);
    expect(find.byKey(const Key('edition-lock-library')), findsNothing);
    expect(find.byKey(const Key('edition-lock-evergreen')), findsNothing);
    expect(find.byKey(const Key('edition-lock-midnight')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('edition-gallery')));
    await tester.tap(find.byKey(const Key('edition-gallery')));
    await tester.pumpAndSettle();
    expect(find.byType(ProScreen), findsOneWidget);
    expect(find.byTooltip('Back to Appearance'), findsOneWidget);
    expect(storage.value, isNull);
    expect(widgetCache.values, isEmpty);
    expect(widgetCache.redrawCount, 0);

    await tester.tap(find.byTooltip('Back to Appearance'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('edition-midnight')));
    await tester.tap(find.byKey(const Key('edition-midnight')));
    await tester.pumpAndSettle();
    expect(storage.value, Editions.midnight.id);
    expect(widgetCache.values[WidgetSyncService.editionKey], 'midnight');
  });

  testWidgets('Pro removes locks and can persist and sync Gallery', (
    tester,
  ) async {
    final storage = _MemoryEditionStorage();
    final widgetCache = _MemoryWidgetCache();
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    await controller.update(SubscriptionTier.pro);
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EntitlementScope(
        notifier: controller,
        child: MaterialApp(
          home: AppearanceScreen(
            editionService: EditionService(storage: storage),
            widgetSyncService: WidgetSyncService(cache: widgetCache),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edition-lock-gallery')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('edition-gallery')));
    await tester.tap(find.byKey(const Key('edition-gallery')));
    await tester.pumpAndSettle();
    expect(storage.value, Editions.gallery.id);
    expect(widgetCache.values[WidgetSyncService.editionKey], 'gallery');
  });

  testWidgets('stored Gallery falls back to Library and restores with Pro', (
    tester,
  ) async {
    final storage = _MemoryEditionStorage()..value = Editions.gallery.id;
    final service = EditionService(storage: storage);
    final widgetCache = _MemoryWidgetCache();
    final widgetSync = WidgetSyncService(cache: widgetCache);
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    final coordinator = EditionEntitlementCoordinator(
      entitlementController: controller,
      editionService: service,
      widgetSyncService: widgetSync,
    )..start();
    addTearDown(coordinator.dispose);
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EntitlementScope(
        notifier: controller,
        child: MaterialApp(
          home: AppearanceScreen(
            editionService: service,
            widgetSyncService: widgetSync,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'library'), isTrue);
    expect(_isSelected(tester, 'gallery'), isFalse);
    expect(storage.value, Editions.gallery.id);
    await controller.update(SubscriptionTier.free);
    await _waitForEdition(widgetCache, 'library');

    await controller.update(SubscriptionTier.pro);
    await tester.pumpAndSettle();
    await _waitForEdition(widgetCache, 'gallery');
    expect(_isSelected(tester, 'library'), isFalse);
    expect(_isSelected(tester, 'gallery'), isTrue);
    expect(storage.value, Editions.gallery.id);
  });
}

bool _isSelected(WidgetTester tester, String id) => find
    .descendant(
      of: find.byKey(Key('edition-selection-$id')),
      matching: find.byIcon(CupertinoIcons.check_mark),
    )
    .evaluate()
    .isNotEmpty;

Future<void> _waitForEdition(_MemoryWidgetCache cache, String id) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (cache.values[WidgetSyncService.editionKey] == id) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Widget Edition never became $id.');
}

class _MemoryWidgetCache implements WidgetCache {
  final values = <String, String>{};
  int redrawCount = 0;

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> redraw() async {
    redrawCount++;
  }
}

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
}
