import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/edition.dart';
import '../theme/interface_theme.dart';

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
    final settings = InterfaceThemeScope.maybeControllerOf(context)?.settings;
    final showTexture =
        edition.id == Editions.evergreen.id &&
        (settings?.textureEnabled ?? true);
    final usesPaper = settings?.interfaceColor == InterfaceColor.paper;
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
        if (showTexture)
          InterfaceTextureOverlay(
            asset: usesPaper
                ? 'assets/images/paper.png'
                : 'assets/images/leather.png',
            baseColor: edition.backgroundColor,
            strength: usesPaper ? 0.10 : 0.06,
          ),
        child,
      ],
    );
  }
}
