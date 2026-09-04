import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/screens/menu_screen.dart';
import 'package:diurnul/screens/settings_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/endless_recall_service.dart';
import 'package:diurnul/services/recall_progress_service.dart';
import 'package:diurnul/theme/interface_theme.dart';
import 'package:diurnul/widgets/edition_background.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  testWidgets('Menu and About react to Paper and Navy interface colours', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _AppStorage();
    final controller = InterfaceColorController(
      AppSettingsService(storage: storage),
    );
    await controller.update(
      AppSettings.defaults.copyWith(
        interfaceColor: InterfaceColor.paper,
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
      InterfacePalette.paper.background,
    );

    await tester.tap(find.text('About Diurnus'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.paper.background,
    );

    await controller.update(
      controller.settings.copyWith(
        interfaceColor: InterfaceColor.navy,
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.navy.background,
    );
  });

  testWidgets('Settings selection updates the shared controller immediately', (
    tester,
  ) async {
    final storage = _AppStorage();
    final service = AppSettingsService(storage: storage);
    final controller = InterfaceColorController(service);
    await controller.update(
      AppSettings.defaults.copyWith(
        interfaceColor: InterfaceColor.paper,
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
    await tester.tap(find.byKey(const Key('interface-color-navy')));
    await tester.pumpAndSettle();
    expect(controller.settings.interfaceColor, InterfaceColor.navy);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InterfacePalette.navy.background,
    );
  });

  testWidgets(
    'publication detail remains Edition-driven across interface colours',
    (tester) async {
      final controller = InterfaceColorController(
        AppSettingsService(storage: _AppStorage()),
      );
      await controller.update(
        AppSettings.defaults.copyWith(
          interfaceColor: InterfaceColor.paper,
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
      Widget view() => InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: PublicationView(
            publication: publication,
            edition: Editions.evergreen,
            isBookmarked: false,
            onBookmarkToggle: null,
          ),
        ),
      );
      await tester.pumpWidget(view());
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.black,
      );
      expect(
        tester
            .widget<EditionBackground>(find.byType(EditionBackground))
            .edition,
        same(Editions.evergreen),
      );

      await controller.update(
        AppSettings.defaults.copyWith(
          interfaceColor: InterfaceColor.navy,
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<EditionBackground>(find.byType(EditionBackground))
            .edition,
        same(Editions.evergreen),
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
