import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/today_screen.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/sound_effects_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/widgets/publication_view.dart';

import 'support/fake_sound_effects.dart';

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
      expect(
        find.byKey(const Key('today-error-details-button')),
        findsOneWidget,
      );

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
      expect(find.byKey(const Key('today-error-details-button')), findsNothing);
      expect(find.byKey(const Key('today-error-notification')), findsNothing);
    },
  );

  testWidgets(
    'fallback messaging describes refresh failure without claiming offline',
    (tester) async {
      await _pumpToday(
        tester,
        service: PublicationApiService(),
        initial: TodayPublicationLoad(
          publication: DailyPublication.localFallback,
          isOffline: true,
        ),
      );

      expect(find.text('Diurnal'), findsOneWidget);
      expect(
        find.byKey(const Key('today-error-details-button')),
        findsOneWidget,
      );
      expect(find.textContaining('Offline mode'), findsNothing);
    },
  );

  testWidgets('online publication has no recovery banner', (tester) async {
    await _pumpToday(
      tester,
      service: PublicationApiService(),
      initial: TodayPublicationLoad(publication: _fresh, isOffline: false),
    );

    expect(find.textContaining('Unable to refresh'), findsNothing);
    expect(find.textContaining('Offline mode'), findsNothing);
  });

  testWidgets('initial failure notifies briefly and keeps accessible details', (
    tester,
  ) async {
    final initial = Completer<TodayPublicationLoad>();
    await _pumpToday(
      tester,
      service: PublicationApiService(),
      initial: initial.future,
      settle: false,
    );
    initial.complete(
      TodayPublicationLoad(
        publication: _cached,
        isOffline: true,
        failure: PublicationLoadFailure.timeout,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Unable to refresh — showing saved word'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('today-error-notification'))),
      matchesSemantics(
        label: 'Unable to refresh — showing saved word',
        isLiveRegion: true,
      ),
    );
    final button = find.byKey(const Key('today-error-details-button'));
    expect(tester.getSize(button), const Size(48, 48));

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('today-error-notification')), findsNothing);
    expect(button, findsOneWidget);
  });

  testWidgets('warning details are support-safe and copyable', (tester) async {
    String? copiedDetails;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedDetails =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpToday(
      tester,
      service: PublicationApiService(),
      initial: TodayPublicationLoad(
        publication: _cached,
        isOffline: true,
        failure: PublicationLoadFailure.connectivity,
      ),
    );

    await tester.tap(find.byKey(const Key('today-error-details-button')));
    await tester.pumpAndSettle();
    expect(find.text('Publication status'), findsOneWidget);
    expect(find.text('CATEGORY · CONNECTION'), findsOneWidget);
    await tester.tap(find.byKey(const Key('copy-publication-error-details')));
    await tester.pump();
    expect(
      copiedDetails,
      'Publication refresh failed. Category: Connection. '
      'Displaying the last saved daily word.',
    );
    expect(copiedDetails, isNot(contains('http')));
  });

  testWidgets(
    'automatic retries stay quiet while manual failures notify again',
    (tester) async {
      final service = PublicationApiService(
        client: MockClient((_) async => throw Exception('unavailable')),
      );
      await _pumpToday(
        tester,
        service: service,
        initial: TodayPublicationLoad(
          publication: _cached,
          isOffline: true,
          failure: PublicationLoadFailure.connectivity,
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('today-error-notification')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('today-error-notification')), findsNothing);

      final refresh = tester
          .widget<PublicationView>(find.byType(PublicationView))
          .onRefresh!;
      await refresh();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('today-error-notification')), findsOneWidget);
    },
  );

  testWidgets(
    'resume with a current-date cache makes no request or notification',
    (tester) async {
      final storage = _MemoryTodayPublicationStorage()
        ..value = jsonEncode(_cached.toJson());
      var requests = 0;
      final service = PublicationApiService(
        client: MockClient((request) async {
          requests++;
          throw Exception('unavailable');
        }),
        todayStorage: storage,
        now: () => DateTime(2026, 9, 28, 15),
      );
      await _pumpToday(
        tester,
        service: service,
        initial: TodayPublicationLoad(publication: _cached, isOffline: false),
        now: () => DateTime(2026, 9, 28, 15),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(requests, 0);
      expect(find.text('Cached'), findsOneWidget);
      expect(find.byKey(const Key('today-error-notification')), findsNothing);
      expect(find.byKey(const Key('today-error-details-button')), findsNothing);
    },
  );

  testWidgets('bundled fallback on resume still requests the API', (
    tester,
  ) async {
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response(jsonEncode(_cached.toJson()), 200);
      }),
      todayStorage: _MemoryTodayPublicationStorage(),
      now: () => DateTime(2026, 9, 28),
    );
    await _pumpToday(
      tester,
      service: service,
      initial: const TodayPublicationLoad(
        publication: DailyPublication.localFallback,
        isOffline: true,
      ),
      now: () => DateTime(2026, 9, 28),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(find.text('Cached'), findsOneWidget);
  });

  testWidgets('Reduce Animations disables the notification transition', (
    tester,
  ) async {
    final initial = Completer<TodayPublicationLoad>();
    await _pumpToday(
      tester,
      service: PublicationApiService(),
      initial: initial.future,
      settle: false,
      disableAnimations: true,
    );
    initial.complete(
      TodayPublicationLoad(
        publication: _cached,
        isOffline: true,
        failure: PublicationLoadFailure.invalidResponse,
      ),
    );
    await tester.pump();

    final switcher = tester.widget<AnimatedSwitcher>(
      find.ancestor(
        of: find.byKey(const Key('today-error-notification')),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('Today bookmark keeps a 48px target and toggles normally', (
    tester,
  ) async {
    await _pumpToday(
      tester,
      service: PublicationApiService(),
      initial: TodayPublicationLoad(publication: _fresh, isOffline: false),
      soundEffectsService: SoundEffectsService(
        playback: FakeSoundEffectsPlayback(),
      ),
    );

    final control = find.byKey(const Key('publication-bookmark-control'));
    expect(tester.getSize(control), const Size(48, 48));
    expect(
      tester.getSize(find.byIcon(CupertinoIcons.bookmark)).shortestSide,
      30,
    );
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.bookmark_fill), findsOneWidget);
  });

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

  testWidgets('resume detects London rollover before the UTC date changes', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 15, 22, 50);
    var requests = 0;
    final londonToday = _publication(
      id: 'october-15',
      sequence: 1,
      date: DateTime.utc(2026, 10, 15),
      word: 'Earlier',
    );
    final londonTomorrow = _publication(
      id: 'october-16',
      sequence: 2,
      date: DateTime.utc(2026, 10, 16),
      word: 'Canonical',
    );
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response(jsonEncode(londonTomorrow.toJson()), 200);
      }),
      now: () => now,
    );
    await _pumpToday(
      tester,
      service: service,
      initial: TodayPublicationLoad(
        publication: londonToday,
        isOffline: false,
      ),
      now: () => now,
    );

    now = DateTime.utc(2026, 10, 15, 23, 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(find.text('Canonical'), findsOneWidget);
  });
}

Future<void> _pumpToday(
  WidgetTester tester, {
  required PublicationApiService service,
  required FutureOr<TodayPublicationLoad> initial,
  DateTime Function()? now,
  SoundEffectsService? soundEffectsService,
  bool settle = true,
  bool disableAnimations = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: TodayScreen(
        apiService: service,
        initialPublication: Future<TodayPublicationLoad>.value(initial),
        widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
        now: now,
        soundEffectsService: soundEffectsService,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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

DailyPublication _publication({
  required String id,
  required int sequence,
  required DateTime date,
  required String word,
}) => DailyPublication(
  id: id,
  sequence: sequence,
  publicationDate: date,
  word: word,
  type: 'Adjective',
  phonetic: word.toLowerCase(),
  definition: 'Definition for $word.',
  usage: '$word appeared in a sentence.',
  synonyms: const ['Literary'],
);

class _MemoryWidgetCache implements WidgetCache {
  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<void> saveString(String key, String value) async {}
}

class _MemoryTodayPublicationStorage implements TodayPublicationStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}
