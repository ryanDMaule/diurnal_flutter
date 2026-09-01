import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';

void main() {
  const response = <String, dynamic>{
    'id': 'publication-1',
    'sequence': 1,
    'publicationDate': '2026-09-01',
    'word': 'Diurnal',
    'type': 'Adjective',
    'phonetic': 'diurnal',
    'definition': 'Active during the daytime.',
    'usage': 'Most people follow a diurnal schedule.',
    'synonyms': ['Daily', 'Daytime', 'Circadian'],
  };

  test('parses a publication response', () {
    final publication = DailyPublication.fromJson(response);

    expect(publication.id, 'publication-1');
    expect(publication.sequence, 1);
    expect(publication.publicationDate, DateTime.utc(2026, 9, 1));
    expect(publication.word, 'Diurnal');
    expect(publication.type, 'Adjective');
    expect(publication.phonetic, 'diurnal');
    expect(publication.definition, 'Active during the daytime.');
    expect(publication.usage, 'Most people follow a diurnal schedule.');
    expect(publication.synonyms, ['Daily', 'Daytime', 'Circadian']);
  });

  test('rejects an invalid publication date', () {
    expect(
      () => DailyPublication.fromJson({
        ...response,
        'publicationDate': '2026-02-30',
      }),
      throwsFormatException,
    );
  });

  test('local fallback does not claim authoritative metadata', () {
    expect(DailyPublication.localFallback.id, isNull);
    expect(DailyPublication.localFallback.sequence, isNull);
    expect(DailyPublication.localFallback.publicationDate, isNull);
    expect(DailyPublication.localFallback.word, 'Diurnal');
  });
}
