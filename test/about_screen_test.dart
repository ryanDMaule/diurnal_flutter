import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/screens/about_screen.dart';
import 'package:diurnul/screens/menu_screen.dart';

void main() {
  testWidgets('About opens from Menu and presents the approved colophon', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

    await tester.tap(find.text('About Diurnus'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('About Diurnus'), findsOneWidget);
    expect(find.text('One remarkable word, every day.'), findsOneWidget);
    expect(find.byKey(const Key('about-main-copy')), findsOneWidget);
    expect(find.text('Diurnus'), findsOneWidget);
    expect(find.text('Version unavailable'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Acknowledgements'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('About remains scrollable on a constrained screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: AboutScreen()));

    expect(find.byKey(const Key('about-scroll-view')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('buy-me-a-coffee')),
      250,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Support Diurnus'), findsOneWidget);
    expect(find.text('Buy me a coffee'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Buy me a coffee, opens external browser'),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(const Key('buy-me-a-coffee'))).height, 52);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Made for the curious.'),
      250,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Made for the curious.'), findsOneWidget);

    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('support action opens the exact donation URL externally', (
    tester,
  ) async {
    Uri? openedUrl;
    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          externalUrlLauncher: (url) async {
            openedUrl = url;
            return true;
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('buy-me-a-coffee')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-me-a-coffee')));
    await tester.pump();

    expect(openedUrl, AboutScreen.supportUrl);
    expect(openedUrl.toString(), 'https://buymeacoffee.com/ryanMaule');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('support action reports an external-launch failure gracefully', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AboutScreen(externalUrlLauncher: (_) async => false)),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('buy-me-a-coffee')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-me-a-coffee')));
    await tester.pump();

    expect(
      find.text('Unable to open the support page right now.'),
      findsOneWidget,
    );
  });
}
