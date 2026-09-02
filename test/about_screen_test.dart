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
    expect(find.text('Made for the curious.'), findsOneWidget);

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
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    expect(find.byKey(const Key('about-scroll-view')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Made for the curious.'),
      250,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Made for the curious.'), findsOneWidget);

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
