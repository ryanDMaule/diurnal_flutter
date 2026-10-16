import 'package:flutter/material.dart';

import '../theme/colors.dart';

class MorphingMenuButton extends StatelessWidget {
  const MorphingMenuButton({
    required this.isOpen,
    required this.onPressed,
    required this.tooltip,
    this.color = AppColors.textPrimary,
    this.highlight = 0,
    this.highlightColor = AppColors.textSecondary,
    super.key,
  });

  static const _heroTag = 'diurnus-menu-control';

  final bool isOpen;
  final VoidCallback onPressed;
  final String tooltip;
  final Color color;
  final double highlight;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('menu-control-highlight'),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlightColor.withValues(alpha: 0.08 * highlight),
        border: Border.all(
          color: highlightColor.withValues(alpha: 0.42 * highlight),
        ),
        boxShadow: highlight <= 0
            ? null
            : [
                BoxShadow(
                  color: highlightColor.withValues(alpha: 0.18 * highlight),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Semantics(
        button: true,
        label: tooltip,
        child: IconButton(
          key: Key(isOpen ? 'close-menu-control' : 'open-menu-control'),
          onPressed: onPressed,
          icon: Hero(
            tag: _heroTag,
            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
            flightShuttleBuilder:
                (flightContext, animation, direction, fromContext, toContext) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return _MenuGlyph(
                        progress: animation.value,
                        color: color,
                      );
                    },
                  );
                },
            child: _MenuGlyph(progress: isOpen ? 1 : 0, color: color),
          ),
        ),
      ),
    );
  }
}

class _MenuGlyph extends StatelessWidget {
  const _MenuGlyph({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(28),
      painter: _MenuGlyphPainter(progress, color),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  const _MenuGlyphPainter(this.progress, this.color);

  final double progress;
  final Color color;

  Offset _lerp(Offset begin, Offset end) {
    return Offset.lerp(begin, end, progress)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      _lerp(const Offset(4, 7), const Offset(5, 5)),
      _lerp(const Offset(24, 7), const Offset(23, 23)),
      paint,
    );

    paint.color = color.withValues(alpha: 1 - progress);
    canvas.drawLine(
      _lerp(const Offset(4, 14), const Offset(14, 14)),
      _lerp(const Offset(24, 14), const Offset(14, 14)),
      paint,
    );

    paint.color = color;
    canvas.drawLine(
      _lerp(const Offset(4, 21), const Offset(5, 23)),
      _lerp(const Offset(24, 21), const Offset(23, 5)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MenuGlyphPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
