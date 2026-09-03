import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MatchStorage {
  Future<int?> readBestMilliseconds();

  Future<void> writeBestMilliseconds(int milliseconds);
}

class SharedPreferencesMatchStorage implements MatchStorage {
  SharedPreferencesMatchStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'diurnus.matchBestMilliseconds';
  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> readBestMilliseconds() => _preferences.getInt(storageKey);

  @override
  Future<void> writeBestMilliseconds(int milliseconds) =>
      _preferences.setInt(storageKey, milliseconds);
}

class MatchCompletion {
  const MatchCompletion({
    required this.elapsedMilliseconds,
    required this.personalBestMilliseconds,
    required this.isNewBest,
  });

  final int elapsedMilliseconds;
  final int personalBestMilliseconds;
  final bool isNewBest;
}

class MatchService {
  MatchService({MatchStorage? storage})
    : _storage = storage ?? SharedPreferencesMatchStorage();

  final MatchStorage _storage;

  Future<int?> personalBestMilliseconds() async {
    final value = await _storage.readBestMilliseconds();
    return value != null && value > 0 ? value : null;
  }

  Future<MatchCompletion> complete(int elapsedMilliseconds) async {
    if (elapsedMilliseconds <= 0) {
      throw ArgumentError.value(elapsedMilliseconds, 'elapsedMilliseconds');
    }
    final previous = await personalBestMilliseconds();
    final isNewBest = previous == null || elapsedMilliseconds < previous;
    if (isNewBest) {
      await _storage.writeBestMilliseconds(elapsedMilliseconds);
    }
    return MatchCompletion(
      elapsedMilliseconds: elapsedMilliseconds,
      personalBestMilliseconds: isNewBest ? elapsedMilliseconds : previous,
      isNewBest: isNewBest,
    );
  }
}

class MatchElapsedTime {
  MatchElapsedTime({required int Function() rawElapsedMilliseconds})
    : _rawElapsedMilliseconds = rawElapsedMilliseconds;

  static const incorrectMatchPenaltyMilliseconds = 1000;
  final int Function() _rawElapsedMilliseconds;
  int _penaltyMilliseconds = 0;

  int get penaltyMilliseconds => _penaltyMilliseconds;
  int get elapsedMilliseconds =>
      _rawElapsedMilliseconds() + _penaltyMilliseconds;

  void addIncorrectMatchPenalty() {
    _penaltyMilliseconds += incorrectMatchPenaltyMilliseconds;
  }
}

String formatMatchTime(int milliseconds) {
  final value = formatMatchTimer(milliseconds);
  return value.contains(':') ? value : '${value}s';
}

String formatMatchTimer(int milliseconds) {
  final tenths = milliseconds ~/ 100;
  final minutes = tenths ~/ 600;
  final secondsTenths = tenths % 600;
  if (minutes == 0) return '${secondsTenths ~/ 10}.${secondsTenths % 10}';
  final seconds = secondsTenths ~/ 10;
  return '$minutes:${seconds.toString().padLeft(2, '0')}.${secondsTenths % 10}';
}
