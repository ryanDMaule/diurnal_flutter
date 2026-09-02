import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/daily_publication.dart';

class PublicationApiService {
  PublicationApiService({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri wordOfTheDayUri = Uri.parse(
    'https://diurnal-api-7zz8.onrender.com/word',
  );
  static final Uri publicationsUri = wordOfTheDayUri.resolve('/publications');

  final http.Client _client;

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
}

class PublicationApiException implements Exception {
  const PublicationApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Publication API returned $statusCode.';
}
