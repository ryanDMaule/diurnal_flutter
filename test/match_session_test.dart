import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/match_session.dart';

void main() {
  test('generates four distinct word-definition pairs and eight cards', () {
    final publications = List.generate(6, _publication);
    final session = MatchSessionGenerator(
      random: Random(4),
    ).generate(publications: publications);

    expect(session.pairCount, 4);
    expect(session.cards, hasLength(8));
    expect(session.subjectIds, hasLength(4));
    for (final id in session.subjectIds) {
      final cards = session.cards
          .where((card) => card.subjectId == id)
          .toList();
      expect(cards, hasLength(2));
      expect(
        cards.map((card) => card.type).toSet(),
        MatchCardType.values.toSet(),
      );
      final publication = publications.firstWhere((item) => item.id == id);
      expect(
        cards.singleWhere((card) => card.type == MatchCardType.definition).text,
        publication.definition,
      );
    }
  });

  test('excludes invalid, duplicate, and excessively long publications', () {
    final valid = _publication(0);
    final duplicate = _publication(1, id: valid.id);
    final blankWord = _publication(2, word: ' ');
    final blankDefinition = _publication(3, definition: ' ');
    final longDefinition = _publication(
      4,
      definition: 'x' * (MatchSessionGenerator.maximumDefinitionLength + 1),
    );
    final secondValid = _publication(5);

    final session = MatchSessionGenerator(random: Random(1)).generate(
      publications: [
        valid,
        duplicate,
        blankWord,
        blankDefinition,
        longDefinition,
        secondValid,
        DailyPublication.localFallback,
      ],
    );

    expect(session.subjectIds, {valid.id, secondValid.id});
    expect(session.cards, hasLength(4));
  });

  test('uses the largest valid set and reports fewer than two unavailable', () {
    final three = MatchSessionGenerator(
      random: Random(2),
    ).generate(publications: List.generate(3, _publication));
    final one = MatchSessionGenerator(
      random: Random(2),
    ).generate(publications: [_publication(0)]);

    expect(three.pairCount, 3);
    expect(three.cards, hasLength(6));
    expect(three.isAvailable, isTrue);
    expect(one.pairCount, 1);
    expect(one.isAvailable, isFalse);
  });

  test('only opposite card types with the same subject match', () {
    const word = MatchCard(
      id: 'a:word',
      subjectId: 'a',
      type: MatchCardType.word,
      text: 'Word',
    );
    const definition = MatchCard(
      id: 'a:definition',
      subjectId: 'a',
      type: MatchCardType.definition,
      text: 'Definition',
    );
    const otherDefinition = MatchCard(
      id: 'b:definition',
      subjectId: 'b',
      type: MatchCardType.definition,
      text: 'Other',
    );
    const otherWord = MatchCard(
      id: 'b:word',
      subjectId: 'b',
      type: MatchCardType.word,
      text: 'Other word',
    );

    expect(word.matches(definition), isTrue);
    expect(word.matches(otherDefinition), isFalse);
    expect(word.matches(otherWord), isFalse);
  });

  test('replay avoids previous subjects when enough alternatives exist', () {
    final publications = List.generate(8, _publication);
    final generator = MatchSessionGenerator(random: Random(7));
    final first = generator.generate(publications: publications);
    final second = generator.generate(
      publications: publications,
      avoidSubjectIds: first.subjectIds,
    );

    expect(first.subjectIds.intersection(second.subjectIds), isEmpty);
  });
}

DailyPublication _publication(
  int index, {
  String? id,
  String? word,
  String? definition,
}) => DailyPublication(
  id: id ?? 'publication-$index',
  sequence: index + 1,
  publicationDate: DateTime.utc(2026, 9, index + 1),
  word: word ?? 'Word$index',
  type: 'Noun',
  phonetic: 'word',
  definition: definition ?? 'Exact definition number $index.',
  usage: 'Usage',
  synonyms: const ['Synonym'],
);
