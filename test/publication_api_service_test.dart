import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diurnul/models/daily_publication.dart';
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

  test('successful today publication is persisted completely', () async {
    final storage = _MemoryTodayPublicationStorage();
    final service = PublicationApiService(
      client: MockClient((request) async => http.Response(_todayResponse, 200)),
      todayStorage: storage,
    );

    final result = await service.loadTodayPublication();

    expect(result.isOffline, isFalse);
    expect(result.publication.id, 'publication-28');
    expect(result.publication.sequence, 1);
    expect(result.publication.publicationDate, DateTime.utc(2026, 9, 28));
    expect(
      storage.values[PublicationApiService.todayPublicationStorageKey],
      isNotEmpty,
    );
  });

  test('network failure uses real cache across service instances', () async {
    final storage = _MemoryTodayPublicationStorage();
    final online = PublicationApiService(
      client: MockClient((request) async => http.Response(_todayResponse, 200)),
      todayStorage: storage,
    );
    await online.loadTodayPublication();
    final storedBeforeFailure =
        storage.values[PublicationApiService.todayPublicationStorageKey];

    final offline = PublicationApiService(
      client: MockClient((request) async => throw Exception('offline')),
      todayStorage: storage,
    );
    final result = await offline.loadTodayPublication();

    expect(result.isOffline, isTrue);
    expect(result.publication.id, 'publication-28');
    expect(result.publication.word, 'Liminal');
    expect(
      storage.values[PublicationApiService.todayPublicationStorageKey],
      storedBeforeFailure,
    );
  });

  test('structured 404 uses the cached real publication', () async {
    final storage = _MemoryTodayPublicationStorage();
    await PublicationApiService(
      client: MockClient((request) async => http.Response(_todayResponse, 200)),
      todayStorage: storage,
    ).loadTodayPublication();

    final service = PublicationApiService(
      client: MockClient(
        (request) async => http.Response(
          '{"error":"No publication for the current date"}',
          404,
        ),
      ),
      todayStorage: storage,
    );
    final result = await service.loadTodayPublication();

    expect(result.isOffline, isTrue);
    expect(result.publication.id, 'publication-28');
    expect(result.publication.sequence, 1);
  });

  test('Diurnal fallback is used and never persisted without a cache', () async {
    final storage = _MemoryTodayPublicationStorage();
    final service = PublicationApiService(
      client: MockClient((request) async => http.Response('Unavailable', 503)),
      todayStorage: storage,
    );

    final result = await service.loadTodayPublication();

    expect(result.publication, same(DailyPublication.localFallback));
    expect(result.isOffline, isTrue);
    expect(storage.values, isEmpty);
  });

  test('malformed cache safely falls back to Diurnal', () async {
    final storage = _MemoryTodayPublicationStorage()
      ..values[PublicationApiService.todayPublicationStorageKey] =
          '{"id":"incomplete"}';
    final service = PublicationApiService(
      client: MockClient((request) async => http.Response('Unavailable', 503)),
      todayStorage: storage,
    );

    final result = await service.loadTodayPublication();

    expect(result.publication, same(DailyPublication.localFallback));
    expect(result.isOffline, isTrue);
  });
}

const _todayResponse = '''
{
  "id": "publication-28",
  "sequence": 1,
  "publicationDate": "2026-09-28",
  "word": "Liminal",
  "type": "Adjective",
  "phonetic": "lim-uh-nuhl",
  "definition": "Occupying a position at a boundary or threshold.",
  "usage": "They paused in the liminal hour before dawn.",
  "synonyms": ["Transitional", "Threshold"]
}
''';

class _MemoryTodayPublicationStorage implements TodayPublicationStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
