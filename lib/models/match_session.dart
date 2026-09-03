import 'dart:math';

import 'daily_publication.dart';

enum MatchCardType { word, definition }

class MatchCard {
  const MatchCard({
    required this.id,
    required this.subjectId,
    required this.type,
    required this.text,
  });

  final String id;
  final String subjectId;
  final MatchCardType type;
  final String text;

  bool matches(MatchCard other) =>
      subjectId == other.subjectId && type != other.type;
}

class MatchSession {
  const MatchSession({required this.cards, required this.subjectIds});

  final List<MatchCard> cards;
  final Set<String> subjectIds;

  int get pairCount => subjectIds.length;
  bool get isAvailable => pairCount >= 2;
}

class MatchSessionGenerator {
  MatchSessionGenerator({Random? random}) : _random = random ?? Random();

  static const pairLimit = 4;
  static const maximumDefinitionLength = 140;
  final Random _random;

  MatchSession generate({
    required Iterable<DailyPublication> publications,
    Set<String> avoidSubjectIds = const {},
  }) {
    final byId = <String, DailyPublication>{};
    for (final publication in publications) {
      final id = publication.id;
      if (id == null ||
          publication.word.trim().isEmpty ||
          publication.definition.trim().isEmpty ||
          publication.definition.length > maximumDefinitionLength) {
        continue;
      }
      byId.putIfAbsent(id, () => publication);
    }

    final eligible = byId.values.toList();
    final preferred =
        eligible
            .where((publication) => !avoidSubjectIds.contains(publication.id))
            .toList()
          ..shuffle(_random);
    final avoided =
        eligible
            .where((publication) => avoidSubjectIds.contains(publication.id))
            .toList()
          ..shuffle(_random);
    final subjects = [...preferred, ...avoided].take(pairLimit).toList();
    final cards = <MatchCard>[
      for (final subject in subjects) ...[
        MatchCard(
          id: '${subject.id}:word',
          subjectId: subject.id!,
          type: MatchCardType.word,
          text: subject.word,
        ),
        MatchCard(
          id: '${subject.id}:definition',
          subjectId: subject.id!,
          type: MatchCardType.definition,
          text: subject.definition,
        ),
      ],
    ]..shuffle(_random);

    return MatchSession(
      cards: List.unmodifiable(cards),
      subjectIds: Set.unmodifiable(subjects.map((subject) => subject.id!)),
    );
  }
}
