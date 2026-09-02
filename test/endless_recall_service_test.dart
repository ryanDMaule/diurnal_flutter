import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/services/endless_recall_service.dart';

void main() {
  test('personal best is absent until a positive completed score', () async {
    final storage = _MemoryEndlessRecallStorage();
    final service = EndlessRecallService(storage: storage);

    expect(await service.personalBest(), isNull);
    final zero = await service.completeRun(0);
    expect(zero.isNewBest, isFalse);
    expect(await service.personalBest(), isNull);
  });

  test('only a greater score replaces the persistent personal best', () async {
    final storage = _MemoryEndlessRecallStorage();
    final service = EndlessRecallService(storage: storage);

    expect((await service.completeRun(12)).isNewBest, isTrue);
    expect((await service.completeRun(8)).isNewBest, isFalse);
    expect((await service.completeRun(12)).isNewBest, isFalse);
    expect((await service.completeRun(13)).isNewBest, isTrue);
    expect(await EndlessRecallService(storage: storage).personalBest(), 13);
  });
}

class _MemoryEndlessRecallStorage implements EndlessRecallStorage {
  int? value;

  @override
  Future<int?> readBest() async => value;

  @override
  Future<void> writeBest(int score) async => value = score;
}
