import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/today_screen.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  testWidgets(
    'pull to refresh replaces offline content with a live publication',
    (tester) async {
      final response = Completer<http.Response>();
      var requests = 0;
      final service = PublicationApiService(
        client: MockClient((request) {
          requests++;
          return response.future;
        }),
      );
      await _pumpToday(
        tester,
        service: service,
        initial: TodayPublicationLoad(publication: _cached, isOffline: true),
      );
      expect(find.text('Cached'), findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
      final refresh = tester
          .widget<PublicationView>(find.byType(PublicationView))
          .onRefresh!;
      final refreshFuture = refresh();
      await tester.pump();
      expect(requests, 1);
      response.complete(http.Response(jsonEncode(_fresh.toJson()), 200));
      await refreshFuture;
      await tester.pumpAndSettle();

      expect(find.text('Fresh'), findsOneWidget);
      expect(find.text('Cached'), findsNothing);
    },
  );

  testWidgets('resume after date rollover retries once without overlapping', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 28, 23, 50);
    final response = Completer<http.Response>();
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) {
        requests++;
        return response.future;
      }),
    );
    await _pumpToday(
      tester,
      service: service,
      initial: TodayPublicationLoad(publication: _cached, isOffline: true),
      now: () => now,
    );

    now = DateTime(2026, 9, 29, 0, 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(requests, 1);

    response.complete(http.Response(jsonEncode(_fresh.toJson()), 200));
    await tester.pumpAndSettle();
    expect(find.text('Fresh'), findsOneWidget);
    expect(requests, 1);
  });
}

Future<void> _pumpToday(
  WidgetTester tester, {
  required PublicationApiService service,
  required TodayPublicationLoad initial,
  DateTime Function()? now,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: TodayScreen(
        apiService: service,
        initialPublication: Future.value(initial),
        widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
        now: now,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final _cached = DailyPublication(
  id: 'cached',
  sequence: 1,
  publicationDate: DateTime.utc(2026, 9, 28),
  word: 'Cached',
  type: 'Adjective',
  phonetic: 'cached',
  definition: 'Saved locally.',
  usage: 'A cached publication remained visible.',
  synonyms: const ['Stored'],
);

final _fresh = DailyPublication(
  id: 'fresh',
  sequence: 2,
  publicationDate: DateTime.utc(2026, 9, 29),
  word: 'Fresh',
  type: 'Adjective',
  phonetic: 'fresh',
  definition: 'Newly retrieved.',
  usage: 'A fresh publication arrived.',
  synonyms: const ['New'],
);

class _MemoryWidgetCache implements WidgetCache {
  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<void> saveString(String key, String value) async {}
}
