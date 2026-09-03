import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/edition.dart';
import 'package:diurnul/screens/appearance_screen.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/widgets/edition_background.dart';

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
    expect(find.byType(EditionBackground), findsNWidgets(5));
    expect(Editions.all.map((edition) => edition.name), [
      'Library',
      'Atrium',
      'Archive',
      'Gallery',
      'Midnight',
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

    await tester.tap(find.byKey(const Key('edition-atrium')));
    await tester.pumpAndSettle();

    expect(await service.loadSelectedEdition(), same(Editions.atrium));
    expect(widgetCache.values[WidgetSyncService.editionKey], 'atrium');
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
        of: find.byKey(const Key('edition-selection-atrium')),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsOneWidget,
    );
  });
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
