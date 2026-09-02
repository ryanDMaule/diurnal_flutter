import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/recall_question.dart';

void main() {
  final archive = List.generate(
    8,
    (index) => _publication('archive-$index', index + 1, 'Word$index'),
  );

  test('Daily Recall generates up to five unique subjects and all types', () {
    final questions = RecallSessionGenerator(
      random: Random(4),
    ).generate(subjects: archive, distractorPool: archive);

    expect(questions, hasLength(5));
    expect(
      questions.map((question) => question.subject.id).toSet(),
      hasLength(5),
    );
    expect(questions.map((question) => question.type).toSet(), {
      RecallQuestionType.wordToDefinition,
      RecallQuestionType.definitionToWord,
      RecallQuestionType.wordToSynonym,
    });
    for (final question in questions) {
      expect(question.answers.toSet(), hasLength(question.answers.length));
      expect(
        question.answers.where((answer) => answer == question.correctAnswer),
        hasLength(1),
      );
      expect(question.answers.length, lessThanOrEqualTo(4));
    }
  });

  test('session size follows the available unique subject pool', () {
    final generator = RecallSessionGenerator(random: Random(2));
    expect(
      generator.generate(subjects: archive.take(1), distractorPool: archive),
      hasLength(1),
    );
    expect(
      generator.generate(subjects: archive.take(3), distractorPool: archive),
      hasLength(3),
    );
    expect(
      generator.generate(subjects: archive, distractorPool: archive),
      hasLength(5),
    );
  });

  test('Lexicon subjects remain saved while Archive supplies distractors', () {
    final saved = archive.take(2).toList();
    final questions = RecallSessionGenerator(
      random: Random(8),
    ).generate(subjects: saved, distractorPool: archive);

    expect(questions.map((question) => question.subject.id).toSet(), {
      'archive-0',
      'archive-1',
    });
    final savedAnswerValues = saved
        .expand(
          (publication) => [
            publication.word,
            publication.definition,
            ...publication.synonyms,
          ],
        )
        .toSet();
    expect(
      questions.expand((question) => question.answers),
      contains(
        predicate<String>((answer) => !savedAnswerValues.contains(answer)),
      ),
    );
  });

  test('missing synonyms fall back to another enabled question type', () {
    final noSynonyms = _publication('plain', 9, 'Plain', synonyms: const []);
    final questions = RecallSessionGenerator(random: Random(1)).generate(
      subjects: [noSynonyms, ...archive.take(2)],
      distractorPool: archive,
    );

    final plainQuestion = questions.singleWhere(
      (question) => question.subject.id == 'plain',
    );
    expect(plainQuestion.type, isNot(RecallQuestionType.wordToSynonym));
  });

  test('answer order is shuffled rather than fixed', () {
    final correctPositions = <int>{};
    for (var seed = 0; seed < 12; seed++) {
      final question = RecallSessionGenerator(
        random: Random(seed),
      ).generate(subjects: [archive.first], distractorPool: archive).single;
      correctPositions.add(question.answers.indexOf(question.correctAnswer));
    }
    expect(correctPositions.length, greaterThan(1));
  });
}

DailyPublication _publication(
  String id,
  int sequence,
  String word, {
  List<String>? synonyms,
}) {
  return DailyPublication(
    id: id,
    sequence: sequence,
    publicationDate: DateTime.utc(2026, 9, sequence),
    word: word,
    type: 'Adjective',
    phonetic: word.toLowerCase(),
    definition: 'Definition $word',
    usage: 'Usage $word',
    synonyms: synonyms ?? ['Synonym$word'],
  );
}
