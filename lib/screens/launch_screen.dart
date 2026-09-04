import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  static const backgroundColor = Color(0xFF032C23);
  static const primaryColor = Color(0xFFF3EBDD);
  static const goldColor = Color(0xFFC8A363);

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 60,
                child: CustomPaint(painter: DiurnusSunrisePainter()),
              ),
              SizedBox(height: 24),
              Text(
                'Diurnus',
                style: TextStyle(
                  color: primaryColor,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 58,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              SizedBox(height: 19),
              Text(
                'ONE REMARKABLE WORD, EVERY DAY.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor,
                  fontFamily: 'Figtree',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiurnusSunrisePainter extends CustomPainter {
  const DiurnusSunrisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LaunchScreen.goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.68);
    final radius = size.width * 0.19;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.141592653589793,
      3.141592653589793,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, center.dy),
      Offset(size.width * 0.88, center.dy),
      paint,
    );

    for (final ray in <(Offset, Offset)>[
      (Offset(0.5, 0.06), Offset(0.5, 0.31)),
      (Offset(0.25, 0.17), Offset(0.36, 0.36)),
      (Offset(0.75, 0.17), Offset(0.64, 0.36)),
      (Offset(0.1, 0.4), Offset(0.29, 0.48)),
      (Offset(0.9, 0.4), Offset(0.71, 0.48)),
    ]) {
      canvas.drawLine(
        Offset(ray.$1.dx * size.width, ray.$1.dy * size.height),
        Offset(ray.$2.dx * size.width, ray.$2.dy * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DiurnusSunrisePainter oldDelegate) => false;
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
