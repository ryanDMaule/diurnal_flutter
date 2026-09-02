import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  test('persists recalled publication IDs across service instances', () async {
    final storage = _MemoryRecallProgressStorage();
    final service = RecallProgressService(storage: storage);

    expect(await service.isRecalled('subject'), isFalse);
    await service.markRecalled('subject');

    final restarted = RecallProgressService(storage: storage);
    expect(await restarted.isRecalled('subject'), isTrue);
    expect(await restarted.isRecalled('distractor'), isFalse);
    expect(await restarted.recalledPublicationIds(), {'subject'});
  });
}

class _MemoryRecallProgressStorage implements RecallProgressStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
