import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/recall_question.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/recall_result_screen.dart';
import 'package:diurnul/screens/recall_screen.dart';
import 'package:diurnul/screens/recall_session_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  late _MemoryBookmarkStorage bookmarkStorage;
  late BookmarkService bookmarkService;
  late _MemoryRecallProgressStorage progressStorage;
  late RecallProgressService progressService;
  late List<DailyPublication> archive;

  setUp(() {
    bookmarkStorage = _MemoryBookmarkStorage();
    bookmarkService = BookmarkService(storage: bookmarkStorage);
    progressStorage = _MemoryRecallProgressStorage();
    progressService = RecallProgressService(storage: progressStorage);
    archive = List.generate(
      6,
      (index) => _publication('archive-$index', index + 1, 'Word$index'),
    );
  });

  test('result wording omits zero-value portions for any session length', () {
    expect(recallResultSummary(5, 5), '5 correct');
    expect(recallResultSummary(4, 5), '4 correct · 1 to revisit');
    expect(recallResultSummary(2, 5), '2 correct · 3 to revisit');
    expect(recallResultSummary(0, 5), '5 to revisit');
    expect(recallResultSummary(2, 3), '2 correct · 1 to revisit');
    expect(recallResultSummary(0, 1), '1 to revisit');
  });

  testWidgets('Recall appears in Menu and opens its landing screen', (
    tester,
  ) async {
    await _setTestSize(tester, height: 1200);
    await tester.pumpWidget(
      MaterialApp(
        home: MenuScreen(
          archiveApiService: _apiReturning(archive),
          bookmarkService: bookmarkService,
          recallProgressService: progressService,
        ),
      ),
    );

    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Words worth remembering'), findsOneWidget);
    await tester.tap(find.text('Recall'));
    await tester.pumpAndSettle();
    expect(find.byType(RecallScreen), findsOneWidget);
    expect(find.text('Daily Recall'), findsOneWidget);
    expect(find.text('My Lexicon Recall'), findsOneWidget);
  });

  testWidgets('Daily Recall starts with five unique Archive subjects', (
    tester,
  ) async {
    await _pumpLanding(tester, archive, bookmarkService, progressService);
    await tester.tap(find.byKey(const Key('daily-recall')));
    await tester.pumpAndSettle();

    final session = tester.widget<RecallSessionScreen>(
      find.byType(RecallSessionScreen),
    );
    expect(session.questions, hasLength(5));
    expect(
      session.questions.map((question) => question.subject.id).toSet(),
      hasLength(5),
    );
  });

  testWidgets(
    'My Lexicon uses only saved subjects and supports short sessions',
    (tester) async {
      await bookmarkService.save(archive[0]);
      await bookmarkService.save(archive[1]);
      await bookmarkService.save(archive[2]);
      await _pumpLanding(tester, archive, bookmarkService, progressService);

      await tester.tap(find.byKey(const Key('lexicon-recall')));
      await tester.pumpAndSettle();
      final questions = tester
          .widget<RecallSessionScreen>(find.byType(RecallSessionScreen))
          .questions;

      expect(questions, hasLength(3));
      expect(questions.map((question) => question.subject.id).toSet(), {
        'archive-0',
        'archive-1',
        'archive-2',
      });
    },
  );

  testWidgets('one saved word creates one question', (tester) async {
    await bookmarkService.save(archive.first);
    await _pumpLanding(tester, archive, bookmarkService, progressService);
    await tester.tap(find.byKey(const Key('lexicon-recall')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<RecallSessionScreen>(find.byType(RecallSessionScreen))
          .questions,
      hasLength(1),
    );
  });

  testWidgets('five or more saves produce five unique saved subjects', (
    tester,
  ) async {
    for (final publication in archive) {
      await bookmarkService.save(publication);
    }
    await _pumpLanding(tester, archive, bookmarkService, progressService);
    await tester.tap(find.byKey(const Key('lexicon-recall')));
    await tester.pumpAndSettle();

    final questions = tester
        .widget<RecallSessionScreen>(find.byType(RecallSessionScreen))
        .questions;
    final savedIds = archive.map((publication) => publication.id).toSet();
    expect(questions, hasLength(5));
    expect(
      questions.map((question) => question.subject.id).toSet(),
      hasLength(5),
    );
    expect(
      questions.every((question) => savedIds.contains(question.subject.id)),
      isTrue,
    );
  });

  testWidgets(
    'empty Lexicon shows its distinct minimal state without API use',
    (tester) async {
      var requests = 0;
      final api = PublicationApiService(
        client: MockClient((request) async {
          requests++;
          return http.Response('[]', 200);
        }),
      );
      await _pumpLandingWithApi(tester, api, bookmarkService, progressService);
      await tester.tap(find.byKey(const Key('lexicon-recall')));
      await tester.pumpAndSettle();

      expect(find.text('Your Lexicon is empty'), findsOneWidget);
      expect(find.text('Save words to practise them here.'), findsOneWidget);
      expect(requests, 1);
    },
  );

  testWidgets('API failure is distinct and offers Retry', (tester) async {
    final api = PublicationApiService(
      client: MockClient((request) async => http.Response('Error', 500)),
    );
    await _pumpLandingWithApi(tester, api, bookmarkService, progressService);
    await tester.tap(find.byKey(const Key('daily-recall')));
    await tester.pumpAndSettle();

    expect(find.text('Recall unavailable'), findsOneWidget);
    expect(find.byKey(const Key('retry-recall')), findsOneWidget);
    expect(find.text('Your Lexicon is empty'), findsNothing);
  });

  testWidgets(
    'correct and incorrect feedback remains inline and locks answers',
    (tester) async {
      final questions = [
        _question(archive[0], correct: 'Correct one', wrong: 'Wrong one'),
        _question(archive[1], correct: 'Correct two', wrong: 'Wrong two'),
      ];
      await _setTestSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: RecallSessionScreen(
            questions: questions,
            progressService: progressService,
            onRecallAgain: (_) async => questions,
          ),
        ),
      );

      await tester.tap(find.text('Wrong one'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('incorrect-feedback')), findsOneWidget);
      expect(find.byKey(const Key('correct-feedback')), findsOneWidget);
      expect(find.text(archive[0].word), findsOneWidget);
      expect(find.byType(RecallSessionScreen), findsOneWidget);
      expect(await progressService.isRecalled(archive[0].id!), isFalse);
      expect(
        await progressService.stateFor(archive[0].id!),
        RecallProgressState.revisit,
      );

      await tester.tap(find.byKey(const Key('recall-continue')));
      await tester.pumpAndSettle();
      expect(find.text('02 / 02'), findsOneWidget);
      await tester.tap(find.text('Correct two'));
      await tester.pumpAndSettle();
      expect(await progressService.isRecalled(archive[1].id!), isTrue);
      expect(await progressService.isRecalled(archive[0].id!), isFalse);
      expect(await progressService.isRecalled(archive[2].id!), isFalse);
    },
  );

  testWidgets('final Continue shows score and Finish returns to landing', (
    tester,
  ) async {
    await _pumpLanding(
      tester,
      [archive.first],
      bookmarkService,
      progressService,
    );
    await tester.pumpAndSettle();
    expect(find.text('0 of 1 recalled'), findsOneWidget);
    await tester.tap(find.byKey(const Key('daily-recall')));
    await tester.pumpAndSettle();
    final question = tester
        .widget<RecallSessionScreen>(find.byType(RecallSessionScreen))
        .questions
        .single;

    await tester.tap(find.text(question.correctAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recall-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(RecallResultScreen), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('Recall complete'), findsOneWidget);
    expect(find.text('1 correct'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finish-recall')));
    await tester.pumpAndSettle();
    expect(find.byType(RecallScreen), findsOneWidget);
    expect(find.text('1 of 1 recalled'), findsOneWidget);
    expect(find.text('Unseen 0 · Revisit 0 · Recalled 1'), findsOneWidget);
    expect(find.byKey(const Key('recall-progress-unseen')), findsNothing);
    expect(find.byKey(const Key('recall-progress-revisit')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('recall-progress-recalled'))).width,
      closeTo(
        tester
            .getSize(find.byKey(const Key('recall-segmented-progress')))
            .width,
        0.01,
      ),
    );
  });

  testWidgets(
    'landing shows Archive-wide Unseen, Revisit, and Recalled counts',
    (tester) async {
      await progressService.recordAnswer(archive[0].id!, wasCorrect: false);
      await progressService.recordAnswer(archive[1].id!, wasCorrect: true);
      await progressService.recordAnswer('not-in-archive', wasCorrect: true);

      await _pumpLanding(tester, archive, bookmarkService, progressService);
      await tester.pumpAndSettle();

      expect(find.text('1 of 6 recalled'), findsOneWidget);
      expect(find.text('Unseen 4 · Revisit 1 · Recalled 1'), findsOneWidget);
      expect(find.byKey(const Key('recall-progress-unseen')), findsOneWidget);
      expect(find.byKey(const Key('recall-progress-revisit')), findsOneWidget);
      expect(find.byKey(const Key('recall-progress-recalled')), findsOneWidget);

      final trackWidth = tester
          .getSize(find.byKey(const Key('recall-segmented-progress')))
          .width;
      final unseenWidth = tester
          .getSize(find.byKey(const Key('recall-progress-unseen')))
          .width;
      final revisitWidth = tester
          .getSize(find.byKey(const Key('recall-progress-revisit')))
          .width;
      final recalledWidth = tester
          .getSize(find.byKey(const Key('recall-progress-recalled')))
          .width;
      expect(
        unseenWidth + revisitWidth + recalledWidth,
        closeTo(trackWidth, 0.01),
      );
      expect(unseenWidth / trackWidth, closeTo(4 / 6, 0.01));
      expect(revisitWidth / trackWidth, closeTo(1 / 6, 0.01));
      expect(recalledWidth / trackWidth, closeTo(1 / 6, 0.01));
    },
  );

  testWidgets('landing refreshes Revisit after an incorrect subject answer', (
    tester,
  ) async {
    await _pumpLanding(
      tester,
      archive.take(2).toList(),
      bookmarkService,
      progressService,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily-recall')));
    await tester.pumpAndSettle();

    var session = tester.widget<RecallSessionScreen>(
      find.byType(RecallSessionScreen),
    );
    var question = session.questions.first;
    final wrongAnswer = question.answers.firstWhere(
      (answer) => answer != question.correctAnswer,
    );
    await tester.tap(find.text(wrongAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recall-continue')));
    await tester.pumpAndSettle();

    session = tester.widget<RecallSessionScreen>(
      find.byType(RecallSessionScreen),
    );
    question = session.questions[1];
    await tester.tap(find.text(question.correctAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recall-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finish-recall')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 recalled'), findsOneWidget);
    expect(find.text('Unseen 0 · Revisit 1 · Recalled 1'), findsOneWidget);
  });

  testWidgets(
    'Recall again regenerates Daily Recall without previous subjects when possible',
    (tester) async {
      final largerArchive = List.generate(
        10,
        (index) => _publication('daily-$index', index + 1, 'Daily$index'),
      );
      await _pumpLanding(
        tester,
        largerArchive,
        bookmarkService,
        progressService,
      );
      await tester.tap(find.byKey(const Key('daily-recall')));
      await tester.pumpAndSettle();
      final firstIds = tester
          .widget<RecallSessionScreen>(find.byType(RecallSessionScreen))
          .questions
          .map((question) => question.subject.id)
          .toSet();

      await _completeSession(tester);
      await tester.tap(find.byKey(const Key('recall-again')));
      await tester.pumpAndSettle();

      final secondSession = tester.widget<RecallSessionScreen>(
        find.byType(RecallSessionScreen),
      );
      final secondIds = secondSession.questions
          .map((question) => question.subject.id)
          .toSet();
      expect(secondSession.questions, hasLength(5));
      expect(secondIds.intersection(firstIds), isEmpty);
      expect(secondIds.every((id) => id!.startsWith('daily-')), isTrue);
    },
  );

  testWidgets(
    'Recall again preserves Lexicon mode and safely repeats small pool',
    (tester) async {
      final saved = archive.take(2).toList();
      for (final publication in saved) {
        await bookmarkService.save(publication);
      }
      await _pumpLanding(tester, archive, bookmarkService, progressService);
      await tester.tap(find.byKey(const Key('lexicon-recall')));
      await tester.pumpAndSettle();

      await _completeSession(tester);
      await tester.tap(find.byKey(const Key('recall-again')));
      await tester.pumpAndSettle();

      final secondSession = tester.widget<RecallSessionScreen>(
        find.byType(RecallSessionScreen),
      );
      expect(secondSession.questions, hasLength(2));
      expect(
        secondSession.questions.map((question) => question.subject.id).toSet(),
        {saved[0].id, saved[1].id},
      );
    },
  );
}

Future<void> _completeSession(WidgetTester tester) async {
  while (find.byType(RecallSessionScreen).evaluate().isNotEmpty) {
    final session = tester.widget<RecallSessionScreen>(
      find.byType(RecallSessionScreen),
    );
    final counter = tester.widget<Text>(
      find.byKey(const Key('recall-question-counter')),
    );
    final currentNumber = int.parse(counter.data!.substring(0, 2));
    final question = session.questions[currentNumber - 1];
    await tester.tap(find.text(question.correctAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recall-continue')));
    await tester.pumpAndSettle();
  }
  expect(find.byType(RecallResultScreen), findsOneWidget);
}

RecallQuestion _question(
  DailyPublication publication, {
  required String correct,
  required String wrong,
}) {
  return RecallQuestion(
    subject: publication,
    type: RecallQuestionType.wordToDefinition,
    content: publication.word,
    prompt: 'Which definition belongs to this word?',
    answers: [correct, wrong],
    correctAnswer: correct,
  );
}

Future<void> _pumpLanding(
  WidgetTester tester,
  List<DailyPublication> archive,
  BookmarkService bookmarkService,
  RecallProgressService progressService,
) => _pumpLandingWithApi(
  tester,
  _apiReturning(archive),
  bookmarkService,
  progressService,
);

Future<void> _pumpLandingWithApi(
  WidgetTester tester,
  PublicationApiService apiService,
  BookmarkService bookmarkService,
  RecallProgressService progressService,
) async {
  await _setTestSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: RecallScreen(
        apiService: apiService,
        bookmarkService: bookmarkService,
        progressService: progressService,
        sessionGenerator: RecallSessionGenerator(random: Random(4)),
      ),
    ),
  );
}

Future<void> _setTestSize(WidgetTester tester, {double height = 1000}) async {
  await tester.binding.setSurfaceSize(Size(700, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

PublicationApiService _apiReturning(List<DailyPublication> publications) {
  return PublicationApiService(
    client: MockClient(
      (request) async => http.Response(
        jsonEncode(publications.map((item) => item.toJson()).toList()),
        200,
      ),
    ),
  );
}

DailyPublication _publication(String id, int sequence, String word) {
  return DailyPublication(
    id: id,
    sequence: sequence,
    publicationDate: DateTime.utc(2026, 9, sequence),
    word: word,
    type: 'Adjective',
    phonetic: word.toLowerCase(),
    definition: 'Definition $word',
    usage: 'Usage $word',
    synonyms: ['Synonym$word'],
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

class _MemoryRecallProgressStorage implements RecallProgressStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
