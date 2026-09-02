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
    if (edition.usesLegacyTreatment) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(edition.backgroundAsset),
            fit: imageFit,
          ),
        ),
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(edition.backgroundAsset, fit: imageFit),
        ColoredBox(
          color: edition.tintColor.withValues(alpha: edition.tintOpacity),
        ),
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
