import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/services/widget_sync_service.dart';

void main() {
  test(
    'publication sync preserves the existing widget cache contract',
    () async {
      final cache = _MemoryWidgetCache();
      final service = WidgetSyncService(cache: cache);
      const publication = DailyPublication(
        id: 'publication-1',
        sequence: 1,
        publicationDate: null,
        word: 'Diurnal',
        type: 'Adjective',
        phonetic: 'di·ur·nal',
        definition: 'Active during the daytime.',
        usage: 'A diurnal rhythm.',
        synonyms: ['Daily'],
      );

      await service.syncPublication(publication);

      expect(cache.values, {
        WidgetSyncService.wordKey: 'Diurnal',
        WidgetSyncService.typeKey: 'Adjective',
        WidgetSyncService.phoneticKey: 'di·ur·nal',
        WidgetSyncService.definitionKey: 'Active during the daytime.',
      });
      expect(cache.redrawCount, 1);
    },
  );

  test('Edition sync caches its stable id and redraws immediately', () async {
    final cache = _MemoryWidgetCache();
    final service = WidgetSyncService(cache: cache);

    await service.syncEdition(Editions.evergreen);

    expect(cache.values, {WidgetSyncService.editionKey: 'evergreen'});
    expect(cache.redrawCount, 1);
  });
}

class _MemoryWidgetCache implements WidgetCache {
  final values = <String, String>{};
  int redrawCount = 0;

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> redraw() async {
    redrawCount++;
  }
}
