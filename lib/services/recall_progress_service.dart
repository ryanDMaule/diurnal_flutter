import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RecallProgressStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesRecallProgressStorage implements RecallProgressStorage {
  SharedPreferencesRecallProgressStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class RecallProgressService {
  RecallProgressService({RecallProgressStorage? storage})
    : _storage = storage ?? SharedPreferencesRecallProgressStorage();

  static const _storageKey = 'diurnus.recalledPublicationIds';
  final RecallProgressStorage _storage;

  Future<Set<String>> recalledPublicationIds() async {
    final stored = await _storage.read(_storageKey);
    if (stored == null || stored.isEmpty) return {};
    final decoded = json.decode(stored);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw const FormatException('Invalid Recall progress storage.');
    }
    return decoded.cast<String>().toSet();
  }

  Future<bool> isRecalled(String publicationId) async =>
      (await recalledPublicationIds()).contains(publicationId);

  Future<void> markRecalled(String publicationId) async {
    final recalled = await recalledPublicationIds();
    if (recalled.add(publicationId)) {
      final sorted = recalled.toList()..sort();
      await _storage.write(_storageKey, json.encode(sorted));
    }
  }
}
