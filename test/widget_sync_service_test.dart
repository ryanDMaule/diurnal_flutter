import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/services/edition_entitlement_coordinator.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
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

  test(
    'entitlement changes sync the effective Edition without replacing storage',
    () async {
      final editionStorage = _MemoryEditionStorage();
      final editionService = EditionService(storage: editionStorage);
      await editionService.selectEdition(Editions.gallery);
      final cache = _MemoryWidgetCache();
      final entitlementController = EntitlementController(
        EntitlementService(storage: _MemoryEntitlementStorage()),
      );
      final coordinator = EditionEntitlementCoordinator(
        entitlementController: entitlementController,
        editionService: editionService,
        widgetSyncService: WidgetSyncService(cache: cache),
      )..start();
      addTearDown(coordinator.dispose);

      await entitlementController.update(SubscriptionTier.pro);
      await _waitForEdition(cache, 'gallery');
      await entitlementController.update(SubscriptionTier.free);
      await _waitForEdition(cache, 'library');
      expect(
        await editionService.loadSelectedEdition(),
        same(Editions.gallery),
      );
      await entitlementController.update(SubscriptionTier.pro);
      await _waitForEdition(cache, 'gallery');
    },
  );
}

Future<void> _waitForEdition(_MemoryWidgetCache cache, String id) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (cache.values[WidgetSyncService.editionKey] == id) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Widget Edition never became $id.');
}

class _MemoryWidgetCache implements WidgetCache {
  final values = <String, Object>{};
  int redrawCount = 0;

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> redraw() async {
    redrawCount++;
  }
}

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
}
