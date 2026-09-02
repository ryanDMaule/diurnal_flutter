import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_publication.dart';

enum RecallProgressState { unseen, revisit, recalled }

class RecallProgressSummary {
  const RecallProgressSummary({
    required this.unseen,
    required this.revisit,
    required this.recalled,
  });

  final int unseen;
  final int revisit;
  final int recalled;

  int get total => unseen + revisit + recalled;

  double fractionFor(RecallProgressState state) {
    if (total == 0) return 0;
    return switch (state) {
      RecallProgressState.unseen => unseen / total,
      RecallProgressState.revisit => revisit / total,
      RecallProgressState.recalled => recalled / total,
    };
  }
}

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
  static const _attemptedStorageKey = 'diurnus.attemptedPublicationIds';
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

  Future<RecallProgressState> stateFor(String publicationId) async {
    final recalled = await recalledPublicationIds();
    if (recalled.contains(publicationId)) return RecallProgressState.recalled;
    final attempted = await _publicationIds(_attemptedStorageKey);
    return attempted.contains(publicationId)
        ? RecallProgressState.revisit
        : RecallProgressState.unseen;
  }

  Future<void> recordAnswer(
    String publicationId, {
    required bool wasCorrect,
  }) async {
    final attempted = await _publicationIds(_attemptedStorageKey);
    if (attempted.add(publicationId)) {
      await _writeIds(_attemptedStorageKey, attempted);
    }
    if (wasCorrect) await markRecalled(publicationId);
  }

  Future<void> markRecalled(String publicationId) async {
    final attempted = await _publicationIds(_attemptedStorageKey);
    if (attempted.add(publicationId)) {
      await _writeIds(_attemptedStorageKey, attempted);
    }
    final recalled = await recalledPublicationIds();
    if (recalled.add(publicationId)) {
      await _writeIds(_storageKey, recalled);
    }
  }

  Future<void> clear() async {
    await _writeIds(_attemptedStorageKey, {});
    await _writeIds(_storageKey, {});
  }

  Future<RecallProgressSummary> summaryFor(
    Iterable<DailyPublication> publications,
  ) async {
    final attempted = await _publicationIds(_attemptedStorageKey);
    final recalled = await recalledPublicationIds();
    var unseenCount = 0;
    var revisitCount = 0;
    var recalledCount = 0;
    final visibleIds = <String>{};

    for (final publication in publications) {
      final id = publication.id;
      if (id == null || !visibleIds.add(id)) continue;
      if (recalled.contains(id)) {
        recalledCount++;
      } else if (attempted.contains(id)) {
        revisitCount++;
      } else {
        unseenCount++;
      }
    }

    return RecallProgressSummary(
      unseen: unseenCount,
      revisit: revisitCount,
      recalled: recalledCount,
    );
  }

  Future<List<DailyPublication>> publicationsInStates(
    Iterable<DailyPublication> publications,
    Set<RecallProgressState> states,
  ) async {
    final attempted = await _publicationIds(_attemptedStorageKey);
    final recalled = await recalledPublicationIds();
    return List.unmodifiable(
      publications.where((publication) {
        final id = publication.id;
        if (id == null) return false;
        final state = recalled.contains(id)
            ? RecallProgressState.recalled
            : attempted.contains(id)
            ? RecallProgressState.revisit
            : RecallProgressState.unseen;
        return states.contains(state);
      }),
    );
  }

  Future<Set<String>> _publicationIds(String key) async {
    final stored = await _storage.read(key);
    if (stored == null || stored.isEmpty) return {};
    final decoded = json.decode(stored);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw const FormatException('Invalid Recall progress storage.');
    }
    return decoded.cast<String>().toSet();
  }

  Future<void> _writeIds(String key, Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _storage.write(key, json.encode(sorted));
  }
}
