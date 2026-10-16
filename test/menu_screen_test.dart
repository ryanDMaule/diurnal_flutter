import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/screens/about_screen.dart';
import 'package:diurnul/screens/menu_screen.dart';

void main() {
  testWidgets('free menu has balanced sections without reserved Pro spacing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));

    expect(find.byKey(const Key('menu-pro-spacing')), findsNothing);
    expect(find.text('Diurnus Pro'), findsNothing);
    expect(find.byType(Divider), findsNWidgets(3));
    expect(find.byKey(const Key('menu-appearance')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-about')),
      250,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(const Key('menu-about')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('menu-about')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
