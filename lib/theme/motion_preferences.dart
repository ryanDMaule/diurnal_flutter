import 'package:flutter/material.dart';

bool reduceAnimationsOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

Duration motionDurationOf(BuildContext context, Duration duration) =>
    reduceAnimationsOf(context) ? Duration.zero : duration;

class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder(this.delegate);

  final PageTransitionsBuilder delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceAnimationsOf(context)) return child;
    return delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

const diurnusPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ReducedMotionPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.iOS: ReducedMotionPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.macOS: ReducedMotionPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.linux: ReducedMotionPageTransitionsBuilder(
      FadeUpwardsPageTransitionsBuilder(),
    ),
    TargetPlatform.windows: ReducedMotionPageTransitionsBuilder(
      FadeUpwardsPageTransitionsBuilder(),
    ),
    TargetPlatform.fuchsia: ReducedMotionPageTransitionsBuilder(
      FadeUpwardsPageTransitionsBuilder(),
    ),
  },
);
