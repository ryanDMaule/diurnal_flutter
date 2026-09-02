import 'package:shared_preferences/shared_preferences.dart';

import '../models/edition.dart';

abstract interface class EditionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesEditionStorage implements EditionStorage {
  SharedPreferencesEditionStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class EditionService {
  EditionService({EditionStorage? storage})
    : _storage = storage ?? SharedPreferencesEditionStorage();

  static const _selectedEditionKey = 'diurnus.selectedEdition';
  final EditionStorage _storage;

  Future<Edition> loadSelectedEdition() async {
    final id = await _storage.read(_selectedEditionKey);
    return Editions.fromId(id);
  }

  Future<void> selectEdition(Edition edition) =>
      _storage.write(_selectedEditionKey, edition.id);
}
