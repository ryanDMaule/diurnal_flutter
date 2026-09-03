import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diurnul/models/match_session.dart';
import 'package:diurnul/screens/match_result_screen.dart';
import 'package:diurnul/screens/match_ready_screen.dart';
import 'package:diurnul/screens/match_session_screen.dart';
import 'package:diurnul/services/match_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  late _ProgressStorage progressStorage;
  late RecallProgressService progressService;
  late _MatchStorage matchStorage;

  setUp(() {
    progressStorage = _ProgressStorage();
    progressService = RecallProgressService(storage: progressStorage);
    matchStorage = _MatchStorage();
  });

  testWidgets(
    'selection, same-type reselection, and wrong pair are non-punitive',
    (tester) async {
      final elapsedTime = MatchElapsedTime(rawElapsedMilliseconds: () => 250);
      await _pumpMatch(
        tester,
        progressService,
        matchStorage,
        elapsedTime: elapsedTime,
      );

      await tester.tap(find.byKey(const Key('match-card-a:word')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('match-card-b:word')));
      await tester.pump();
      expect(elapsedTime.penaltyMilliseconds, 0);
      await tester.tap(find.byKey(const Key('match-card-a:definition')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(elapsedTime.penaltyMilliseconds, 1000);
      expect(find.text('+1 sec'), findsOneWidget);
      expect(find.text('1.2'), findsOneWidget);
      expect(await progressService.stateFor('a'), RecallProgressState.unseen);
      expect(await progressService.stateFor('b'), RecallProgressState.unseen);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('+1 sec'), findsNothing);
      expect(find.byType(MatchSessionScreen), findsOneWidget);
    },
  );

  testWidgets(
    'correct pairs become recalled, disappear, and complete session',
    (tester) async {
      final elapsedTime = MatchElapsedTime(rawElapsedMilliseconds: () => 250);
      await _pumpMatch(
        tester,
        progressService,
        matchStorage,
        elapsedTime: elapsedTime,
      );

      await _match(tester, 'a');
      expect(elapsedTime.penaltyMilliseconds, 0);
      expect(await progressService.stateFor('a'), RecallProgressState.recalled);
      expect(
        tester
            .widget<AnimatedOpacity>(find.byKey(const Key('match-card-a:word')))
            .opacity,
        0,
      );
      await _match(tester, 'b');

      expect(find.byType(MatchResultScreen), findsOneWidget);
      expect(find.text('Match complete'), findsOneWidget);
      expect(find.text('New personal best'), findsOneWidget);
      expect(await progressService.stateFor('b'), RecallProgressState.recalled);
      expect(matchStorage.value, isNotNull);

      await tester.tap(find.byKey(const Key('match-play-again')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchSessionScreen), findsOneWidget);
      expect(find.byType(MatchReadyScreen), findsNothing);
      expect(find.byKey(const Key('match-timer')), findsOneWidget);
    },
  );

  testWidgets('multiple wrong matches affect displayed and completed time', (
    tester,
  ) async {
    final elapsedTime = MatchElapsedTime(rawElapsedMilliseconds: () => 250);
    await _pumpMatch(
      tester,
      progressService,
      matchStorage,
      elapsedTime: elapsedTime,
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.byKey(const Key('match-card-a:word')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('match-card-b:definition')));
      await tester.pump(const Duration(milliseconds: 160));
    }
    expect(elapsedTime.penaltyMilliseconds, 2000);
    expect(find.text('2.2'), findsOneWidget);

    await _match(tester, 'a');
    await _match(tester, 'b');
    final result = tester.widget<MatchResultScreen>(
      find.byType(MatchResultScreen),
    );
    expect(result.completion.elapsedMilliseconds, 2250);
    expect(matchStorage.value, 2250);
  });

  testWidgets('reduce animations completes without transition delays', (
    tester,
  ) async {
    final elapsedTime = MatchElapsedTime(rawElapsedMilliseconds: () => 500);
    await _pumpMatch(
      tester,
      progressService,
      matchStorage,
      disableAnimations: true,
      elapsedTime: elapsedTime,
    );

    await tester.tap(find.byKey(const Key('match-card-a:word')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-card-b:definition')));
    await tester.pump();
    expect(elapsedTime.penaltyMilliseconds, 1000);
    expect(find.text('+1 sec'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('+1 sec'), findsNothing);

    await tester.tap(find.byKey(const Key('match-card-a:word')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-card-a:definition')));
    await tester.pump();

    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const Key('match-card-a:word')))
          .opacity,
      0,
    );
  });
}

Future<void> _match(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('match-card-$id:word')));
  await tester.pump();
  await tester.tap(find.byKey(Key('match-card-$id:definition')));
  await tester.pump(const Duration(milliseconds: 220));
  await tester.pumpAndSettle();
}

Future<void> _pumpMatch(
  WidgetTester tester,
  RecallProgressService progressService,
  _MatchStorage matchStorage, {
  bool disableAnimations = false,
  MatchElapsedTime? elapsedTime,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const cards = [
    MatchCard(
      id: 'a:word',
      subjectId: 'a',
      type: MatchCardType.word,
      text: 'Alpha',
    ),
    MatchCard(
      id: 'b:definition',
      subjectId: 'b',
      type: MatchCardType.definition,
      text: 'The second exact definition.',
    ),
    MatchCard(
      id: 'b:word',
      subjectId: 'b',
      type: MatchCardType.word,
      text: 'Beta',
    ),
    MatchCard(
      id: 'a:definition',
      subjectId: 'a',
      type: MatchCardType.definition,
      text: 'The first exact definition.',
    ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MatchSessionScreen(
          session: const MatchSession(cards: cards, subjectIds: {'a', 'b'}),
          matchService: MatchService(storage: matchStorage),
          progressService: progressService,
          onPlayAgain: (_) async =>
              const MatchSession(cards: cards, subjectIds: {'a', 'b'}),
          onFinished: () async {},
          elapsedTime: elapsedTime,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _ProgressStorage implements RecallProgressStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _MatchStorage implements MatchStorage {
  int? value;

  @override
  Future<int?> readBestMilliseconds() async => value;

  @override
  Future<void> writeBestMilliseconds(int milliseconds) async {
    value = milliseconds;
  }
}
