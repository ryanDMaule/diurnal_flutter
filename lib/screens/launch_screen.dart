import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/diurnus_brand_lockup.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  static const backgroundColor = Color(0xFF032C23);
  static const primaryColor = Color(0xFFF3EBDD);
  static const goldColor = Color(0xFFC8A363);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: SizedBox(
                    width: 132,
                    height: 72,
                    child: OverflowBox(
                      minWidth: 132,
                      maxWidth: 132,
                      minHeight: 132,
                      maxHeight: 132,
                      child: DiurnusSunriseMark(color: goldColor, size: 132),
                    ),
                  ),
                ),
                SizedBox(height: 38),
                ClipRect(
                  child: SizedBox(
                    width: 220,
                    height: 42,
                    child: OverflowBox(
                      minWidth: 220,
                      maxWidth: 220,
                      minHeight: 75.5,
                      maxHeight: 75.5,
                      child: DiurnusWordmark(
                        color: primaryColor,
                        width: 220,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'ONE REMARKABLE WORD, EVERY DAY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryColor,
                    fontFamily: 'Figtree',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.1,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TODO: Revisit the Android cold-start transition. The native forest splash is
/// intentionally minimal and [LaunchScreen] contains the branded Flutter
/// splash, but physical cold-start behavior still needs investigation to ensure
/// the Flutter splash is reliably presented before Today.
class LaunchGate extends StatelessWidget {
  const LaunchGate({
    required this.initialization,
    required this.child,
    super.key,
  });

  final Future<void> initialization;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
          ? child
          : const LaunchScreen(),
    );
  }
}
