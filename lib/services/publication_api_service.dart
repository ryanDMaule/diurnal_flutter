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
  SharedPreferencesTodayPublicationStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

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
  });

  final DailyPublication publication;
  final bool isOffline;
}

class PublicationApiService {
  PublicationApiService({
    http.Client? client,
    TodayPublicationStorage? todayStorage,
  }) : _client = client ?? http.Client(),
       _todayStorage =
           todayStorage ?? SharedPreferencesTodayPublicationStorage();

  static final Uri wordOfTheDayUri = Uri.parse(
    'https://diurnal-api-7zz8.onrender.com/word',
  );
  static final Uri publicationsUri = wordOfTheDayUri.resolve('/publications');
  static const todayPublicationStorageKey =
      'diurnus.todayPublication.lastSuccessful';

  final http.Client _client;
  final TodayPublicationStorage _todayStorage;

  Future<TodayPublicationLoad> loadTodayPublication() async {
    try {
      final response = await _client.get(wordOfTheDayUri);
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
    } catch (_) {
      final cached = await _readCachedTodayPublication();
      return TodayPublicationLoad(
        publication: cached ?? DailyPublication.localFallback,
        isOffline: true,
      );
    }
  }

  Future<List<DailyPublication>> fetchPublications() async {
    final response = await _client.get(publicationsUri);
    if (response.statusCode != 200) {
      throw PublicationApiException(response.statusCode);
    }

    final data = json.decode(response.body);
    if (data is! List) {
      throw const FormatException('Invalid publications response.');
    }

    return List<DailyPublication>.unmodifiable(
      data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid publication response.');
        }
        return DailyPublication.fromJson(item);
      }),
    );
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
}

class PublicationApiException implements Exception {
  const PublicationApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Publication API returned $statusCode.';
}
