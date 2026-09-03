import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_tier.dart';

abstract interface class EntitlementStorage {
  Future<String?> readTier();

  Future<void> writeTier(String tier);
}

class SharedPreferencesEntitlementStorage implements EntitlementStorage {
  SharedPreferencesEntitlementStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'diurnus.subscriptionTier';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readTier() => _preferences.getString(storageKey);

  @override
  Future<void> writeTier(String tier) =>
      _preferences.setString(storageKey, tier);
}

class EntitlementService {
  EntitlementService({EntitlementStorage? storage})
    : _storage = storage ?? SharedPreferencesEntitlementStorage();

  final EntitlementStorage _storage;

  Future<SubscriptionTier> load() async {
    final stored = await _storage.readTier();
    return SubscriptionTier.values
            .where((tier) => tier.name == stored)
            .firstOrNull ??
        SubscriptionTier.free;
  }

  Future<void> save(SubscriptionTier tier) => _storage.writeTier(tier.name);
}

class EntitlementController extends ChangeNotifier {
  EntitlementController(this.service);

  final EntitlementService service;
  SubscriptionTier _tier = SubscriptionTier.free;

  SubscriptionTier get tier => _tier;
  bool get isPro => _tier.isPro;

  Future<void> load() async {
    _tier = await service.load();
    notifyListeners();
  }

  Future<void> update(SubscriptionTier tier) async {
    await service.save(tier);
    _tier = tier;
    notifyListeners();
  }
}
