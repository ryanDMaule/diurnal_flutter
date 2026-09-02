import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/screens/archive_screen.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/publication_api_service.dart';

void main() {
  late _MemoryBookmarkStorage bookmarkStorage;
  late BookmarkService bookmarkService;
  late EditionService editionService;

  setUp(() {
    bookmarkStorage = _MemoryBookmarkStorage();
    bookmarkService = BookmarkService(storage: bookmarkStorage);
    editionService = EditionService(storage: _MemoryEditionStorage());
  });

  testWidgets('Archive appears in the menu and opens above it', (tester) async {
    final service = _apiReturning(const []);
    await tester.binding.setSurfaceSize(const Size(700, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MenuScreen(
          archiveApiService: service,
          bookmarkService: bookmarkService,
          editionService: editionService,
        ),
      ),
    );

    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Every word, every day'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.byType(ArchiveScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
  });

  testWidgets('sorts newest first and groups August and September', (
    tester,
  ) async {
    await _pumpArchive(
      tester,
      _apiReturning([
        _publication('august', 1, 'Anfractuous', '2026-08-31'),
        _publication('september', 2, 'Apocryphal', '2026-09-02'),
        _publication('diurnal', 3, 'Diurnal', '2026-09-01'),
      ]),
      bookmarkService,
      editionService,
    );

    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    expect(find.text('AUGUST 2026'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('archive-row-september'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('archive-row-diurnal'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('archive-row-diurnal'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('archive-row-august'))).dy,
      ),
    );
  });

  testWidgets('rows have fixed height and definitions use two-line ellipsis', (
    tester,
  ) async {
    await _pumpArchive(
      tester,
      _apiReturning([
        _publication(
          'long',
          4,
          'Circumlocutory',
          '2026-09-02',
          definition: List.filled(
            30,
            'A deliberately long definition',
          ).join(' '),
        ),
      ]),
      bookmarkService,
      editionService,
    );

    expect(
      tester.getSize(find.byKey(const Key('archive-row-long'))).height,
      118,
    );
    final definition = tester.widget<Text>(
      find.byKey(const Key('archive-definition-long')),
    );
    expect(definition.maxLines, 2);
    expect(definition.overflow, TextOverflow.ellipsis);
  });

  testWidgets('shows the empty state for a successful empty response', (
    tester,
  ) async {
    await _pumpArchive(
      tester,
      _apiReturning(const []),
      bookmarkService,
      editionService,
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(
      find.text('Published words will appear here as they become available.'),
      findsOneWidget,
    );
    expect(find.text('Archive unavailable'), findsNothing);
  });

  testWidgets('shows a distinct error state with retry', (tester) async {
    final service = PublicationApiService(
      client: MockClient((request) async => http.Response('Error', 500)),
    );
    await _pumpArchive(tester, service, bookmarkService, editionService);

    expect(find.text('Archive unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);
  });

  testWidgets(
    'opens the supplied snapshot without requesting the Today endpoint',
    (tester) async {
      final requestedUris = <Uri>[];
      final service = PublicationApiService(
        client: MockClient((request) async {
          requestedUris.add(request.url);
          return http.Response(
            jsonEncode([
              _publication('history', 34, 'Apocryphal', '2026-09-02'),
            ]),
            200,
          );
        }),
      );
      await _pumpArchive(tester, service, bookmarkService, editionService);

      await tester.tap(find.byKey(const Key('archive-row-history')));
      await tester.pumpAndSettle();

      expect(find.text('Apocryphal'), findsOneWidget);
      expect(find.text('Definition for Apocryphal'), findsOneWidget);
      expect(find.text('September 2, 2026'), findsOneWidget);
      expect(find.text('#34'), findsOneWidget);
      expect(find.byTooltip('Back to Archive'), findsOneWidget);
      expect(requestedUris, [PublicationApiService.publicationsUri]);

      await tester.tap(find.byIcon(CupertinoIcons.bookmark));
      await tester.pumpAndSettle();
      expect(await bookmarkService.isSaved('history'), isTrue);
    },
  );
}

Future<void> _pumpArchive(
  WidgetTester tester,
  PublicationApiService apiService,
  BookmarkService bookmarkService,
  EditionService editionService,
) async {
  await tester.binding.setSurfaceSize(const Size(700, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ArchiveScreen(
        apiService: apiService,
        bookmarkService: bookmarkService,
        editionService: editionService,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PublicationApiService _apiReturning(List<Map<String, dynamic>> publications) {
  return PublicationApiService(
    client: MockClient(
      (request) async => http.Response(jsonEncode(publications), 200),
    ),
  );
}

Map<String, dynamic> _publication(
  String id,
  int sequence,
  String word,
  String date, {
  String? definition,
}) {
  return {
    'id': id,
    'sequence': sequence,
    'publicationDate': date,
    'word': word,
    'type': 'Adjective',
    'phonetic': word.toLowerCase(),
    'definition': definition ?? 'Definition for $word',
    'usage': 'Usage for $word',
    'synonyms': ['Literary'],
  };
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
