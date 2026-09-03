import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/recall_question.dart';
import 'package:diurnul/models/recall_settings.dart';
import 'package:diurnul/models/recall_settings_policy.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/screens/recall_settings_screen.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/services/recall_settings_service.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';

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

  test(
    'Free policy constrains effective settings without changing storage',
    () async {
      const stored = RecallSettings(
        wordPool: RecallWordPool.revisit,
        questionCount: 20,
        enabledQuestionTypes: {RecallQuestionType.wordToSynonym},
      );

      final effective = RecallSettingsPolicy.effectiveFor(stored, isPro: false);
      expect(effective.wordPool, RecallWordPool.archive);
      expect(effective.questionCount, 5);
      expect(effective.enabledQuestionTypes, {
        RecallQuestionType.wordToDefinition,
      });
      expect(stored.wordPool, RecallWordPool.revisit);
      expect(stored.questionCount, 20);
      expect(stored.enabledQuestionTypes, {RecallQuestionType.wordToSynonym});
      expect(
        RecallSettingsPolicy.effectiveFor(stored, isPro: true),
        same(stored),
      );
    },
  );

  testWidgets('Free settings show locks and locked taps do not save', (
    tester,
  ) async {
    final storage = _MemorySettingsStorage();
    final service = RecallSettingsService(storage: storage);
    const stored = RecallSettings(
      wordPool: RecallWordPool.revisit,
      questionCount: 20,
      enabledQuestionTypes: {RecallQuestionType.wordToSynonym},
    );
    await service.save(stored);
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(700, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EntitlementScope(
        notifier: controller,
        child: MaterialApp(
          home: RecallSettingsScreen(settingsService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pro-setting-lock')), findsNWidgets(7));
    await tester.tap(find.byKey(const Key('pool-archive')));
    await tester.ensureVisible(find.byKey(const Key('type-wordToDefinition')));
    await tester.tap(find.byKey(const Key('type-wordToDefinition')));
    await tester.pumpAndSettle();
    final allowedSettings = await service.load();
    expect(allowedSettings.wordPool, RecallWordPool.archive);
    expect(
      allowedSettings.enabledQuestionTypes,
      contains(RecallQuestionType.wordToDefinition),
    );

    await service.save(stored);
    await tester.tap(find.byKey(const Key('pool-myLexicon')));
    await tester.pumpAndSettle();
    expect(find.byType(ProScreen), findsOneWidget);
    expect(find.byTooltip('Back to Recall Settings'), findsOneWidget);
    expect((await service.load()).toJson(), stored.toJson());

    await tester.tap(find.byTooltip('Back to Recall Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('question-count-5')));
    await tester.tap(find.byKey(const Key('question-count-5')));
    await tester.pumpAndSettle();
    expect((await service.load()).questionCount, 5);
  });

  testWidgets(
    'settings selections persist and final question type stays enabled',
    (tester) async {
      final service = RecallSettingsService(storage: _MemorySettingsStorage());
      await tester.binding.setSurfaceSize(const Size(700, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        EntitlementScope(
          notifier: await _proController(),
          child: MaterialApp(
            home: RecallSettingsScreen(settingsService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recall Settings'), findsOneWidget);
      expect(find.text('Word pool'), findsOneWidget);
      expect(find.text('Questions per session'), findsOneWidget);
      expect(find.text('Question types'), findsOneWidget);
      expect(find.byKey(const Key('pro-setting-lock')), findsNothing);

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

Future<EntitlementController> _proController() async {
  final controller = EntitlementController(
    EntitlementService(storage: _MemoryEntitlementStorage()),
  );
  await controller.update(SubscriptionTier.pro);
  return controller;
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
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
