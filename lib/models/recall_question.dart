import 'dart:math';

import 'daily_publication.dart';

enum RecallQuestionType { wordToDefinition, definitionToWord, wordToSynonym }

typedef RecallAgainCallback =
    Future<List<RecallQuestion>> Function(Set<String> previousSubjectIds);

class RecallQuestion {
  const RecallQuestion({
    required this.subject,
    required this.type,
    required this.content,
    required this.prompt,
    required this.answers,
    required this.correctAnswer,
  });

  final DailyPublication subject;
  final RecallQuestionType type;
  final String content;
  final String prompt;
  final List<String> answers;
  final String correctAnswer;
}

class RecallSessionGenerator {
  RecallSessionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<RecallQuestion> generate({
    required Iterable<DailyPublication> subjects,
    required Iterable<DailyPublication> distractorPool,
    int questionCount = 5,
    Set<RecallQuestionType>? enabledTypes,
    Set<String> avoidSubjectIds = const {},
  }) {
    final activeTypes = enabledTypes ?? RecallQuestionType.values.toSet();
    final distractors = _uniquePublications(distractorPool);
    final uniqueSubjects = _uniquePublications(subjects)
        .where(
          (subject) => _hasCompatibleType(subject, activeTypes, distractors),
        )
        .toList();
    final preferredSubjects =
        uniqueSubjects
            .where((publication) => !avoidSubjectIds.contains(publication.id))
            .toList()
          ..shuffle(_random);
    final previousSubjects =
        uniqueSubjects
            .where((publication) => avoidSubjectIds.contains(publication.id))
            .toList()
          ..shuffle(_random);
    final subjectList = [...preferredSubjects, ...previousSubjects];
    final count = min(questionCount, subjectList.length);
    final questions = <RecallQuestion>[];

    for (var index = 0; index < count; index++) {
      final subject = subjectList[index];
      final preferred = RecallQuestionType.values[index % 3];
      final type = _supportedType(subject, preferred, activeTypes, distractors);
      if (type == null) continue;
      questions.add(_buildQuestion(subject, type, distractors));
    }

    return List.unmodifiable(questions);
  }

  RecallQuestion? generateQuestion({
    required DailyPublication subject,
    required Iterable<DailyPublication> distractorPool,
    Set<RecallQuestionType>? enabledTypes,
  }) {
    final activeTypes = enabledTypes ?? RecallQuestionType.values.toSet();
    final supportedTypes =
        RecallQuestionType.values
            .where(
              (type) =>
                  activeTypes.contains(type) &&
                  _supportsType(
                    subject,
                    type,
                    _uniquePublications(distractorPool),
                  ),
            )
            .toList()
          ..shuffle(_random);
    if (supportedTypes.isEmpty) return null;
    return _buildQuestion(
      subject,
      supportedTypes.first,
      _uniquePublications(distractorPool),
    );
  }

  bool _hasCompatibleType(
    DailyPublication subject,
    Set<RecallQuestionType> enabledTypes,
    List<DailyPublication> pool,
  ) {
    if (enabledTypes.contains(RecallQuestionType.wordToDefinition) ||
        enabledTypes.contains(RecallQuestionType.definitionToWord)) {
      return true;
    }
    return enabledTypes.contains(RecallQuestionType.wordToSynonym) &&
        _canBuildSynonymQuestion(subject, pool);
  }

  RecallQuestionType? _supportedType(
    DailyPublication subject,
    RecallQuestionType preferred,
    Set<RecallQuestionType> enabledTypes,
    List<DailyPublication> pool,
  ) {
    final ordered = [
      preferred,
      RecallQuestionType.wordToDefinition,
      RecallQuestionType.definitionToWord,
      RecallQuestionType.wordToSynonym,
    ];
    for (final type in ordered) {
      if (!enabledTypes.contains(type)) continue;
      if (_supportsType(subject, type, pool)) {
        return type;
      }
    }
    return null;
  }

  bool _supportsType(
    DailyPublication subject,
    RecallQuestionType type,
    List<DailyPublication> pool,
  ) =>
      type != RecallQuestionType.wordToSynonym ||
      _canBuildSynonymQuestion(subject, pool);

  bool _canBuildSynonymQuestion(
    DailyPublication subject,
    List<DailyPublication> pool,
  ) {
    final subjectSynonyms = _validSynonyms(subject);
    if (subjectSynonyms.length < 2) return false;

    final subjectValues = subjectSynonyms
        .map((value) => value.toLowerCase())
        .toSet();
    final alternatives = <String>{};
    for (final publication in pool) {
      for (final synonym in _validSynonyms(publication)) {
        final normalized = synonym.toLowerCase();
        if (!subjectValues.contains(normalized)) alternatives.add(normalized);
      }
    }
    return alternatives.length >= 3;
  }

  RecallQuestion _buildQuestion(
    DailyPublication subject,
    RecallQuestionType type,
    List<DailyPublication> pool,
  ) {
    late final String content;
    late final String prompt;
    late final String correct;
    late final Iterable<String> candidates;

    switch (type) {
      case RecallQuestionType.wordToDefinition:
        content = subject.word;
        prompt = 'Which definition best describes this word?';
        correct = subject.definition;
        candidates = pool.map((publication) => publication.definition);
      case RecallQuestionType.definitionToWord:
        content = subject.definition;
        prompt = 'Which word does this describe?';
        correct = subject.word;
        candidates = pool.map((publication) => publication.word);
      case RecallQuestionType.wordToSynonym:
        content = subject.word;
        prompt = 'Which word is closest in meaning?';
        final subjectSynonyms = _validSynonyms(subject);
        correct = subjectSynonyms.first;
        final subjectValues = subjectSynonyms
            .map((value) => value.toLowerCase())
            .toSet();
        candidates = pool
            .expand(_validSynonyms)
            .where((value) => !subjectValues.contains(value.toLowerCase()));
    }

    final answers = <String>[correct];
    final seen = <String>{correct.trim().toLowerCase()};
    final shuffledCandidates = candidates.toList()..shuffle(_random);
    for (final candidate in shuffledCandidates) {
      final normalized = candidate.trim().toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      answers.add(candidate.trim());
      if (answers.length == 4) break;
    }
    answers.shuffle(_random);

    return RecallQuestion(
      subject: subject,
      type: type,
      content: content,
      prompt: prompt,
      answers: List.unmodifiable(answers),
      correctAnswer: correct,
    );
  }

  List<String> _validSynonyms(DailyPublication publication) {
    final seen = <String>{};
    return publication.synonyms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
        .toList(growable: false);
  }
}

class EndlessRecallQuestionCycle {
  EndlessRecallQuestionCycle({
    required Iterable<DailyPublication> publications,
    required this.generator,
    Random? random,
  }) : _publications = _uniquePublications(publications),
       _random = random ?? Random();

  final List<DailyPublication> _publications;
  final RecallSessionGenerator generator;
  final Random _random;
  final List<DailyPublication> _remaining = [];
  String? _lastSubjectId;

  int get eligibleSubjectCount => _publications.length;

  RecallQuestion? next() {
    if (_publications.isEmpty) return null;
    if (_remaining.isEmpty) {
      _remaining.addAll(_publications..shuffle(_random));
      if (_remaining.length > 1 && _remaining.first.id == _lastSubjectId) {
        final first = _remaining.removeAt(0);
        _remaining.add(first);
      }
    }
    final subject = _remaining.removeAt(0);
    _lastSubjectId = subject.id;
    return generator.generateQuestion(
      subject: subject,
      distractorPool: _publications,
      enabledTypes: RecallQuestionType.values.toSet(),
    );
  }
}

List<DailyPublication> _uniquePublications(
  Iterable<DailyPublication> publications,
) {
  final byId = <String, DailyPublication>{};
  for (final publication in publications) {
    final id = publication.id;
    if (id != null) byId[id] = publication;
  }
  return byId.values.toList();
}
