class DailyPublication {
  const DailyPublication({
    required this.id,
    required this.sequence,
    required this.publicationDate,
    required this.word,
    required this.type,
    required this.phonetic,
    required this.definition,
    required this.usage,
    required this.synonyms,
  });

  factory DailyPublication.fromJson(Map<String, dynamic> json) {
    final rawSequence = json['sequence'];
    if (rawSequence is! int || rawSequence < 1) {
      throw const FormatException('Invalid publication sequence.');
    }

    final rawSynonyms = json['synonyms'];
    if (rawSynonyms is! List || rawSynonyms.any((item) => item is! String)) {
      throw const FormatException('Invalid publication synonyms.');
    }

    return DailyPublication(
      id: _requiredString(json, 'id'),
      sequence: rawSequence,
      publicationDate: _parsePublicationDate(
        _requiredString(json, 'publicationDate'),
      ),
      word: _requiredString(json, 'word'),
      type: _requiredString(json, 'type'),
      phonetic: _requiredString(json, 'phonetic'),
      definition: _requiredString(json, 'definition'),
      usage: _requiredString(json, 'usage'),
      synonyms: List<String>.unmodifiable(rawSynonyms.cast<String>()),
    );
  }

  Map<String, dynamic> toJson() {
    final publicationId = id;
    final publicationSequence = sequence;
    final date = publicationDate;
    if (publicationId == null || publicationSequence == null || date == null) {
      throw StateError('Local fallback content cannot be serialized.');
    }

    return {
      'id': publicationId,
      'sequence': publicationSequence,
      'publicationDate': _formatPublicationDate(date),
      'word': word,
      'type': type,
      'phonetic': phonetic,
      'definition': definition,
      'usage': usage,
      'synonyms': synonyms,
    };
  }

  static const localFallback = DailyPublication(
    id: null,
    sequence: null,
    publicationDate: null,
    word: 'Diurnal',
    type: 'Adjective',
    phonetic: 'di·​ur·​nal',
    definition:
        'Occurring or active during the daytime; relating to or happening once every day.',
    usage:
        'Unlike nocturnal creatures, diurnal animals such as squirrels and hawks are active during the day.',
    synonyms: ['Daily', 'Daytime', 'Circadian'],
  );

  final String? id;
  final int? sequence;
  final DateTime? publicationDate;
  final String word;
  final String type;
  final String phonetic;
  final String definition;
  final String usage;
  final List<String> synonyms;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid publication $key.');
  }
  return value;
}

DateTime _parsePublicationDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw const FormatException('Invalid publication date.');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);

  if (date.year != year || date.month != month || date.day != day) {
    throw const FormatException('Invalid publication date.');
  }

  return date;
}

String _formatPublicationDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
