import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_publication.dart';

abstract interface class BookmarkStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesBookmarkStorage implements BookmarkStorage {
  SharedPreferencesBookmarkStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class BookmarkService {
  BookmarkService({BookmarkStorage? storage})
    : _storage = storage ?? SharedPreferencesBookmarkStorage();

  static const _storageKey = 'diurnus.bookmarkedPublications';

  final BookmarkStorage _storage;

  Future<List<DailyPublication>> getSavedPublications() async {
    final bookmarks = await _readBookmarks();
    return List<DailyPublication>.unmodifiable(bookmarks.values);
  }

  Future<bool> isSaved(String? publicationId) async {
    if (publicationId == null) return false;
    final bookmarks = await _readBookmarks();
    return bookmarks.containsKey(publicationId);
  }

  Future<void> save(DailyPublication publication) async {
    final publicationId = publication.id;
    if (publicationId == null) {
      throw ArgumentError('Fallback content cannot be bookmarked.');
    }

    final bookmarks = await _readBookmarks();
    bookmarks[publicationId] = publication;
    await _writeBookmarks(bookmarks);
  }

  Future<void> remove(String publicationId) async {
    final bookmarks = await _readBookmarks();
    if (bookmarks.remove(publicationId) != null) {
      await _writeBookmarks(bookmarks);
    }
  }

  Future<void> clearAll() => _writeBookmarks({});

  Future<Map<String, DailyPublication>> _readBookmarks() async {
    final storedValue = await _storage.read(_storageKey);
    if (storedValue == null || storedValue.isEmpty) return {};

    final decoded = json.decode(storedValue);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid bookmark storage.');
    }

    return decoded.map((id, value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved publication.');
      }
      return MapEntry(id, DailyPublication.fromJson(value));
    });
  }

  Future<void> _writeBookmarks(Map<String, DailyPublication> bookmarks) async {
    final serialized = bookmarks.map(
      (id, publication) => MapEntry(id, publication.toJson()),
    );
    await _storage.write(_storageKey, json.encode(serialized));
  }
}
