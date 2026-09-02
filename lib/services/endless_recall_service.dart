import 'package:shared_preferences/shared_preferences.dart';

abstract interface class EndlessRecallStorage {
  Future<int?> readBest();

  Future<void> writeBest(int score);
}

class SharedPreferencesEndlessRecallStorage implements EndlessRecallStorage {
  SharedPreferencesEndlessRecallStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'diurnus.endlessRecallBest';
  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> readBest() => _preferences.getInt(_key);

  @override
  Future<void> writeBest(int score) => _preferences.setInt(_key, score);
}

class EndlessRecallResult {
  const EndlessRecallResult({
    required this.score,
    required this.personalBest,
    required this.isNewBest,
  });

  final int score;
  final int? personalBest;
  final bool isNewBest;
}

class EndlessRecallService {
  EndlessRecallService({EndlessRecallStorage? storage})
    : _storage = storage ?? SharedPreferencesEndlessRecallStorage();

  final EndlessRecallStorage _storage;

  Future<int?> personalBest() async {
    final best = await _storage.readBest();
    return best != null && best > 0 ? best : null;
  }

  Future<EndlessRecallResult> completeRun(int score) async {
    final previousBest = await personalBest();
    final isNewBest =
        score > 0 && (previousBest == null || score > previousBest);
    if (isNewBest) await _storage.writeBest(score);
    return EndlessRecallResult(
      score: score,
      personalBest: isNewBest ? score : previousBest,
      isNewBest: isNewBest,
    );
  }
}
