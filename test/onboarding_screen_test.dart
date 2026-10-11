import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/screens/onboarding_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/onboarding_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/theme/interface_theme.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  testWidgets(
    'onboarding retains draft appearance and shows widget carousel layouts',
    (tester) async {
      final settingsStorage = _MemoryAppSettingsStorage();
      final editionStorage = _MemoryEditionStorage();
      final onboardingStorage = _MemoryOnboardingStorage();
      final controller = InterfaceColorController(
        AppSettingsService(storage: settingsStorage),
      );
      var completed = false;
      await tester.binding.setSurfaceSize(const Size(430, 820));
      addTearDown(() {
        controller.dispose();
        tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        InterfaceThemeScope(
          notifier: controller,
          child: MaterialApp(
            home: OnboardingScreen(
              initialStep: 0,
              onboardingService: OnboardingService(storage: onboardingStorage),
              editionService: EditionService(storage: editionStorage),
              widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
              onCompleted: () async => completed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('One remarkable\nword, every day.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-begin')));
      await tester.pumpAndSettle();

      expect(find.text('Make Diurnus yours.'), findsOneWidget);
      expect(find.byKey(const Key('edition-lock-atrium')), findsOneWidget);
      await tester.tap(find.byKey(const Key('interface-color-navy')));
      await tester.tap(find.byKey(const Key('edition-midnight')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Words beyond the app.'), findsOneWidget);
      expect(find.byKey(const Key('widget-preview-small')), findsOneWidget);
      expect(find.text('Small widget'), findsOneWidget);
      expect(find.byType(WidgetEditionPreview).hitTestable(), findsOneWidget);
      final carouselSize = tester.getSize(
        find.byKey(const Key('onboarding-widget-carousel')),
      );
      final smallSize = tester.getSize(
        find.byKey(const Key('widget-preview-small')),
      );
      await tester.drag(
        find.byKey(const Key('onboarding-widget-list')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(_dotWidth(tester, 0), 16);
      expect(
        tester
            .widget<WidgetEditionPreview>(
              find.byKey(const Key('widget-preview-small')),
            )
            .edition,
        Editions.midnight,
      );
      await tester.drag(
        find.byKey(const Key('onboarding-widget-carousel')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('widget-preview-medium')), findsOneWidget);
      expect(find.text('Medium widget'), findsOneWidget);
      expect(find.byType(WidgetEditionPreview).hitTestable(), findsOneWidget);
      expect(_dotWidth(tester, 1), 16);
      final mediumSize = tester.getSize(
        find.byKey(const Key('widget-preview-medium')),
      );
      expect(
        tester.getSize(find.byKey(const Key('onboarding-widget-carousel'))),
        carouselSize,
      );
      expect(
        tester
            .widget<WidgetEditionPreview>(
              find.byKey(const Key('widget-preview-medium')),
            )
            .edition,
        Editions.midnight,
      );
      await tester.drag(
        find.byKey(const Key('onboarding-widget-carousel')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('widget-preview-large')), findsOneWidget);
      expect(find.text('Large widget'), findsOneWidget);
      expect(find.byType(WidgetEditionPreview).hitTestable(), findsOneWidget);
      expect(_dotWidth(tester, 2), 16);
      final largeSize = tester.getSize(
        find.byKey(const Key('widget-preview-large')),
      );
      expect(smallSize.height, mediumSize.height);
      expect(mediumSize.width, smallSize.width * 2);
      expect(largeSize.width, mediumSize.width);
      expect(largeSize.height, mediumSize.height * 2);
      expect(smallSize.aspectRatio, 1);
      expect(mediumSize.aspectRatio, 2);
      expect(largeSize.aspectRatio, 1);
      expect(
        tester.getSize(find.byKey(const Key('onboarding-widget-carousel'))),
        carouselSize,
      );
      await controller.update(
        controller.settings.copyWith(hapticFeedbackEnabled: false),
      );
      await tester.pump();
      expect(find.text('Large widget'), findsOneWidget);
      expect(_dotWidth(tester, 2), 16);
      expect(
        tester
            .widget<WidgetEditionPreview>(
              find.byKey(const Key('widget-preview-large')),
            )
            .edition,
        Editions.midnight,
      );
      expect(find.byKey(const Key('widget-preview-mark')), findsNothing);
      expect(find.byKey(const Key('widget-preview-brand')), findsNothing);
      expect(
        await EditionService(storage: editionStorage).loadSelectedEdition(),
        Editions.midnight,
      );
      expect(
        (await AppSettingsService(
          storage: settingsStorage,
        ).load()).interfaceColor,
        InterfaceColor.navy,
      );

      await tester.tap(find.byKey(const Key('onboarding-back')));
      await tester.pumpAndSettle();
      expect(find.text('Make Diurnus yours.'), findsOneWidget);
      expect(find.text('Navy'), findsOneWidget);
      expect(_isSelected(tester, 'midnight'), isTrue);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('edition-library'))),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PublicationView), findsOneWidget);
      expect(find.text('Laconic'), findsWidgets);
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-explore-diurnus')));
      await tester.pump();
      expect(completed, isTrue);
    },
  );

  testWidgets('locked Edition cannot replace the free draft selection', (
    tester,
  ) async {
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(430, 820));
    addTearDown(() {
      controller.dispose();
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: OnboardingScreen(
            initialStep: 1,
            onboardingService: OnboardingService(
              storage: _MemoryOnboardingStorage(),
            ),
            editionService: EditionService(storage: _MemoryEditionStorage()),
            widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            onCompleted: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('edition-atrium')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('onboarding-appearance-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(
      find.byKey(const Key('onboarding-appearance-list')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edition-atrium')));
    await tester.pump();

    expect(
      find.text('This Edition is available with Diurnus Pro.'),
      findsOneWidget,
    );
    expect(_isSelected(tester, 'library'), isTrue);
    expect(_isSelected(tester, 'atrium'), isFalse);
  });

  testWidgets(
    'fresh install ignores restored Theme Edition and starts at Library',
    (tester) async {
      final settingsStorage = _MemoryAppSettingsStorage();
      await AppSettingsService(storage: settingsStorage).save(
        AppSettings.defaults.copyWith(interfaceColor: InterfaceColor.navy),
      );
      final editionStorage = _MemoryEditionStorage();
      await EditionService(
        storage: editionStorage,
      ).selectEdition(Editions.evergreen);
      final controller = InterfaceColorController(
        AppSettingsService(storage: settingsStorage),
      );
      await controller.load(syncWidget: false);
      await tester.binding.setSurfaceSize(const Size(430, 820));
      addTearDown(() {
        controller.dispose();
        tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        InterfaceThemeScope(
          notifier: controller,
          child: MaterialApp(
            home: OnboardingScreen(
              initialStep: 1,
              useDefaultAppearance: true,
              onboardingService: OnboardingService(
                storage: _MemoryOnboardingStorage(),
              ),
              editionService: EditionService(storage: editionStorage),
              widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
              onCompleted: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evergreen'), findsOneWidget);
      expect(_isSelected(tester, 'library'), isTrue);
      expect(_isSelected(tester, 'evergreen'), isFalse);

      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();
      expect(
        await EditionService(storage: editionStorage).loadSelectedEdition(),
        Editions.library,
      );
      expect(
        (await AppSettingsService(
          storage: settingsStorage,
        ).load()).interfaceColor,
        InterfaceColor.evergreen,
      );
    },
  );

  testWidgets('Theme Edition preview uses every draft interface colour', (
    tester,
  ) async {
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() {
      controller.dispose();
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: OnboardingScreen(
            initialStep: 1,
            onboardingService: OnboardingService(
              storage: _MemoryOnboardingStorage(),
            ),
            editionService: EditionService(storage: _MemoryEditionStorage()),
            widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            onCompleted: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final color in InterfaceColor.values) {
      await tester.tap(find.byKey(Key('interface-color-${color.name}')));
      await tester.pump();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('edition-evergreen'))),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final preview = tester.widget<PublicationView>(
        find.byType(PublicationView),
      );
      expect(
        preview.interfacePaletteOverride?.background,
        InterfacePalette.forColor(color).background,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'widget carousel is responsive and instructions stay accessible',
    (tester) async {
      final controller = InterfaceColorController(
        AppSettingsService(storage: _MemoryAppSettingsStorage()),
      );
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() {
        controller.dispose();
        tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        InterfaceThemeScope(
          notifier: controller,
          child: MaterialApp(
            home: OnboardingScreen(
              initialStep: 2,
              onboardingService: OnboardingService(
                storage: _MemoryOnboardingStorage(),
              ),
              editionService: EditionService(storage: _MemoryEditionStorage()),
              widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
              onCompleted: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byKey(const Key('onboarding-widget-list')),
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();

      for (var page = 0; page < 2; page++) {
        await tester.drag(
          find.byKey(const Key('onboarding-widget-carousel')),
          const Offset(-300, 0),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('How to add a widget'));
      await tester.pumpAndSettle();
      expect(
        find.text('1.  Long-press an empty area of your home screen.'),
        findsOneWidget,
      );
      expect(find.text('2.  Tap Widgets and find Diurnus.'), findsOneWidget);
      expect(
        find.text(
          '3.  Choose your preferred widget and drag it into position.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Theme widget previews use the selected draft colour', (
    tester,
  ) async {
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(430, 820));
    addTearDown(() {
      controller.dispose();
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: OnboardingScreen(
            initialStep: 1,
            onboardingService: OnboardingService(
              storage: _MemoryOnboardingStorage(),
            ),
            editionService: EditionService(storage: _MemoryEditionStorage()),
            widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            onCompleted: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interface-color-oxblood')));
    await tester.tap(find.byKey(const Key('edition-evergreen')));
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    final expected = InterfacePalette.forColor(InterfaceColor.oxblood);
    for (var page = 0; page < 3; page++) {
      final preview = tester.widget<WidgetEditionPreview>(
        find.byType(WidgetEditionPreview).hitTestable(),
      );
      expect(preview.edition.id, Editions.evergreen.id);
      expect(preview.edition.backgroundColor, expected.background);
      expect(preview.edition.accentColor, expected.accent);
      expect(find.text('Laconic'), findsWidgets);
      if (page < 2) {
        await tester.drag(
          find.byKey(const Key('onboarding-widget-carousel')),
          const Offset(-350, 0),
        );
        await tester.pumpAndSettle();
      }
    }
  });
}

double _dotWidth(WidgetTester tester, int index) =>
    tester.getSize(find.byKey(Key('widget-carousel-dot-$index'))).width;

bool _isSelected(WidgetTester tester, String id) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(Key('edition-selection-$id')),
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.border!.top.width == 1.25;
}

class _MemoryAppSettingsStorage implements AppSettingsStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _MemoryEditionStorage implements EditionStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _MemoryOnboardingStorage implements OnboardingStorage {
  final ints = <String, int>{};
  final bools = <String, bool>{};
  final strings = <String, String>{};

  @override
  Future<int?> readInt(String key) async => ints[key];

  @override
  Future<bool?> readBool(String key) async => bools[key];

  @override
  Future<String?> readString(String key) async => strings[key];

  @override
  Future<Set<String>> keys() async => {
    ...ints.keys,
    ...bools.keys,
    ...strings.keys,
  };

  @override
  Future<void> writeInt(String key, int value) async => ints[key] = value;

  @override
  Future<void> writeBool(String key, bool value) async => bools[key] = value;

  @override
  Future<void> writeString(String key, String value) async =>
      strings[key] = value;
}

class _MemoryWidgetCache implements WidgetCache {
  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<void> saveString(String key, String value) async {}
}
