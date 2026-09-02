import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

abstract interface class AppSettingsStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesAppSettingsStorage implements AppSettingsStorage {
  SharedPreferencesAppSettingsStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class AppSettingsService {
  AppSettingsService({AppSettingsStorage? storage})
    : _storage = storage ?? SharedPreferencesAppSettingsStorage();

  static const storageKey = 'diurnus.appSettings';
  final AppSettingsStorage _storage;

  Future<AppSettings> load() async {
    final stored = await _storage.read(storageKey);
    if (stored == null || stored.isEmpty) return AppSettings.defaults;
    try {
      final decoded = json.decode(stored);
      if (decoded is! Map<String, dynamic>) return AppSettings.defaults;
      return AppSettings.fromJson(decoded);
    } on FormatException {
      return AppSettings.defaults;
    }
  }

  Future<void> save(AppSettings settings) =>
      _storage.write(storageKey, json.encode(settings.toJson()));
}
