import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/theme/motion_preferences.dart';

void main() {
  testWidgets('system reduced motion disables decorative transitions', (
    tester,
  ) async {
    await _pumpProbe(tester, systemSetting: true);

    expect(_probeDuration(tester), Duration.zero);
    expect(find.byKey(const Key('delegated-transition')), findsNothing);
    expect(find.byKey(const Key('route-content')), findsOneWidget);
  });

  testWidgets('animations remain enabled when system setting is off', (
    tester,
  ) async {
    await _pumpProbe(tester, systemSetting: false);

    expect(_probeDuration(tester), const Duration(milliseconds: 140));
    expect(find.byKey(const Key('delegated-transition')), findsOneWidget);
    expect(find.byKey(const Key('route-content')), findsOneWidget);
  });
}

Duration _probeDuration(WidgetTester tester) => tester
    .widget<AnimatedContainer>(find.byKey(const Key('motion-duration-probe')))
    .duration;

Future<void> _pumpProbe(
  WidgetTester tester, {
  required bool systemSetting,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: systemSetting),
        child: const _MotionProbe(),
      ),
    ),
  );
}

class _MotionProbe extends StatelessWidget {
  const _MotionProbe();

  @override
  Widget build(BuildContext context) {
    final route = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final transition =
        const ReducedMotionPageTransitionsBuilder(
          _MarkerPageTransitionsBuilder(),
        ).buildTransitions(
          route,
          context,
          const AlwaysStoppedAnimation(1),
          const AlwaysStoppedAnimation(0),
          const SizedBox(key: Key('route-content')),
        );
    return Column(
      children: [
        AnimatedContainer(
          key: const Key('motion-duration-probe'),
          duration: motionDurationOf(
            context,
            const Duration(milliseconds: 140),
          ),
        ),
        transition,
      ],
    );
  }
}

class _MarkerPageTransitionsBuilder extends PageTransitionsBuilder {
  const _MarkerPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => KeyedSubtree(key: const Key('delegated-transition'), child: child);
}
