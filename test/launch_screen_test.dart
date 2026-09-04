import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/screens/launch_screen.dart';

void main() {
  testWidgets('LaunchScreen renders the intended branding and system UI', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LaunchScreen()));

    expect(find.byType(LaunchScreen), findsOneWidget);
    final launchSystemUi = tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .value;
    expect(launchSystemUi.statusBarColor, LaunchScreen.backgroundColor);
    expect(
      launchSystemUi.systemNavigationBarColor,
      LaunchScreen.backgroundColor,
    );
    expect(find.text('Diurnus'), findsOneWidget);
    expect(find.text('ONE REMARKABLE WORD, EVERY DAY.'), findsOneWidget);
    expect(find.textContaining('Loading'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('startup displays LaunchScreen then reaches Today', (
    tester,
  ) async {
    final initialization = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: LaunchGate(
          initialization: initialization.future,
          child: const Scaffold(key: Key('today-destination')),
        ),
      ),
    );

    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(find.byKey(const Key('today-destination')), findsNothing);

    initialization.complete();
    await tester.pump();
    await tester.pump();

    expect(find.byType(LaunchScreen), findsNothing);
    expect(find.byKey(const Key('today-destination')), findsOneWidget);
  });

  testWidgets('startup failure does not trap the app on the launch screen', (
    tester,
  ) async {
    final initialization = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: LaunchGate(
          initialization: initialization.future,
          child: const Text('Today destination'),
        ),
      ),
    );
    initialization.completeError(StateError('startup failed'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LaunchScreen), findsNothing);
    expect(find.text('Today destination'), findsOneWidget);
  });
}
