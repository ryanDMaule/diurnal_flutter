import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/services/bookmark_service.dart';

void main() {
  late _MemoryBookmarkStorage storage;
  late BookmarkService service;
  late DailyPublication publication;

  setUp(() {
    storage = _MemoryBookmarkStorage();
    service = BookmarkService(storage: storage);
    publication = DailyPublication.fromJson({
      'id': 'publication-1',
      'sequence': 1,
      'publicationDate': '2026-09-01',
      'word': 'Diurnal',
      'type': 'Adjective',
      'phonetic': 'diurnal',
      'definition': 'Active during the daytime.',
      'usage': 'Most people follow a diurnal schedule.',
      'synonyms': ['Daily', 'Daytime', 'Circadian'],
    });
  });

  test('saves and finds a publication across service instances', () async {
    expect(await service.isSaved(publication.id), isFalse);

    await service.save(publication);

    final restoredService = BookmarkService(storage: storage);
    expect(await restoredService.isSaved(publication.id), isTrue);
    expect(await restoredService.getSavedPublications(), hasLength(1));
  });

  test('removes a saved publication', () async {
    await service.save(publication);
    await service.remove(publication.id!);

    expect(await service.isSaved(publication.id), isFalse);
  });

  test(
    'repeated save and remove operations preserve persisted truth',
    () async {
      await service.save(publication);
      await service.remove(publication.id!);
      await service.save(publication);
      expect(await service.isSaved(publication.id), isTrue);

      await service.remove(publication.id!);
      final restartedService = BookmarkService(storage: storage);
      expect(await restartedService.isSaved(publication.id), isFalse);
    },
  );

  test('does not allow fallback content to be saved', () async {
    expect(await service.isSaved(DailyPublication.localFallback.id), isFalse);
    expect(
      () => service.save(DailyPublication.localFallback),
      throwsArgumentError,
    );
  });
}

class _MemoryBookmarkStorage implements BookmarkStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
