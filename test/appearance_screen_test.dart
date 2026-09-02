import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/edition.dart';
import 'package:diurnul/screens/appearance_screen.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/widgets/edition_background.dart';

void main() {
  testWidgets('shows all Editions in order in a vertical scrollable list', (
    tester,
  ) async {
    final service = EditionService(storage: _MemoryEditionStorage());
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: AppearanceScreen(editionService: service)),
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
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: AppearanceScreen(editionService: service)),
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

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}
