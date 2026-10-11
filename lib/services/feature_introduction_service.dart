import 'package:shared_preferences/shared_preferences.dart';

enum FeatureIntroduction { archive, myLexicon, recall }

abstract interface class FeatureIntroductionStorage {
  Future<bool?> read(String key);

  Future<void> write(String key, bool value);
}

class SharedPreferencesFeatureIntroductionStorage
    implements FeatureIntroductionStorage {
  SharedPreferencesFeatureIntroductionStorage({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> read(String key) => _preferences.getBool(key);

  @override
  Future<void> write(String key, bool value) =>
      _preferences.setBool(key, value);
}

class FeatureIntroductionService {
  FeatureIntroductionService({FeatureIntroductionStorage? storage})
    : _storage = storage ?? SharedPreferencesFeatureIntroductionStorage();

  final FeatureIntroductionStorage _storage;

  Future<bool> hasSeen(FeatureIntroduction feature) async =>
      await _storage.read(_key(feature)) ?? false;

  Future<void> markSeen(FeatureIntroduction feature) =>
      _storage.write(_key(feature), true);

  static String _key(FeatureIntroduction feature) =>
      'diurnus.featureIntroduction.${feature.name}.seen';
}
