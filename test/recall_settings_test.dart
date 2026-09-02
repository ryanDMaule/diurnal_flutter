import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/recall_question.dart';
import 'package:diurnul/models/recall_settings.dart';
import 'package:diurnul/screens/recall_settings_screen.dart';
import 'package:diurnul/services/recall_settings_service.dart';

void main() {
  test(
    'defaults preserve the original Archive five-question behaviour',
    () async {
      final service = RecallSettingsService(storage: _MemorySettingsStorage());
      final settings = await service.load();

      expect(settings.wordPool, RecallWordPool.archive);
      expect(settings.questionCount, 5);
      expect(settings.enabledQuestionTypes, RecallQuestionType.values.toSet());
    },
  );

  test('pool, count, and enabled types survive service recreation', () async {
    final storage = _MemorySettingsStorage();
    final service = RecallSettingsService(storage: storage);
    const settings = RecallSettings(
      wordPool: RecallWordPool.revisit,
      questionCount: 20,
      enabledQuestionTypes: {RecallQuestionType.definitionToWord},
    );
    await service.save(settings);

    final restored = await RecallSettingsService(storage: storage).load();
    expect(restored.wordPool, RecallWordPool.revisit);
    expect(restored.questionCount, 20);
    expect(restored.enabledQuestionTypes, {
      RecallQuestionType.definitionToWord,
    });
  });

  testWidgets(
    'settings selections persist and final question type stays enabled',
    (tester) async {
      final service = RecallSettingsService(storage: _MemorySettingsStorage());
      await tester.binding.setSurfaceSize(const Size(700, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: RecallSettingsScreen(settingsService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recall Settings'), findsOneWidget);
      expect(find.text('Word pool'), findsOneWidget);
      expect(find.text('Questions per session'), findsOneWidget);
      expect(find.text('Question types'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pool-myLexicon')));
      await tester.tap(find.byKey(const Key('question-count-10')));
      await tester.tap(find.byKey(const Key('type-wordToDefinition')));
      await tester.tap(find.byKey(const Key('type-definitionToWord')));
      await tester.pumpAndSettle();

      var settings = await service.load();
      expect(settings.wordPool, RecallWordPool.myLexicon);
      expect(settings.questionCount, 10);
      expect(settings.enabledQuestionTypes, {RecallQuestionType.wordToSynonym});

      await tester.tap(find.byKey(const Key('type-wordToSynonym')));
      await tester.pumpAndSettle();
      settings = await service.load();
      expect(settings.enabledQuestionTypes, {RecallQuestionType.wordToSynonym});
    },
  );
}

class _MemorySettingsStorage implements RecallSettingsStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
