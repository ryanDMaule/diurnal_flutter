import 'recall_question.dart';

enum RecallWordPool { archive, myLexicon, unrecalled, revisit }

class RecallSettings {
  const RecallSettings({
    required this.wordPool,
    required this.questionCount,
    required this.enabledQuestionTypes,
  });

  static const defaults = RecallSettings(
    wordPool: RecallWordPool.archive,
    questionCount: 5,
    enabledQuestionTypes: {
      RecallQuestionType.wordToDefinition,
      RecallQuestionType.definitionToWord,
      RecallQuestionType.wordToSynonym,
    },
  );

  final RecallWordPool wordPool;
  final int questionCount;
  final Set<RecallQuestionType> enabledQuestionTypes;

  RecallSettings copyWith({
    RecallWordPool? wordPool,
    int? questionCount,
    Set<RecallQuestionType>? enabledQuestionTypes,
  }) {
    return RecallSettings(
      wordPool: wordPool ?? this.wordPool,
      questionCount: questionCount ?? this.questionCount,
      enabledQuestionTypes: Set.unmodifiable(
        enabledQuestionTypes ?? this.enabledQuestionTypes,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'wordPool': wordPool.name,
    'questionCount': questionCount,
    'enabledQuestionTypes': enabledQuestionTypes
        .map((type) => type.name)
        .toList(),
  };

  factory RecallSettings.fromJson(Map<String, dynamic> json) {
    final poolName = json['wordPool'];
    final count = json['questionCount'];
    final typeNames = json['enabledQuestionTypes'];
    final pool = RecallWordPool.values.where((value) => value.name == poolName);
    final types = typeNames is List
        ? RecallQuestionType.values
              .where((type) => typeNames.contains(type.name))
              .toSet()
        : <RecallQuestionType>{};

    return RecallSettings(
      wordPool: pool.isEmpty ? RecallWordPool.archive : pool.first,
      questionCount: const {5, 10, 20}.contains(count) ? count as int : 5,
      enabledQuestionTypes: types.isEmpty
          ? RecallSettings.defaults.enabledQuestionTypes
          : Set.unmodifiable(types),
    );
  }
}
