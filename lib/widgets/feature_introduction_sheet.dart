import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/interface_theme.dart';
import '../theme/motion_preferences.dart';

Future<void> showFeatureIntroductionSheet({
  required BuildContext context,
  required String heading,
  required String description,
  required String actionLabel,
  Widget? visual,
  bool useRecallPalette = false,
}) {
  final interfacePalette = InterfaceThemeScope.maybePaletteOf(context);
  final palette = useRecallPalette
      ? const InterfacePalette(
          brightness: Brightness.dark,
          background: Color(0xFF071E19),
          surface: Color(0xFF102923),
          primary: Color(0xFFE7E0D4),
          secondary: Color(0xFFD2C7B5),
          divider: Color(0xFF56665E),
          accent: Color(0xFFC49A52),
        )
      : interfacePalette;
  final reduceAnimations = reduceAnimationsOf(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: reduceAnimations ? AnimationStyle.noAnimation : null,
    builder: (sheetContext) => _FeatureIntroductionSheet(
      heading: heading,
      description: description,
      actionLabel: actionLabel,
      visual: visual,
      palette: palette,
    ),
  );
}

class _FeatureIntroductionSheet extends StatelessWidget {
  const _FeatureIntroductionSheet({
    required this.heading,
    required this.description,
    required this.actionLabel,
    required this.palette,
    this.visual,
  });

  final String heading;
  final String description;
  final String actionLabel;
  final Widget? visual;
  final InterfacePalette palette;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 38,
                    height: 3,
                    decoration: BoxDecoration(
                      color: palette.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const Key('close-feature-introduction'),
                    tooltip: 'Close introduction',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(CupertinoIcons.xmark, color: palette.primary),
                  ),
                ),
                Text(
                  heading,
                  style: TextStyle(
                    color: palette.primary,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 29,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.secondary,
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
                if (visual != null) ...[const SizedBox(height: 22), visual!],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('feature-introduction-action'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF17130D),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(actionLabel),
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
