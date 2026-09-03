import 'recall_question.dart';
import 'recall_settings.dart';

abstract final class RecallSettingsPolicy {
  static const freeSettings = RecallSettings(
    wordPool: RecallWordPool.archive,
    questionCount: 5,
    enabledQuestionTypes: {RecallQuestionType.wordToDefinition},
  );

  static RecallSettings effectiveFor(
    RecallSettings stored, {
    required bool isPro,
  }) => isPro ? stored : freeSettings;
}
