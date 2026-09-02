import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';

void main() {
  late _MemoryRecallProgressStorage storage;
  late RecallProgressService service;

  setUp(() {
    storage = _MemoryRecallProgressStorage();
    service = RecallProgressService(storage: storage);
  });

  test('new publications are Unseen', () async {
    expect(await service.stateFor('new'), RecallProgressState.unseen);
  });

  test('Unseen and Revisit transition correctly on answers', () async {
    await service.recordAnswer('incorrect', wasCorrect: false);
    expect(await service.stateFor('incorrect'), RecallProgressState.revisit);

    await service.recordAnswer('incorrect', wasCorrect: false);
    expect(await service.stateFor('incorrect'), RecallProgressState.revisit);

    await service.recordAnswer('incorrect', wasCorrect: true);
    expect(await service.stateFor('incorrect'), RecallProgressState.recalled);

    await service.recordAnswer('correct', wasCorrect: true);
    expect(await service.stateFor('correct'), RecallProgressState.recalled);
  });

  test('Recalled is sticky after correct or incorrect later answers', () async {
    await service.recordAnswer('sticky', wasCorrect: true);
    await service.recordAnswer('sticky', wasCorrect: false);
    expect(await service.stateFor('sticky'), RecallProgressState.recalled);

    await service.recordAnswer('sticky', wasCorrect: true);
    expect(await service.stateFor('sticky'), RecallProgressState.recalled);
  });

  test(
    'attempted and recalled states persist across service instances',
    () async {
      await service.recordAnswer('revisit', wasCorrect: false);
      await service.recordAnswer('recalled', wasCorrect: true);

      final restarted = RecallProgressService(storage: storage);
      expect(await restarted.stateFor('revisit'), RecallProgressState.revisit);
      expect(
        await restarted.stateFor('recalled'),
        RecallProgressState.recalled,
      );
    },
  );

  test(
    'legacy recalled IDs remain recognised without attempted data',
    () async {
      storage.values['diurnus.recalledPublicationIds'] = jsonEncode(['legacy']);
      expect(await service.stateFor('legacy'), RecallProgressState.recalled);
    },
  );

  test('summary counts only unique currently published Archive IDs', () async {
    await service.recordAnswer('revisit', wasCorrect: false);
    await service.recordAnswer('recalled', wasCorrect: true);
    await service.recordAnswer('not-published', wasCorrect: true);

    final summary = await service.summaryFor([
      _publication('unseen'),
      _publication('revisit'),
      _publication('recalled'),
      _publication('recalled'),
    ]);

    expect(summary.unseen, 1);
    expect(summary.revisit, 1);
    expect(summary.recalled, 1);
    expect(summary.total, 3);
    expect(
      summary.fractionFor(RecallProgressState.unseen),
      closeTo(1 / 3, 0.001),
    );
    expect(
      summary.fractionFor(RecallProgressState.revisit),
      closeTo(1 / 3, 0.001),
    );
    expect(
      summary.fractionFor(RecallProgressState.recalled),
      closeTo(1 / 3, 0.001),
    );
  });

  test('zero-publication summary has safe zero fractions', () async {
    final summary = await service.summaryFor(const []);
    expect(summary.total, 0);
    expect(summary.fractionFor(RecallProgressState.unseen), 0);
    expect(summary.fractionFor(RecallProgressState.revisit), 0);
    expect(summary.fractionFor(RecallProgressState.recalled), 0);
  });

  test('reading and distractor use do not change state', () async {
    final publication = _publication('read-only');
    expect(publication.word, 'Word read-only');
    expect(await service.stateFor('read-only'), RecallProgressState.unseen);
    expect(await service.stateFor('distractor'), RecallProgressState.unseen);
  });

  test('bookmark save and removal do not alter Recall progress', () async {
    final publication = _publication('independent');
    final bookmarks = BookmarkService(storage: _MemoryBookmarkStorage());
    await service.recordAnswer('independent', wasCorrect: true);

    await bookmarks.save(publication);
    await bookmarks.remove(publication.id!);

    expect(await service.stateFor('independent'), RecallProgressState.recalled);
  });
}

DailyPublication _publication(String id) => DailyPublication(
  id: id,
  sequence: 1,
  publicationDate: DateTime.utc(2026, 9, 1),
  word: 'Word $id',
  type: 'Adjective',
  phonetic: id,
  definition: 'Definition $id',
  usage: 'Usage $id',
  synonyms: ['Synonym $id'],
);

class _MemoryRecallProgressStorage implements RecallProgressStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _MemoryBookmarkStorage implements BookmarkStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
