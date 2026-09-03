import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/services/entitlement_service.dart';

void main() {
  test('missing entitlement defaults to Free', () async {
    final service = EntitlementService(storage: _EntitlementStorage());

    expect(await service.load(), SubscriptionTier.free);
  });

  test('stored Pro restores as Pro', () async {
    final storage = _EntitlementStorage()..value = 'pro';

    expect(
      await EntitlementService(storage: storage).load(),
      SubscriptionTier.pro,
    );
  });

  test('invalid entitlement safely falls back to Free', () async {
    final storage = _EntitlementStorage()..value = 'premium';

    expect(
      await EntitlementService(storage: storage).load(),
      SubscriptionTier.free,
    );
  });

  test('changing tier persists its stable identifier', () async {
    final storage = _EntitlementStorage();
    final service = EntitlementService(storage: storage);

    await service.save(SubscriptionTier.pro);
    expect(storage.value, 'pro');
    expect(
      await EntitlementService(storage: storage).load(),
      SubscriptionTier.pro,
    );
  });

  test('controller updates reactively and exposes isPro', () async {
    final storage = _EntitlementStorage();
    final controller = EntitlementController(
      EntitlementService(storage: storage),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.load();
    expect(controller.tier, SubscriptionTier.free);
    expect(controller.isPro, isFalse);
    await controller.update(SubscriptionTier.pro);
    expect(controller.tier, SubscriptionTier.pro);
    expect(controller.isPro, isTrue);
    expect(storage.value, 'pro');
    expect(notifications, 2);
  });

  test('SharedPreferences key is namespaced', () {
    expect(
      SharedPreferencesEntitlementStorage.storageKey,
      'diurnus.subscriptionTier',
    );
  });
}

class _EntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
}
