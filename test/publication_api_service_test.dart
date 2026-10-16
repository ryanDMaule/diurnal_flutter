import 'dart:async';
import 'dart:convert';

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
        archiveStorage: _MemoryArchivePublicationStorage(),
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

  test('Archive timeout is distinct and leaves its cache untouched', () async {
    final storage = _MemoryArchivePublicationStorage()
      ..values[PublicationApiService.archivePublicationsStorageKey] =
          jsonEncode([_archivePublication('one', 1, 'First')]);
    final storedBefore =
        storage.values[PublicationApiService.archivePublicationsStorageKey];
    final pending = Completer<http.Response>();
    final service = PublicationApiService(
      client: MockClient((request) => pending.future),
      archiveStorage: storage,
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      service.fetchPublications(),
      throwsA(isA<PublicationTimeoutException>()),
    );
    expect(
      storage.values[PublicationApiService.archivePublicationsStorageKey],
      storedBefore,
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

  test('current-date Today cache skips the automatic request', () async {
    final storage = _MemoryTodayPublicationStorage()
      ..values[PublicationApiService.todayPublicationStorageKey] =
          _todayResponse;
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response('Unavailable', 503);
      }),
      todayStorage: storage,
      now: () => DateTime(2026, 9, 28, 23, 59),
    );

    final result = await service.loadTodayPublication(
      preferCurrentDateCache: true,
    );

    expect(requests, 0);
    expect(result.publication.id, 'publication-28');
    expect(result.isOffline, isFalse);
    expect(result.failure, isNull);
  });

  test('Today cache uses the London date rather than the device date', () async {
    final storage = _MemoryTodayPublicationStorage()
      ..values[PublicationApiService.todayPublicationStorageKey] =
          _todayResponse;
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response('Unavailable', 503);
      }),
      todayStorage: storage,
      now: () => DateTime.parse('2026-09-29T00:30:00+09:00'),
    );

    final result = await service.loadTodayPublication(
      preferCurrentDateCache: true,
    );

    expect(requests, 0);
    expect(result.publication.id, 'publication-28');
  });

  test('previous-date Today cache still requests the API', () async {
    final storage = _MemoryTodayPublicationStorage()
      ..values[PublicationApiService.todayPublicationStorageKey] =
          _todayResponse;
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response(_todayResponse, 200);
      }),
      todayStorage: storage,
      now: () => DateTime(2026, 9, 29),
    );

    await service.loadTodayPublication(preferCurrentDateCache: true);

    expect(requests, 1);
  });

  test('missing or fallback-only Today state still requests the API', () async {
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response(_todayResponse, 200);
      }),
      todayStorage: _MemoryTodayPublicationStorage(),
      now: () => DateTime(2026, 9, 28),
    );

    final result = await service.loadTodayPublication(
      preferCurrentDateCache: true,
    );

    expect(requests, 1);
    expect(result.publication.id, 'publication-28');
  });

  test('manual Today load bypasses a current-date cache', () async {
    final storage = _MemoryTodayPublicationStorage()
      ..values[PublicationApiService.todayPublicationStorageKey] =
          _todayResponse;
    var requests = 0;
    final service = PublicationApiService(
      client: MockClient((request) async {
        requests++;
        return http.Response(_todayResponse, 200);
      }),
      todayStorage: storage,
      now: () => DateTime(2026, 9, 28),
    );

    await service.loadTodayPublication();

    expect(requests, 1);
  });

  test(
    'Today timeout returns cached publication without replacing it',
    () async {
      final storage = _MemoryTodayPublicationStorage();
      await PublicationApiService(
        client: MockClient(
          (request) async => http.Response(_todayResponse, 200),
        ),
        todayStorage: storage,
      ).loadTodayPublication();
      final storedBefore =
          storage.values[PublicationApiService.todayPublicationStorageKey];
      final pending = Completer<http.Response>();
      final service = PublicationApiService(
        client: MockClient((request) => pending.future),
        todayStorage: storage,
        requestTimeout: const Duration(milliseconds: 10),
      );

      final result = await service.loadTodayPublication();

      expect(result.failure, PublicationLoadFailure.timeout);
      expect(result.publication.id, 'publication-28');
      expect(
        storage.values[PublicationApiService.todayPublicationStorageKey],
        storedBefore,
      );
    },
  );

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
    expect(result.failure, PublicationLoadFailure.connectivity);
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
    expect(result.failure, PublicationLoadFailure.server);
    expect(result.publication.id, 'publication-28');
    expect(result.publication.sequence, 1);
  });

  test(
    'Diurnal fallback is used and never persisted without a cache',
    () async {
      final storage = _MemoryTodayPublicationStorage();
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response('Unavailable', 503),
        ),
        todayStorage: storage,
      );

      final result = await service.loadTodayPublication();

      expect(result.publication, same(DailyPublication.localFallback));
      expect(result.isOffline, isTrue);
      expect(storage.values, isEmpty);
    },
  );

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

  test(
    'successful publications response persists validated collection',
    () async {
      final storage = _MemoryArchivePublicationStorage();
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode([_archivePublication('one', 1, 'First')]),
            200,
          ),
        ),
        archiveStorage: storage,
      );

      final publications = await service.fetchPublications();
      final restored = await PublicationApiService(
        client: MockClient((request) async => throw Exception('offline')),
        archiveStorage: storage,
      ).readCachedPublications();

      expect(publications.single.id, 'one');
      expect(restored!.single.id, 'one');
      expect(restored.single.publicationDate, DateTime.utc(2026, 9, 28));
    },
  );

  test(
    'refresh adds records without duplicates and fresh identity wins',
    () async {
      final storage = _MemoryArchivePublicationStorage()
        ..values[PublicationApiService.archivePublicationsStorageKey] =
            jsonEncode([
              _archivePublication('one', 1, 'Old First'),
              _archivePublication('two', 2, 'Second'),
            ]);
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode([
              _archivePublication('one', 1, 'First'),
              _archivePublication('three', 3, 'Third'),
            ]),
            200,
          ),
        ),
        archiveStorage: storage,
      );

      final publications = await service.fetchPublications();

      expect(publications.map((item) => item.id), ['one', 'two', 'three']);
      expect(publications.first.word, 'First');
    },
  );

  test('Archive excludes future publications from cache and results', () async {
    final storage = _MemoryArchivePublicationStorage();
    final service = PublicationApiService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode([
            _archivePublication('today', 1, 'Today'),
            {
              ..._archivePublication('future', 2, 'Future'),
              'publicationDate': '2026-09-29',
            },
          ]),
          200,
        ),
      ),
      archiveStorage: storage,
      now: () => DateTime(2026, 9, 28, 12),
    );

    final publications = await service.fetchPublications();

    expect(publications.map((item) => item.id), ['today']);
    expect((await service.readCachedPublications())!.map((item) => item.id), [
      'today',
    ]);
  });

  test('Archive future filtering follows the London publication day', () async {
    final service = PublicationApiService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode([
            _archivePublication('today', 1, 'Today'),
            {
              ..._archivePublication('future', 2, 'Future'),
              'publicationDate': '2026-09-29',
            },
          ]),
          200,
        ),
      ),
      archiveStorage: _MemoryArchivePublicationStorage(),
      now: () => DateTime.parse('2026-09-29T00:30:00+09:00'),
    );

    expect(
      (await service.fetchPublications()).map((item) => item.id),
      ['today'],
    );
  });

  test('default timeout allows a Render cold start', () {
    expect(
      PublicationApiService().requestTimeout,
      const Duration(seconds: 60),
    );
  });

  test('clean install accepts the canonical catalogue response metadata', () async {
    final service = PublicationApiService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            ..._archivePublication('canonical-1', 1, 'Canonical'),
            'publicationDate': '2026-10-16',
            'generation': 'diurnus-canonical-2026-10-16-v1',
          }),
          200,
        ),
      ),
      todayStorage: _MemoryTodayPublicationStorage(),
    );

    final result = await service.loadTodayPublication();

    expect(result.isOffline, isFalse);
    expect(result.publication.id, 'canonical-1');
    expect(result.publication.sequence, 1);
    expect(result.publication.publicationDate, DateTime.utc(2026, 10, 16));
  });

  test(
    'Archive freshness expires after its window and at date rollover',
    () async {
      var now = DateTime(2026, 9, 28, 12);
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode([_archivePublication('one', 1, 'First')]),
            200,
          ),
        ),
        archiveStorage: _MemoryArchivePublicationStorage(),
        now: () => now,
      );
      await service.fetchPublications();
      expect(await service.isArchiveCacheFresh(), isTrue);

      now = DateTime(2026, 9, 28, 12, 31);
      expect(await service.isArchiveCacheFresh(), isFalse);

      now = DateTime(2026, 9, 29, 0, 1);
      expect(await service.isArchiveCacheFresh(), isFalse);
    },
  );

  test(
    'smaller successful response does not destroy a healthy cache',
    () async {
      final storage = _MemoryArchivePublicationStorage()
        ..values[PublicationApiService.archivePublicationsStorageKey] =
            jsonEncode([
              _archivePublication('one', 1, 'First'),
              _archivePublication('two', 2, 'Second'),
              _archivePublication('three', 3, 'Third'),
            ]);
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode([_archivePublication('three', 3, 'Third')]),
            200,
          ),
        ),
        archiveStorage: storage,
      );

      final publications = await service.fetchPublications();

      expect(publications.map((item) => item.id), ['one', 'two', 'three']);
      expect((await service.readCachedPublications())!.length, 3);
    },
  );

  test(
    'malformed response does not overwrite a healthy Archive cache',
    () async {
      final storage = _MemoryArchivePublicationStorage()
        ..values[PublicationApiService.archivePublicationsStorageKey] =
            jsonEncode([_archivePublication('one', 1, 'First')]);
      final storedBefore =
          storage.values[PublicationApiService.archivePublicationsStorageKey];
      final service = PublicationApiService(
        client: MockClient(
          (request) async => http.Response('[{"id":"incomplete"}]', 200),
        ),
        archiveStorage: storage,
      );

      await expectLater(service.fetchPublications(), throwsFormatException);

      expect(
        storage.values[PublicationApiService.archivePublicationsStorageKey],
        storedBefore,
      );
      expect((await service.readCachedPublications())!.single.id, 'one');
    },
  );

  test('malformed Archive cache is ignored without crashing', () async {
    final storage = _MemoryArchivePublicationStorage()
      ..values[PublicationApiService.archivePublicationsStorageKey] =
          '[{"id":"incomplete"}]';
    final service = PublicationApiService(archiveStorage: storage);

    expect(await service.readCachedPublications(), isNull);
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

class _MemoryArchivePublicationStorage implements ArchivePublicationStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

Map<String, dynamic> _archivePublication(
  String id,
  int sequence,
  String word,
) => {
  'id': id,
  'sequence': sequence,
  'publicationDate': '2026-09-28',
  'word': word,
  'type': 'Adjective',
  'phonetic': word.toLowerCase(),
  'definition': 'Definition for $word',
  'usage': 'Usage for $word',
  'synonyms': ['Literary'],
};
