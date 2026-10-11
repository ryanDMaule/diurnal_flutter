import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/recall_settings.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/settings_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/endless_recall_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';
import 'package:diurnul/services/recall_settings_service.dart';
import 'package:diurnul/services/sound_effects_service.dart';

import 'support/fake_sound_effects.dart';

void main() {
  testWidgets('Settings opens from Menu, persists controls, and returns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appStorage = _AppStorage();
    await tester.pumpWidget(
      MaterialApp(
        home: MenuScreen(
          appSettingsService: AppSettingsService(storage: appStorage),
          bookmarkService: BookmarkService(storage: _BookmarkStorage()),
          recallProgressService: RecallProgressService(
            storage: _ProgressStorage(),
          ),
          endlessRecallService: EndlessRecallService(
            storage: _EndlessStorage(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    final soundSwitch = find.descendant(
      of: find.byKey(const Key('sound-effects-setting')),
      matching: find.byType(Switch),
    );
    final reduceAnimationsSwitch = find.descendant(
      of: find.byKey(const Key('reduce-animations-setting')),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(soundSwitch).value, isTrue);
    expect(tester.widget<Switch>(reduceAnimationsSwitch).value, isFalse);

    await tester.tap(soundSwitch);
    await tester.tap(reduceAnimationsSwitch);
    expect(find.text('Theme Colour'), findsNothing);
    expect(find.byKey(const Key('theme-color-selector')), findsNothing);
    final restored = await AppSettingsService(storage: appStorage).load();
    expect(restored.soundEffectsEnabled, isFalse);
    expect(restored.reduceAnimations, isTrue);
    expect(restored.interfaceColor, InterfaceColor.evergreen);

    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
  });

  testWidgets('destructive actions require confirmation and stay isolated', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bookmarkStorage = _BookmarkStorage();
    final progressStorage = _ProgressStorage();
    final endlessStorage = _EndlessStorage()..value = 9;
    final bookmarks = BookmarkService(storage: bookmarkStorage);
    final progress = RecallProgressService(storage: progressStorage);
    final publication = _publication();
    final recallSettingsStorage = _RecallSettingsStorage();
    final recallSettings = RecallSettingsService(
      storage: recallSettingsStorage,
    );
    await recallSettings.save(
      RecallSettings.defaults.copyWith(questionCount: 20),
    );
    await bookmarks.save(publication);
    await progress.recordAnswer(publication.id!, wasCorrect: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: AppSettingsService(storage: _AppStorage()),
          bookmarkService: bookmarks,
          recallProgressService: progress,
          endlessRecallService: EndlessRecallService(storage: endlessStorage),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reset-recall-progress')));
    await tester.pumpAndSettle();
    expect(find.text('Reset Recall progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await progress.isRecalled(publication.id!), isTrue);

    await tester.tap(find.byKey(const Key('reset-recall-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    expect(
      await progress.stateFor(publication.id!),
      RecallProgressState.unseen,
    );
    expect(
      await EndlessRecallService(storage: endlessStorage).personalBest(),
      isNull,
    );
    expect(await bookmarks.isSaved(publication.id), isTrue);
    expect((await recallSettings.load()).questionCount, 20);

    await tester.tap(find.byKey(const Key('clear-my-lexicon')));
    await tester.pumpAndSettle();
    expect(find.text('Clear My Lexicon?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await bookmarks.isSaved(publication.id), isTrue);

    await tester.tap(find.byKey(const Key('clear-my-lexicon')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Lexicon'));
    await tester.pumpAndSettle();
    expect(await bookmarks.getSavedPublications(), isEmpty);
    expect(
      await progress.stateFor(publication.id!),
      RecallProgressState.unseen,
    );
    expect((await recallSettings.load()).questionCount, 20);
  });

  testWidgets('enabling Sound Effects plays exactly one preview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _AppStorage();
    final settingsService = AppSettingsService(storage: storage);
    await settingsService.save(
      AppSettings.defaults.copyWith(soundEffectsEnabled: false),
    );
    final playback = FakeSoundEffectsPlayback();
    final soundEffectsService = SoundEffectsService(
      playback: playback,
      enabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settingsService: settingsService,
          soundEffectsService: soundEffectsService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final soundSwitch = find.descendant(
      of: find.byKey(const Key('sound-effects-setting')),
      matching: find.byType(Switch),
    );

    await tester.tap(soundSwitch);
    await tester.pumpAndSettle();
    expect(playback.calls, hasLength(1));
    expect(playback.calls.single.assetPath, 'sfx/v2/select_01.ogg');
    expect(playback.calls.single.volume, 0.20);

    await tester.tap(soundSwitch);
    await tester.pumpAndSettle();
    expect(playback.calls, hasLength(1));
    expect(soundEffectsService.enabled, isFalse);
  });
}

DailyPublication _publication() => DailyPublication(
  id: 'publication-1',
  sequence: 1,
  publicationDate: DateTime.utc(2026, 9, 1),
  word: 'Diurnal',
  type: 'Adjective',
  phonetic: 'diurnal',
  definition: 'Active during the daytime.',
  usage: 'A diurnal rhythm.',
  synonyms: const ['Daily'],
);

class _AppStorage implements AppSettingsStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _BookmarkStorage implements BookmarkStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _ProgressStorage implements RecallProgressStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _EndlessStorage implements EndlessRecallStorage {
  int? value;
  @override
  Future<int?> readBest() async => value;
  @override
  Future<void> writeBest(int score) async => value = score;
}

class _RecallSettingsStorage implements RecallSettingsStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}
