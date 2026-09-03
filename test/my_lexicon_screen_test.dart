import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/screens/my_lexicon_screen.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  late _MemoryBookmarkStorage storage;
  late BookmarkService service;
  late EditionService editionService;
  late DailyPublication diurnal;
  late DailyPublication arcane;

  setUp(() {
    storage = _MemoryBookmarkStorage();
    service = BookmarkService(storage: storage);
    editionService = EditionService(storage: _MemoryEditionStorage());
    diurnal = _publication('2', 2, 'Diurnal');
    arcane = _publication('1', 1, 'Arcane');
  });

  test('sorts, filters, and pluralizes saved publications', () {
    expect(
      sortLexiconPublications([diurnal, arcane]).map((item) => item.word),
      ['Arcane', 'Diurnal'],
    );
    expect(filterLexiconPublications([diurnal, arcane], 'URN'), [diurnal]);
    expect(collectedWordsLabel(1), '1 word collected');
    expect(collectedWordsLabel(2), '2 words collected');
  });

  testWidgets(
    'Free users can open an old saved publication without Archive gating',
    (tester) async {
      await service.save(diurnal);
      await editionService.selectEdition(Editions.gallery);
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entitlementController = EntitlementController(
        EntitlementService(storage: _MemoryEntitlementStorage()),
      );

      await tester.pumpWidget(
        EntitlementScope(
          notifier: entitlementController,
          child: MaterialApp(
            home: MyLexiconScreen(
              bookmarkService: service,
              editionService: editionService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 word collected'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lexicon-row-2')));
      await tester.pumpAndSettle();

      expect(find.text('ADJECTIVE'), findsOneWidget);
      expect(find.text('Definition for Diurnal'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(entitlementController.tier, SubscriptionTier.free);
      expect(find.byType(ProScreen), findsNothing);
      expect(
        tester.widget<PublicationView>(find.byType(PublicationView)).edition,
        same(Editions.gallery),
      );
    },
  );

  testWidgets('removing from a saved publication refreshes My Lexicon', (
    tester,
  ) async {
    await service.save(diurnal);
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MyLexiconScreen(
          bookmarkService: service,
          editionService: editionService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lexicon-row-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.bookmark_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to My Lexicon'));
    await tester.pumpAndSettle();

    expect(find.text('0 words collected'), findsOneWidget);
    expect(find.text('No words saved yet'), findsOneWidget);
    expect(await service.isSaved(diurnal.id), isFalse);
  });

  testWidgets('removing the final bookmark shows the empty state', (
    tester,
  ) async {
    await service.save(diurnal);
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MyLexiconScreen(
          bookmarkService: service,
          editionService: editionService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('remove-bookmark-2')));
    await tester.pumpAndSettle();

    expect(find.text('0 words collected'), findsOneWidget);
    expect(find.text('No words saved yet'), findsOneWidget);
    expect(find.text('Search lexicon...'), findsNothing);
  });
}

DailyPublication _publication(String id, int sequence, String word) {
  return DailyPublication(
    id: id,
    sequence: sequence,
    publicationDate: DateTime.utc(2026, 9, sequence),
    word: word,
    type: 'Adjective',
    phonetic: word.toLowerCase(),
    definition: 'Definition for $word',
    usage: 'Usage for $word',
    synonyms: const ['Literary'],
  );
}

class _MemoryBookmarkStorage implements BookmarkStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
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
  @override
  Future<String?> readTier() async => SubscriptionTier.free.name;

  @override
  Future<void> writeTier(String tier) async {}
}
