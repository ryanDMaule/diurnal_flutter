import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/today_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';
import 'package:diurnul/theme/interface_theme.dart';

void main() {
  testWidgets(
    'menu discovery is suppressed by reduced motion until menu opens',
    (tester) async {
      var consumed = 0;
      final controller = InterfaceColorController(
        AppSettingsService(storage: _MemoryAppSettingsStorage()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        InterfaceThemeScope(
          notifier: controller,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: TodayScreen(
                initialPublication: Future.value(
                  const TodayPublicationLoad(
                    publication: _publication,
                    isOffline: false,
                  ),
                ),
                widgetSyncService: WidgetSyncService(
                  cache: _MemoryWidgetCache(),
                ),
                showMenuShimmer: true,
                onMenuShimmerConsumed: () async => consumed++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(consumed, 0);
      final highlight = tester.widget<DecoratedBox>(
        find.byKey(const Key('menu-control-highlight')),
      );
      final decoration = highlight.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);

      await tester.tap(find.byKey(const Key('open-menu-control')));
      await tester.pumpAndSettle();
      expect(consumed, 1);
    },
  );

  testWidgets('menu discovery repeats until opening the menu consumes it', (
    tester,
  ) async {
    var consumed = 0;
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: TodayScreen(
            initialPublication: Future.value(
              const TodayPublicationLoad(
                publication: _publication,
                isOffline: false,
              ),
            ),
            widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            showMenuShimmer: true,
            onMenuShimmerConsumed: () async => consumed++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 225));
    expect(_highlightDecoration(tester).boxShadow, isNotNull);
    expect(consumed, 0);

    await tester.pump(const Duration(milliseconds: 9775));
    await tester.pump(const Duration(milliseconds: 225));
    expect(_highlightDecoration(tester).boxShadow, isNotNull);
    expect(consumed, 0);

    await tester.tap(find.byKey(const Key('open-menu-control')));
    await tester.pumpAndSettle();
    expect(consumed, 1);
    await tester.tap(find.byKey(const Key('close-menu-control')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    expect(_highlightDecoration(tester).boxShadow, isNull);
    expect(consumed, 1);
  });

  testWidgets('menu discovery timer is cancelled while app is paused', (
    tester,
  ) async {
    var consumed = 0;
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          home: TodayScreen(
            initialPublication: Future.value(
              const TodayPublicationLoad(
                publication: _publication,
                isOffline: false,
              ),
            ),
            widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            showMenuShimmer: true,
            onMenuShimmerConsumed: () async => consumed++,
          ),
        ),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));

    expect(_highlightDecoration(tester).boxShadow, isNull);
    expect(consumed, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('system reduced motion removes the custom menu transition', (
    tester,
  ) async {
    final controller = InterfaceColorController(
      AppSettingsService(storage: _MemoryAppSettingsStorage()),
    );
    await controller.load();
    addTearDown(controller.dispose);
    final observer = _RouteObserver();
    await tester.pumpWidget(
      InterfaceThemeScope(
        notifier: controller,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: TodayScreen(
              initialPublication: Future.value(
                const TodayPublicationLoad(
                  publication: _publication,
                  isOffline: false,
                ),
              ),
              widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Open menu'), findsNothing);
    await tester.tap(find.byKey(const Key('open-menu-control')));
    await tester.pump();

    final route = observer.lastPushed as PageRouteBuilder<void>;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    expect(find.byTooltip('Close menu'), findsNothing);
    expect(find.byKey(const Key('close-menu-control')), findsOneWidget);
  });
}

BoxDecoration _highlightDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(const Key('menu-control-highlight')),
            )
            .decoration
        as BoxDecoration;

const _publication = DailyPublication(
  id: 'publication-1',
  sequence: 1,
  publicationDate: null,
  word: 'Laconic',
  type: 'Adjective',
  phonetic: 'la·con·ic',
  definition: 'Using very few words.',
  usage: 'A laconic response.',
  synonyms: ['Brief'],
);

class _MemoryAppSettingsStorage implements AppSettingsStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

class _RouteObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
  }
}

class _MemoryWidgetCache implements WidgetCache {
  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<void> saveString(String key, String value) async {}
}
