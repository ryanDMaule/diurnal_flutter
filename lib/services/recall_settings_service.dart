import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recall_settings.dart';

abstract interface class RecallSettingsStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesRecallSettingsStorage implements RecallSettingsStorage {
  SharedPreferencesRecallSettingsStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class RecallSettingsService {
  RecallSettingsService({RecallSettingsStorage? storage})
    : _storage = storage ?? SharedPreferencesRecallSettingsStorage();

  static const _storageKey = 'diurnus.recallSettings';
  final RecallSettingsStorage _storage;

  Future<RecallSettings> load() async {
    final stored = await _storage.read(_storageKey);
    if (stored == null || stored.isEmpty) return RecallSettings.defaults;
    final decoded = json.decode(stored);
    if (decoded is! Map<String, dynamic>) return RecallSettings.defaults;
    return RecallSettings.fromJson(decoded);
  }

  Future<void> save(RecallSettings settings) =>
      _storage.write(_storageKey, json.encode(settings.toJson()));
}
