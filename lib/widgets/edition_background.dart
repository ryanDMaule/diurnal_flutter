import 'package:flutter/material.dart';

import '../models/edition.dart';

class EditionBackground extends StatelessWidget {
  const EditionBackground({
    required this.edition,
    required this.child,
    this.imageFit = BoxFit.cover,
    super.key,
  });

  final Edition edition;
  final Widget child;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: edition.backgroundColor),
        if (edition.backgroundAsset case final asset?)
          Image.asset(asset, fit: imageFit),
        if (edition.tintOpacity > 0)
          ColoredBox(
            color: edition.tintColor.withValues(alpha: edition.tintOpacity),
          ),
        if (edition.gradientColors.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: edition.gradientColors,
                stops: edition.gradientStops,
                begin: edition.gradientBegin,
                end: edition.gradientEnd,
              ),
            ),
          ),
        child,
      ],
    );
  }
}
