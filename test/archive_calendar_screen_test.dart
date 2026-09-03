import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/screens/archive_calendar_screen.dart';
import 'package:diurnul/screens/archive_screen.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/screens/saved_publication_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';

void main() {
  late BookmarkService bookmarkService;
  late EditionService editionService;
  late List<DailyPublication> publications;

  setUp(() {
    bookmarkService = BookmarkService(storage: _MemoryBookmarkStorage());
    editionService = EditionService(storage: _MemoryEditionStorage());
    publications = [
      _publication('newest', 34, 'Apocryphal', 2026, 9, 7),
      _publication('september', 33, 'Diurnal', 2026, 9, 1),
      _publication('earliest', 1, 'Anfractuous', 2026, 8, 5),
    ];
  });

  testWidgets('Archive calendar control opens the newest publication month', (
    tester,
  ) async {
    var requestCount = 0;
    final apiService = PublicationApiService(
      client: MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode(publications.map((item) => item.toJson()).toList()),
          200,
        );
      }),
    );
    await _setTestSize(tester);
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

    expect(find.byKey(const Key('open-archive-calendar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-archive-calendar')));
    await tester.pumpAndSettle();

    expect(find.byType(ArchiveCalendarScreen), findsOneWidget);
    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    expect(requestCount, 1);
  });

  testWidgets('month navigation is bounded by earliest and newest months', (
    tester,
  ) async {
    await _pumpCalendar(tester, publications, bookmarkService, editionService);

    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    expect(_iconButton(tester, const Key('next-month')).onPressed, isNull);
    expect(
      _iconButton(tester, const Key('previous-month')).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('previous-month')));
    await tester.pump();

    expect(find.text('AUGUST 2026'), findsOneWidget);
    expect(_iconButton(tester, const Key('previous-month')).onPressed, isNull);
    expect(_iconButton(tester, const Key('next-month')).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('next-month')));
    await tester.pump();
    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
  });

  testWidgets('only published dates receive indicators and can open details', (
    tester,
  ) async {
    await _pumpCalendar(tester, publications, bookmarkService, editionService);

    expect(
      find.byKey(const Key('publication-indicator-2026-09-07')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('publication-indicator-2026-09-01')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('publication-indicator-2026-09-08')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('calendar-day-2026-09-08')));
    await tester.pumpAndSettle();
    expect(find.byType(ArchiveCalendarScreen), findsOneWidget);
    expect(find.text('#34'), findsNothing);

    await tester.tap(find.byKey(const Key('calendar-day-2026-09-07')));
    await tester.pumpAndSettle();
    expect(find.text('Apocryphal'), findsOneWidget);
    expect(find.text('#34'), findsOneWidget);
    expect(find.text('September 7, 2026'), findsOneWidget);
    expect(find.byTooltip('Back to Calendar'), findsOneWidget);
  });

  testWidgets('returning from a snapshot preserves the viewed calendar month', (
    tester,
  ) async {
    await _pumpCalendar(tester, publications, bookmarkService, editionService);
    await tester.tap(find.byKey(const Key('previous-month')));
    await tester.pump();
    expect(find.text('AUGUST 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-day-2026-08-05')));
    await tester.pumpAndSettle();
    expect(find.text('Anfractuous'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Calendar'));
    await tester.pumpAndSettle();
    expect(find.byType(ArchiveCalendarScreen), findsOneWidget);
    expect(find.text('AUGUST 2026'), findsOneWidget);
  });

  testWidgets('published dates expose descriptive semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCalendar(tester, publications, bookmarkService, editionService);

    final node = tester.getSemantics(
      find.byKey(const Key('calendar-day-2026-09-07')),
    );
    expect(node.label, contains('7 September 2026, Apocryphal'));
    semantics.dispose();
  });

  testWidgets('calendar gates old dates for Free and opens them for Pro', (
    tester,
  ) async {
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    final history = [
      for (var day = 1; day <= 7; day++)
        _publication('day-$day', day, 'Word $day', 2026, 9, day),
    ];
    await _pumpCalendar(
      tester,
      history,
      bookmarkService,
      editionService,
      entitlementController: controller,
    );

    expect(
      find.byKey(const Key('publication-indicator-2026-09-01')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('calendar-day-2026-09-07')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPublicationScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Calendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-day-2026-09-01')));
    await tester.pumpAndSettle();
    expect(find.byType(ProScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Calendar'));
    await tester.pumpAndSettle();

    await controller.update(SubscriptionTier.pro);
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-day-2026-09-01')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPublicationScreen), findsOneWidget);
  });
}

IconButton _iconButton(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key));

Future<void> _pumpCalendar(
  WidgetTester tester,
  List<DailyPublication> publications,
  BookmarkService bookmarkService,
  EditionService editionService, {
  EntitlementController? entitlementController,
}) async {
  await _setTestSize(tester);
  final app = MaterialApp(
    home: ArchiveCalendarScreen(
      publications: publications,
      bookmarkService: bookmarkService,
      editionService: editionService,
    ),
  );
  await tester.pumpWidget(
    entitlementController == null
        ? app
        : EntitlementScope(notifier: entitlementController, child: app),
  );
  await tester.pumpAndSettle();
}

Future<void> _setTestSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(700, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

DailyPublication _publication(
  String id,
  int sequence,
  String word,
  int year,
  int month,
  int day,
) {
  return DailyPublication(
    id: id,
    sequence: sequence,
    publicationDate: DateTime.utc(year, month, day),
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
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async {
    value = tier;
  }
}
