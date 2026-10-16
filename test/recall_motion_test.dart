import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/recall_question.dart';
import 'package:diurnul/screens/recall_session_screen.dart';
import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  testWidgets(
    'Recall feedback remains visible but immediate with system reduced motion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RecallSessionScreen(
              questions: const [_question],
              progressService: RecallProgressService(
                storage: _MemoryProgressStorage(),
              ),
              onRecallAgain: (_) async => const [_question],
            ),
          ),
        ),
      );
      await tester.pump();

      final progress = tester.widget<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(progress.duration, Duration.zero);

      await tester.tap(find.text('Correct'));
      await tester.pump();
      final answer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('recall-answer-0')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(answer.duration, Duration.zero);
      expect(find.byKey(const Key('correct-feedback')), findsOneWidget);
      expect(find.byKey(const Key('recall-continue')), findsOneWidget);
    },
  );
}

const _publication = DailyPublication(
  id: 'motion-word',
  sequence: 1,
  publicationDate: null,
  word: 'Laconic',
  type: 'Adjective',
  phonetic: 'la-con-ic',
  definition: 'Using very few words.',
  usage: 'A laconic reply.',
  synonyms: ['Brief'],
);

const _question = RecallQuestion(
  type: RecallQuestionType.wordToDefinition,
  subject: _publication,
  content: 'Laconic',
  prompt: 'Which definition belongs to this word?',
  answers: ['Correct', 'Incorrect'],
  correctAnswer: 'Correct',
);

class _MemoryProgressStorage implements RecallProgressStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
