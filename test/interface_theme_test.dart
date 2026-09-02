import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/settings_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/endless_recall_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';
import 'package:diurnul/theme/interface_theme.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  testWidgets('Menu and About react to Light and Dark appearance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _AppStorage();
    final controller = InterfaceAppearanceController(
      AppSettingsService(storage: storage),
    );
    await controller.update(
      AppSettings.defaults.copyWith(
        interfaceAppearance: InterfaceAppearance.light,
      ),
    );
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(home: MenuScreen()),
      ),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.light.background,
    );

    await tester.tap(find.text('About Diurnus'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.light.background,
    );

    await controller.update(
      controller.settings.copyWith(
        interfaceAppearance: InterfaceAppearance.dark,
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.dark.background,
    );
  });

  testWidgets('Settings selection updates the shared controller immediately', (
    tester,
  ) async {
    final storage = _AppStorage();
    final service = AppSettingsService(storage: storage);
    final controller = InterfaceAppearanceController(service);
    await controller.update(
      AppSettings.defaults.copyWith(
        interfaceAppearance: InterfaceAppearance.light,
      ),
    );
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: SettingsScreen(
            settingsService: service,
            bookmarkService: BookmarkService(storage: _BookmarkStorage()),
            recallProgressService: RecallProgressService(
              storage: _ProgressStorage(),
            ),
            endlessRecallService: EndlessRecallService(
              storage: _EndlessStorage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearance-dark')));
    await tester.pumpAndSettle();
    expect(controller.settings.interfaceAppearance, InterfaceAppearance.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.dark.background,
    );
  });

  testWidgets(
    'historical detail uses interface palette while Edition path remains unchanged',
    (tester) async {
      final controller = InterfaceAppearanceController(
        AppSettingsService(storage: _AppStorage()),
      );
      await controller.update(
        AppSettings.defaults.copyWith(
          interfaceAppearance: InterfaceAppearance.light,
        ),
      );
      final publication = DailyPublication(
        id: 'one',
        sequence: 1,
        publicationDate: DateTime.utc(2026, 9, 1),
        word: 'Diurnal',
        type: 'Adjective',
        phonetic: 'diurnal',
        definition: 'Of the day.',
        usage: 'A diurnal rhythm.',
        synonyms: const ['Daily'],
      );
      Widget view(bool interfaceStyled) => InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: PublicationView(
            publication: publication,
            interfaceStyled: interfaceStyled,
            isBookmarked: false,
            onBookmarkToggle: null,
          ),
        ),
      );
      await tester.pumpWidget(view(true));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        InterfacePalette.light.background,
      );
      await tester.pumpWidget(view(false));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.black,
      );
    },
  );
}

class _AppStorage implements AppSettingsStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _BookmarkStorage implements BookmarkStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
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
