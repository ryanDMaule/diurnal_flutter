import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/archive_screen.dart';
import 'package:diurnul/screens/my_lexicon_screen.dart';
import 'package:diurnul/screens/recall_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/feature_introduction_service.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  test('feature introduction flags are independent and persistent', () async {
    final storage = _MemoryIntroductionStorage();
    final service = FeatureIntroductionService(storage: storage);

    expect(await service.hasSeen(FeatureIntroduction.archive), isFalse);
    expect(await service.hasSeen(FeatureIntroduction.myLexicon), isFalse);
    expect(await service.hasSeen(FeatureIntroduction.recall), isFalse);

    await service.markSeen(FeatureIntroduction.archive);
    final restored = FeatureIntroductionService(storage: storage);
    expect(await restored.hasSeen(FeatureIntroduction.archive), isTrue);
    expect(await restored.hasSeen(FeatureIntroduction.myLexicon), isFalse);
    expect(await restored.hasSeen(FeatureIntroduction.recall), isFalse);
  });

  testWidgets('Archive introduction appears once and can be reopened', (
    tester,
  ) async {
    final storage = _MemoryIntroductionStorage();
    final introductions = FeatureIntroductionService(storage: storage);
    await _setTestSize(tester, height: 800);

    await tester.pumpWidget(
      MaterialApp(
        home: ArchiveScreen(
          apiService: _apiReturning(const []),
          bookmarkService: BookmarkService(storage: _MemoryBookmarkStorage()),
          editionService: EditionService(storage: _MemoryEditionStorage()),
          introductionService: introductions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every word, kept.'), findsOneWidget);
    expect(find.text('Explore Archive'), findsOneWidget);
    expect(find.byKey(const Key('archive-introduction-sample')), findsNothing);
    await tester.tap(find.text('Explore Archive'));
    await tester.pumpAndSettle();
    expect(await introductions.hasSeen(FeatureIntroduction.archive), isTrue);

    await tester.tap(find.byKey(const Key('archive-introduction-info')));
    await tester.pumpAndSettle();
    expect(find.text('Every word, kept.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-feature-introduction')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: ArchiveScreen(
          apiService: _apiReturning(const []),
          bookmarkService: BookmarkService(storage: _MemoryBookmarkStorage()),
          editionService: EditionService(storage: _MemoryEditionStorage()),
          introductionService: FeatureIntroductionService(storage: storage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Every word, kept.'), findsNothing);
  });

  testWidgets('empty Lexicon explains collecting without hiding empty state', (
    tester,
  ) async {
    final introductions = FeatureIntroductionService(
      storage: _MemoryIntroductionStorage(),
    );
    await _setTestSize(tester, height: 800);
    await tester.pumpWidget(
      MaterialApp(
        home: MyLexiconScreen(
          bookmarkService: BookmarkService(storage: _MemoryBookmarkStorage()),
          editionService: EditionService(storage: _MemoryEditionStorage()),
          introductionService: introductions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Words you choose to keep.'), findsOneWidget);
    expect(find.text('Start collecting'), findsOneWidget);
    expect(find.text('No words saved yet'), findsOneWidget);
    expect(find.byKey(const Key('lexicon-introduction-sample')), findsNothing);
    await tester.tap(find.byKey(const Key('close-feature-introduction')));
    await tester.pumpAndSettle();
    expect(await introductions.hasSeen(FeatureIntroduction.myLexicon), isTrue);
  });

  testWidgets('existing bookmarks suppress automatic Lexicon introduction', (
    tester,
  ) async {
    final bookmarks = BookmarkService(storage: _MemoryBookmarkStorage());
    await bookmarks.save(_publication('saved', 'Sepulchral'));
    final introductions = FeatureIntroductionService(
      storage: _MemoryIntroductionStorage(),
    );
    await _setTestSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MyLexiconScreen(
          bookmarkService: bookmarks,
          editionService: EditionService(storage: _MemoryEditionStorage()),
          introductionService: introductions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Words you choose to keep.'), findsNothing);
    expect(await introductions.hasSeen(FeatureIntroduction.myLexicon), isTrue);
    await tester.tap(find.byKey(const Key('lexicon-introduction-info')));
    await tester.pumpAndSettle();
    expect(find.text('View my words'), findsOneWidget);
    expect(
      find.byKey(const Key('lexicon-introduction-sample')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Recall introduction uses real progress and prior activity suppresses it',
    (tester) async {
      final publication = _publication('recall', 'Laconic');
      final progressStorage = _MemoryProgressStorage();
      final progress = RecallProgressService(storage: progressStorage);
      final introductions = FeatureIntroductionService(
        storage: _MemoryIntroductionStorage(),
      );
      await _setTestSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: RecallScreen(
            apiService: _apiReturning([publication.toJson()]),
            progressService: progress,
            introductionService: introductions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remember what you discover.'), findsOneWidget);
      expect(find.text('Unseen'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.ensureVisible(find.text('Explore Recall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore Recall'));
      await tester.pumpAndSettle();

      await progress.recordAnswer(publication.id!, wasCorrect: false);
      final activityIntroductions = FeatureIntroductionService(
        storage: _MemoryIntroductionStorage(),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: RecallScreen(
            apiService: _apiReturning([publication.toJson()]),
            progressService: progress,
            introductionService: activityIntroductions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remember what you discover.'), findsNothing);
      expect(
        await activityIntroductions.hasSeen(FeatureIntroduction.recall),
        isTrue,
      );
    },
  );
}

Future<void> _setTestSize(WidgetTester tester, {double height = 640}) async {
  await tester.binding.setSurfaceSize(Size(360, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

PublicationApiService _apiReturning(List<Map<String, dynamic>> publications) =>
    PublicationApiService(
      client: MockClient(
        (_) async => http.Response(jsonEncode(publications), 200),
      ),
      archiveStorage: _MemoryArchiveStorage(),
    );

DailyPublication _publication(String id, String word) => DailyPublication(
  id: id,
  sequence: 1,
  publicationDate: DateTime.utc(2026, 9, 1),
  word: word,
  type: 'Adjective',
  phonetic: word.toLowerCase(),
  definition: 'Definition for $word',
  usage: 'Usage for $word',
  synonyms: const ['Brief'],
);

class _MemoryIntroductionStorage implements FeatureIntroductionStorage {
  final Map<String, bool> values = {};

  @override
  Future<bool?> read(String key) async => values[key];

  @override
  Future<void> write(String key, bool value) async => values[key] = value;
}

class _MemoryBookmarkStorage implements BookmarkStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _MemoryProgressStorage implements RecallProgressStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _MemoryArchiveStorage implements ArchivePublicationStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
