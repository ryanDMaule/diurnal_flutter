import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/services/archive_access.dart';

void main() {
  test('Free access contains exactly the five newest publications by date', () {
    final publications = [
      _publication('third', 3, 3),
      _publication('sixth', 6, 6),
      _publication('first', 1, 1),
      _publication('seventh', 7, 7),
      _publication('fourth', 4, 4),
      _publication('second', 2, 2),
      _publication('fifth', 5, 5),
    ];

    final accessible = ArchiveAccess.accessiblePublicationIds(
      publications,
      isPro: false,
    );

    expect(accessible, {'third', 'fourth', 'fifth', 'sixth', 'seventh'});
    expect(accessible, hasLength(5));
    expect(accessible, isNot(contains('first')));
    expect(accessible, isNot(contains('second')));
  });

  test('Pro access contains the full publication history', () {
    final publications = List.generate(
      8,
      (index) => _publication('publication-$index', index + 1, index + 1),
    );

    expect(
      ArchiveAccess.accessiblePublicationIds(publications, isPro: true),
      hasLength(8),
    );
  });

  test('Free access includes all publications when fewer than five exist', () {
    final publications = List.generate(
      4,
      (index) => _publication('publication-$index', index + 1, index + 1),
    );

    expect(
      ArchiveAccess.accessiblePublicationIds(publications, isPro: false),
      hasLength(4),
    );
  });

  test('access uses dates rather than sequence or wrapping', () {
    final publications = [
      _publication('old-high-sequence', 999, 1),
      for (var day = 2; day <= 6; day++) _publication('recent-$day', day, day),
    ];

    final accessible = ArchiveAccess.accessiblePublicationIds(
      publications.reversed,
      isPro: false,
    );

    expect(accessible, isNot(contains('old-high-sequence')));
    expect(
      accessible,
      containsAll(List.generate(5, (index) => 'recent-${index + 2}')),
    );
  });
}

DailyPublication _publication(String id, int sequence, int day) =>
    DailyPublication(
      id: id,
      sequence: sequence,
      publicationDate: DateTime.utc(2026, 9, day),
      word: 'Word $id',
      type: 'Noun',
      phonetic: id,
      definition: 'Definition for $id',
      usage: 'Usage for $id',
      synonyms: const ['Literary'],
    );
