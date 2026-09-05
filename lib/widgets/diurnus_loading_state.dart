import 'package:flutter/material.dart';

import '../theme/interface_theme.dart';

class DiurnusLoadingState extends StatefulWidget {
  const DiurnusLoadingState({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  State<DiurnusLoadingState> createState() => _DiurnusLoadingStateState();
}

class _DiurnusLoadingStateState extends State<DiurnusLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceAnimations =
        InterfaceThemeScope.maybeControllerOf(
          context,
        )?.settings.reduceAnimations ??
        MediaQuery.disableAnimationsOf(context);
    if (reduceAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    final reduceAnimations =
        InterfaceThemeScope.maybeControllerOf(
          context,
        )?.settings.reduceAnimations ??
        MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontFamily: 'NotoSerifJP',
              fontSize: 21,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.secondary,
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              width: 160,
              height: 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: palette.secondary.withValues(alpha: 0.22),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Align(
                      alignment: Alignment(
                        reduceAnimations
                            ? 0
                            : -1 +
                                  (2 *
                                      Curves.easeInOut.transform(
                                        _controller.value,
                                      )),
                        0,
                      ),
                      child: child,
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 2,
                      child: ColoredBox(color: palette.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
