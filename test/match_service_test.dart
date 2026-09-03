import 'package:flutter_test/flutter_test.dart';
import 'package:diurnul/services/match_service.dart';

void main() {
  test('first completion stores a namespaced numeric best', () async {
    final storage = _MemoryMatchStorage();
    final result = await MatchService(storage: storage).complete(12400);

    expect(result.isNewBest, isTrue);
    expect(result.personalBestMilliseconds, 12400);
    expect(storage.value, 12400);
    expect(
      SharedPreferencesMatchStorage.storageKey,
      'diurnus.matchBestMilliseconds',
    );
  });

  test(
    'faster completion replaces best and slower completion does not',
    () async {
      final storage = _MemoryMatchStorage()..value = 12400;
      final service = MatchService(storage: storage);

      expect((await service.complete(13000)).isNewBest, isFalse);
      expect(storage.value, 12400);
      expect((await service.complete(10800)).isNewBest, isTrue);
      expect(storage.value, 10800);
      expect(
        await MatchService(storage: storage).personalBestMilliseconds(),
        10800,
      );
    },
  );

  test('abandoned run cannot change best without completion', () async {
    final storage = _MemoryMatchStorage()..value = 9000;
    final service = MatchService(storage: storage);

    expect(await service.personalBestMilliseconds(), 9000);
    expect(storage.value, 9000);
  });

  test('formats tenths and long sessions', () {
    expect(formatMatchTime(0), '0.0s');
    expect(formatMatchTime(12499), '12.4s');
    expect(formatMatchTime(65499), '1:05.4');
    expect(formatMatchTimer(12499), '12.4');
  });

  test('incorrect penalties accumulate separately from raw elapsed time', () {
    var rawMilliseconds = 12400;
    final elapsed = MatchElapsedTime(
      rawElapsedMilliseconds: () => rawMilliseconds,
    );

    expect(elapsed.elapsedMilliseconds, 12400);
    elapsed.addIncorrectMatchPenalty();
    elapsed.addIncorrectMatchPenalty();
    expect(elapsed.penaltyMilliseconds, 2000);
    expect(elapsed.elapsedMilliseconds, 14400);
    rawMilliseconds = 13000;
    expect(elapsed.elapsedMilliseconds, 15000);
  });

  test('personal best compares the penalised completion time', () async {
    final storage = _MemoryMatchStorage()..value = 14000;
    final elapsed = MatchElapsedTime(rawElapsedMilliseconds: () => 12500)
      ..addIncorrectMatchPenalty()
      ..addIncorrectMatchPenalty();

    final result = await MatchService(
      storage: storage,
    ).complete(elapsed.elapsedMilliseconds);

    expect(result.elapsedMilliseconds, 14500);
    expect(result.isNewBest, isFalse);
    expect(storage.value, 14000);
  });
}

class _MemoryMatchStorage implements MatchStorage {
  int? value;

  @override
  Future<int?> readBestMilliseconds() async => value;

  @override
  Future<void> writeBestMilliseconds(int milliseconds) async {
    value = milliseconds;
  }
}
