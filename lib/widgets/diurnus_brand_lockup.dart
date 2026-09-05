import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiurnusBrandLockup extends StatelessWidget {
  const DiurnusBrandLockup({
    required this.markColor,
    required this.wordmarkColor,
    this.markSize = 48,
    this.wordmarkWidth = 128,
    this.spacing = 2,
    this.direction = Axis.vertical,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });

  final Color markColor;
  final Color wordmarkColor;
  final double markSize;
  final double wordmarkWidth;
  final double spacing;
  final Axis direction;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Flex(
    direction: direction,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: [
      DiurnusSunriseMark(color: markColor, size: markSize),
      SizedBox(
        width: direction == Axis.horizontal ? spacing : 0,
        height: direction == Axis.vertical ? spacing : 0,
      ),
      DiurnusWordmark(color: wordmarkColor, width: wordmarkWidth),
    ],
  );
}

class DiurnusSunriseMark extends StatelessWidget {
  const DiurnusSunriseMark({
    required this.color,
    required this.size,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/icon.svg',
    width: size,
    height: size,
    fit: BoxFit.contain,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

class DiurnusWordmark extends StatelessWidget {
  const DiurnusWordmark({
    required this.color,
    required this.width,
    super.key,
  });

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/name.svg',
    width: width,
    fit: BoxFit.contain,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
