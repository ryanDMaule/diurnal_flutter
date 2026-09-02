import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/recall_question.dart';

void main() {
  test('uses every Archive subject once before beginning another cycle', () {
    final archive = List.generate(3, _publication);
    final cycle = EndlessRecallQuestionCycle(
      publications: archive,
      generator: RecallSessionGenerator(random: Random(2)),
      random: Random(3),
    );

    final firstCycle = List.generate(3, (_) => cycle.next()!.subject.id);
    final secondCycle = List.generate(3, (_) => cycle.next()!.subject.id);

    expect(firstCycle.toSet(), archive.map((item) => item.id).toSet());
    expect(secondCycle.toSet(), archive.map((item) => item.id).toSet());
    expect(secondCycle.first, isNot(firstCycle.last));
  });

  test('small Archive pools cycle safely and regenerate questions', () {
    final publication = _publication(0);
    final cycle = EndlessRecallQuestionCycle(
      publications: [publication],
      generator: RecallSessionGenerator(random: Random(5)),
      random: Random(6),
    );

    final questions = List.generate(5, (_) => cycle.next()!);
    expect(
      questions.every((question) => question.subject.id == publication.id),
      isTrue,
    );
    expect(questions, everyElement(isNotNull));
  });

  test('all supported valid question types are eligible', () {
    final publication = _publication(0);
    final generator = RecallSessionGenerator(random: Random(8));
    final seen = <RecallQuestionType>{};
    for (var index = 0; index < 60; index++) {
      seen.add(
        generator
            .generateQuestion(
              subject: publication,
              distractorPool: List.generate(4, _publication),
            )!
            .type,
      );
    }
    expect(seen, RecallQuestionType.values.toSet());
  });
}

DailyPublication _publication(int index) => DailyPublication(
  id: 'publication-$index',
  sequence: index + 1,
  publicationDate: DateTime.utc(2026, 9, index + 1),
  word: 'Word$index',
  type: 'Adjective',
  phonetic: 'word',
  definition: 'Definition $index',
  usage: 'Usage $index',
  synonyms: ['Synonym$index'],
);
