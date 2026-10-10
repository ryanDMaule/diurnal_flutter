import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_publication.dart';

abstract interface class TodayPublicationStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesTodayPublicationStorage
    implements TodayPublicationStorage {
  SharedPreferencesTodayPublicationStorage({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

abstract interface class ArchivePublicationStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesArchivePublicationStorage
    implements ArchivePublicationStorage {
  SharedPreferencesArchivePublicationStorage({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class TodayPublicationLoad {
  const TodayPublicationLoad({
    required this.publication,
    required this.isOffline,
    this.failure,
  });

  final DailyPublication publication;
  final bool isOffline;
  final PublicationLoadFailure? failure;
}

enum PublicationLoadFailure { connectivity, timeout, invalidResponse }

class PublicationApiService {
  PublicationApiService({
    http.Client? client,
    TodayPublicationStorage? todayStorage,
    ArchivePublicationStorage? archiveStorage,
    this.requestTimeout = const Duration(seconds: 10),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _todayStorage =
           todayStorage ?? SharedPreferencesTodayPublicationStorage(),
       _archiveStorage =
           archiveStorage ?? SharedPreferencesArchivePublicationStorage(),
       _now = now ?? DateTime.now;

  static final Uri wordOfTheDayUri = Uri.parse(
    'https://diurnal-api-7zz8.onrender.com/word',
  );
  static final Uri publicationsUri = wordOfTheDayUri.resolve('/publications');
  static const todayPublicationStorageKey =
      'diurnus.todayPublication.lastSuccessful';
  static const archivePublicationsStorageKey =
      'diurnus.archivePublications.lastSuccessful';
  static const archiveRefreshStorageKey =
      'diurnus.archivePublications.lastSuccessfulRefresh';
  static const archiveFreshness = Duration(minutes: 30);

  final http.Client _client;
  final TodayPublicationStorage _todayStorage;
  final ArchivePublicationStorage _archiveStorage;
  final Duration requestTimeout;
  final DateTime Function() _now;

  Future<TodayPublicationLoad> loadTodayPublication() async {
    try {
      final response = await _client
          .get(wordOfTheDayUri)
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw PublicationApiException(response.statusCode);
      }

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid publication response.');
      }
      final publication = DailyPublication.fromJson(data);
      await _cacheTodayPublication(publication);
      return TodayPublicationLoad(publication: publication, isOffline: false);
    } catch (error) {
      final cached = await _readCachedTodayPublication();
      return TodayPublicationLoad(
        publication: cached ?? DailyPublication.localFallback,
        isOffline: true,
        failure: _failureFor(error),
      );
    }
  }

  Future<List<DailyPublication>> fetchPublications() async {
    late final http.Response response;
    try {
      response = await _client.get(publicationsUri).timeout(requestTimeout);
    } on TimeoutException catch (error) {
      throw PublicationTimeoutException(error.duration ?? requestTimeout);
    } on http.ClientException catch (error) {
      throw PublicationConnectivityException(error.message);
    } catch (error) {
      throw PublicationConnectivityException(error.toString());
    }
    if (response.statusCode != 200) {
      throw PublicationApiException(response.statusCode);
    }

    final data = json.decode(response.body);
    if (data is! List) {
      throw const FormatException('Invalid publications response.');
    }

    final fetched = List<DailyPublication>.unmodifiable(
      data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid publication response.');
        }
        return DailyPublication.fromJson(item);
      }),
    );
    final cached = await readCachedPublications();
    final merged = _visiblePublications(
      _mergePublications(cached ?? const [], fetched),
    );
    await _cachePublications(merged);
    return merged;
  }

  Future<List<DailyPublication>?> readCachedPublications() async {
    try {
      final stored = await _archiveStorage.read(archivePublicationsStorageKey);
      if (stored == null || stored.isEmpty) return null;
      final decoded = json.decode(stored);
      if (decoded is! List) return null;
      final publications = decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid cached publication.');
        }
        return DailyPublication.fromJson(item);
      });
      return _visiblePublications(_mergePublications(const [], publications));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isArchiveCacheFresh() async {
    try {
      final stored = await _archiveStorage.read(archiveRefreshStorageKey);
      final refreshedAt = stored == null ? null : DateTime.tryParse(stored);
      if (refreshedAt == null) return false;
      final now = _now();
      final sameDate =
          refreshedAt.year == now.year &&
          refreshedAt.month == now.month &&
          refreshedAt.day == now.day;
      final age = now.difference(refreshedAt);
      return sameDate && !age.isNegative && age <= archiveFreshness;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cacheTodayPublication(DailyPublication publication) async {
    try {
      await _todayStorage.write(
        todayPublicationStorageKey,
        json.encode(publication.toJson()),
      );
    } catch (_) {
      // A persistence failure must not discard a valid network publication.
    }
  }

  Future<DailyPublication?> _readCachedTodayPublication() async {
    try {
      final stored = await _todayStorage.read(todayPublicationStorageKey);
      if (stored == null || stored.isEmpty) return null;
      final decoded = json.decode(stored);
      if (decoded is! Map<String, dynamic>) return null;
      return DailyPublication.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cachePublications(List<DailyPublication> publications) async {
    try {
      await _archiveStorage.write(
        archivePublicationsStorageKey,
        json.encode(
          publications.map((publication) => publication.toJson()).toList(),
        ),
      );
      await _archiveStorage.write(
        archiveRefreshStorageKey,
        _now().toIso8601String(),
      );
    } catch (_) {
      // A persistence failure must not discard a valid network response.
    }
  }

  List<DailyPublication> _mergePublications(
    Iterable<DailyPublication> cached,
    Iterable<DailyPublication> fetched,
  ) {
    final byId = <String, DailyPublication>{};
    for (final publication in cached) {
      byId[publication.id!] = publication;
    }
    for (final publication in fetched) {
      byId[publication.id!] = publication;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final sequenceOrder = a.sequence!.compareTo(b.sequence!);
        return sequenceOrder != 0 ? sequenceOrder : a.id!.compareTo(b.id!);
      });
    return List<DailyPublication>.unmodifiable(merged);
  }

  List<DailyPublication> _visiblePublications(
    Iterable<DailyPublication> publications,
  ) {
    final now = _now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return List<DailyPublication>.unmodifiable(
      publications.where(
        (publication) => !publication.publicationDate!.isAfter(today),
      ),
    );
  }

  PublicationLoadFailure _failureFor(Object error) {
    if (error is TimeoutException) return PublicationLoadFailure.timeout;
    if (error is FormatException || error is PublicationApiException) {
      return PublicationLoadFailure.invalidResponse;
    }
    return PublicationLoadFailure.connectivity;
  }
}

class PublicationApiException implements Exception {
  const PublicationApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Publication API returned $statusCode.';
}

class PublicationTimeoutException implements Exception {
  const PublicationTimeoutException(this.duration);

  final Duration duration;

  @override
  String toString() => 'Publication request timed out after $duration.';
}

class PublicationConnectivityException implements Exception {
  const PublicationConnectivityException(this.message);

  final String message;

  @override
  String toString() => 'Publication network request failed: $message';
}
