import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/config/pro_restrictions.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/models/edition_access_policy.dart';
import 'package:diurnul/models/recall_question.dart';
import 'package:diurnul/models/recall_settings.dart';
import 'package:diurnul/models/recall_settings_policy.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/pro_screen.dart';
import 'package:diurnul/services/archive_access.dart';
import 'package:diurnul/services/edition_entitlement_coordinator.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';

void main() {
  tearDown(() => ProRestrictions.setTestOverride(null));

  test('free release flag unlocks all policy-controlled features', () {
    expect(kProRestrictionsEnabled, isFalse);
    expect(ProRestrictions.enabled, isFalse);

    for (final edition in Editions.all) {
      expect(EditionAccessPolicy.canSelect(edition, isPro: false), isTrue);
      expect(
        EditionAccessPolicy.effectiveFor(edition, isPro: false),
        same(edition),
      );
    }

    final publications = List.generate(8, _publication);
    expect(
      ArchiveAccess.accessiblePublicationIds(publications, isPro: false),
      hasLength(8),
    );

    const settings = RecallSettings(
      wordPool: RecallWordPool.myLexicon,
      questionCount: 20,
      enabledQuestionTypes: {
        RecallQuestionType.wordToDefinition,
        RecallQuestionType.definitionToWord,
        RecallQuestionType.wordToSynonym,
      },
    );
    expect(
      RecallSettingsPolicy.effectiveFor(settings, isPro: false),
      same(settings),
    );
  });

  testWidgets('free release menu does not expose Pro or subscription UI', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

    expect(find.text('Diurnus Pro'), findsNothing);
    expect(find.text('Unlock the full experience'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    expect(find.textContaining('£'), findsNothing);
    expect(find.byKey(const Key('pro-entitlement-toggle')), findsNothing);
  });

  test('free release syncs a premium Edition for a Free entitlement', () async {
    final editionStorage = _MemoryEditionStorage()..value = Editions.gilded.id;
    final cache = _MemoryWidgetCache();
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    final coordinator = EditionEntitlementCoordinator(
      entitlementController: controller,
      editionService: EditionService(storage: editionStorage),
      widgetSyncService: WidgetSyncService(cache: cache),
    );

    await controller.load();
    await coordinator.syncNow();

    expect(controller.isPro, isFalse);
    expect(cache.values[WidgetSyncService.editionKey], Editions.gilded.id);
    expect(editionStorage.value, Editions.gilded.id);
  });

  test('restricted override preserves the existing Free policies', () {
    ProRestrictions.setTestOverride(true);
    expect(ProRestrictions.enabled, isTrue);
    expect(
      EditionAccessPolicy.canSelect(Editions.gilded, isPro: false),
      isFalse,
    );
    expect(
      EditionAccessPolicy.effectiveFor(Editions.gilded, isPro: false),
      same(Editions.library),
    );
    expect(
      ArchiveAccess.accessiblePublicationIds(
        List.generate(8, _publication),
        isPro: false,
      ),
      hasLength(ArchiveAccess.freePublicationLimit),
    );
    expect(
      RecallSettingsPolicy.effectiveFor(
        const RecallSettings(
          wordPool: RecallWordPool.revisit,
          questionCount: 20,
          enabledQuestionTypes: {RecallQuestionType.wordToSynonym},
        ),
        isPro: false,
      ),
      RecallSettingsPolicy.freeSettings,
    );
  });

  testWidgets('restricted mode preserves the original Pro destination', (
    tester,
  ) async {
    ProRestrictions.setTestOverride(true);
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: MenuScreen(entitlementController: controller)),
    );

    expect(find.text('Diurnus Pro'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    await tester.ensureVisible(find.text('Diurnus Pro'));
    await tester.tap(find.text('Diurnus Pro'));
    await tester.pumpAndSettle();

    expect(find.byType(ProScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pro-entitlement-toggle')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('£2.99 / month'), findsOneWidget);
    expect(find.text('£15 / year'), findsOneWidget);
    expect(find.byKey(const Key('pro-entitlement-toggle')), findsOneWidget);
  });
}

DailyPublication _publication(int index) => DailyPublication(
  id: 'publication-$index',
  sequence: index + 1,
  publicationDate: DateTime.utc(2026, 9, index + 1),
  word: 'Word $index',
  type: 'Noun',
  phonetic: 'word',
  definition: 'Definition',
  usage: 'Usage',
  synonyms: const ['Term'],
);

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  @override
  Future<String?> readTier() async => null;

  @override
  Future<void> writeTier(String tier) async {}
}

class _MemoryWidgetCache implements WidgetCache {
  final values = <String, Object>{};

  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> saveString(String key, String value) async =>
      values[key] = value;
}
