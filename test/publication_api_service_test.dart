import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/services/publication_api_service.dart';

void main() {
  test(
    'fetches and parses publication snapshots with DailyPublication',
    () async {
      late Uri requestedUri;
      final service = PublicationApiService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('''
          [{
            "id": "publication-2",
            "sequence": 2,
            "publicationDate": "2026-09-02",
            "word": "Apocryphal",
            "type": "Adjective",
            "phonetic": "uh-pok-ruh-fuhl",
            "definition": "Of doubtful authenticity.",
            "usage": "An apocryphal account.",
            "synonyms": ["Dubious"]
          }]
        ''', 200);
        }),
      );

      final publications = await service.fetchPublications();

      expect(requestedUri, PublicationApiService.publicationsUri);
      expect(publications.single.id, 'publication-2');
      expect(publications.single.sequence, 2);
      expect(publications.single.publicationDate, DateTime.utc(2026, 9, 2));
      expect(publications.single.word, 'Apocryphal');
    },
  );

  test('reports non-success responses as API errors', () async {
    final service = PublicationApiService(
      client: MockClient((request) async => http.Response('Unavailable', 503)),
    );

    expect(
      service.fetchPublications,
      throwsA(
        isA<PublicationApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
  });
}
