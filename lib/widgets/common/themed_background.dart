import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;

  /// Oyun içinde soru numarasına göre farklı sahne göstermek için.
  /// Ana ekranlarda yazılmazsa otomatik 0 çalışır.
  final int variantIndex;

  const ThemedBackground({
    super.key,
    required this.child,
    this.variantIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().currentTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: _backgroundGradient(theme.id, theme.background),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ThemeBackgroundPainter(
                theme.id,
                variantIndex,
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  LinearGradient _backgroundGradient(String themeId, Color fallback) {
    switch (themeId) {
      case "space":
        return const LinearGradient(
          colors: [
            Color(0xFF120024),
            Color(0xFF321A80),
            Color(0xFF5D5FEF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

      case "car":
        return const LinearGradient(
          colors: [
            Color(0xFFFFF0C2),
            Color(0xFFFFC266),
            Color(0xFF80C7F2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

      case "forest":
        return const LinearGradient(
          colors: [
            Color(0xFFE8F5E9),
            Color(0xFFA5D6A7),
            Color(0xFF5DBB63),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

      case "rainbow":
        return const LinearGradient(
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFE0F0),
            Color(0xFFE1F5FE),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

      default:
        return LinearGradient(
          colors: [
            fallback,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}

class _ThemeBackgroundPainter extends CustomPainter {
  final String themeId;
  final int variantIndex;

  _ThemeBackgroundPainter(
      this.themeId,
      this.variantIndex,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final variant = variantIndex % 4;

    switch (themeId) {
      case "space":
        _drawSpace(canvas, size, variant);
        break;
      case "car":
        _drawCarRoad(canvas, size, variant);
        break;
      case "forest":
        _drawForest(canvas, size, variant);
        break;
      case "rainbow":
        _drawRainbow(canvas, size, variant);
        break;
      default:
        _drawSoftBubbles(canvas, size, variant);
    }
  }

  void _drawSpace(Canvas canvas, Size size, int variant) {
    final random = Random(variant + 9);

    final starPaint = Paint()..color = Colors.white.withOpacity(0.48);
    final starCount = 42 + (variant * 8);

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 1.0 + random.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    if (variant == 0) {
      _drawPlanet(
        canvas,
        Offset(size.width * 0.82, size.height * 0.22),
        54,
        const Color(0xFFFFC857).withOpacity(0.22),
      );
      _drawPlanet(
        canvas,
        Offset(size.width * 0.18, size.height * 0.78),
        38,
        const Color(0xFF80DEEA).withOpacity(0.18),
      );
      _drawOrbitLine(canvas, size, 0.88);
    } else if (variant == 1) {
      _drawMoonSurface(canvas, size);
      _drawPlanet(
        canvas,
        Offset(size.width * 0.78, size.height * 0.18),
        42,
        const Color(0xFFE1BEE7).withOpacity(0.24),
      );
    } else if (variant == 2) {
      _drawRocketWindow(canvas, size);
      _drawPlanet(
        canvas,
        Offset(size.width * 0.22, size.height * 0.22),
        46,
        const Color(0xFF4DD0E1).withOpacity(0.20),
      );
    } else {
      _drawGalaxy(canvas, size);
      _drawPlanet(
        canvas,
        Offset(size.width * 0.74, size.height * 0.72),
        50,
        const Color(0xFFFF8A65).withOpacity(0.20),
      );
    }
  }

  void _drawCarRoad(Canvas canvas, Size size, int variant) {
    if (variant == 0) {
      _drawStraightRoad(canvas, size);
      _drawRoadCircles(canvas, size);
    } else if (variant == 1) {
      _drawRaceTrack(canvas, size);
      _drawFlag(canvas, size);
    } else if (variant == 2) {
      _drawGarageScene(canvas, size);
    } else {
      _drawTrafficScene(canvas, size);
    }
  }

  void _drawForest(Canvas canvas, Size size, int variant) {
    if (variant == 0) {
      _drawForestHill(canvas, size);
      _drawLeaves(canvas, size, variant);
      _drawSun(canvas, size);
    } else if (variant == 1) {
      _drawLakeScene(canvas, size);
      _drawLeaves(canvas, size, variant);
    } else if (variant == 2) {
      _drawButterflyScene(canvas, size);
      _drawForestHill(canvas, size);
    } else {
      _drawDeepForest(canvas, size);
      _drawLeaves(canvas, size, variant);
    }
  }

  void _drawRainbow(Canvas canvas, Size size, int variant) {
    if (variant == 0) {
      _drawRainbowArc(canvas, size);
      _drawCloud(canvas, Offset(size.width * 0.20, size.height * 0.23));
      _drawCloud(canvas, Offset(size.width * 0.78, size.height * 0.18));
      _drawCloud(canvas, Offset(size.width * 0.68, size.height * 0.78));
    } else if (variant == 1) {
      _drawBalloonScene(canvas, size);
    } else if (variant == 2) {
      _drawConfettiScene(canvas, size);
    } else {
      _drawPastelWaves(canvas, size);
      _drawCloud(canvas, Offset(size.width * 0.30, size.height * 0.24));
      _drawCloud(canvas, Offset(size.width * 0.74, size.height * 0.72));
    }
  }

  void _drawSoftBubbles(Canvas canvas, Size size, int variant) {
    final paint1 = Paint()..color = Colors.white.withOpacity(0.30);
    final paint2 = Paint()..color = Colors.blueAccent.withOpacity(0.08);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.20), 38, paint1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.30), 52, paint2);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.82), 46, paint2);
  }

  // SPACE HELPERS

  void _drawPlanet(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2.4,
        height: radius * 0.72,
      ),
      ringPaint,
    );
  }

  void _drawOrbitLine(Canvas canvas, Size size, double yFactor) {
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * yFactor)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * (yFactor - 0.18),
        size.width * 0.58,
        size.height * (yFactor - 0.08),
      );

    canvas.drawPath(path, orbitPaint);
  }

  void _drawMoonSurface(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = Colors.white.withOpacity(0.14);

    final hill = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.68,
        size.width,
        size.height * 0.80,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(hill, moonPaint);

    final craterPaint = Paint()..color = Colors.black.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.82), 18, craterPaint);
    canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.88), 28, craterPaint);
  }

  void _drawRocketWindow(Canvas canvas, Size size) {
    final framePaint = Paint()..color = Colors.white.withOpacity(0.14);
    final glassPaint = Paint()..color = Colors.lightBlueAccent.withOpacity(0.12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.72),
          width: size.width * 0.64,
          height: size.height * 0.26,
        ),
        const Radius.circular(42),
      ),
      framePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.72),
          width: size.width * 0.50,
          height: size.height * 0.18,
        ),
        const Radius.circular(36),
      ),
      glassPaint,
    );
  }

  void _drawGalaxy(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final center = Offset(size.width * 0.48, size.height * 0.52);

    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * (0.35 + i * 0.16),
        height: size.height * (0.12 + i * 0.07),
      );
      canvas.drawArc(rect, i * 0.7, pi * 1.3, false, paint);
    }
  }

  // CAR HELPERS

  void _drawStraightRoad(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = const Color(0xFF37474F).withOpacity(0.30);

    final road = Path()
      ..moveTo(size.width * 0.25, size.height)
      ..lineTo(size.width * 0.42, size.height * 0.36)
      ..lineTo(size.width * 0.58, size.height * 0.36)
      ..lineTo(size.width * 0.75, size.height)
      ..close();

    canvas.drawPath(road, roadPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.60)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (double y = size.height * 0.45; y < size.height; y += 70) {
      canvas.drawLine(
        Offset(size.width * 0.5, y),
        Offset(size.width * 0.5, y + 34),
        linePaint,
      );
    }
  }

  void _drawRaceTrack(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFF263238).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.82)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.72,
        size.height * 0.58,
        size.width * 0.90,
        size.height * 0.82,
      );

    canvas.drawPath(path, trackPaint);

    final insidePaint = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, insidePaint);
  }

  void _drawFlag(Canvas canvas, Size size) {
    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 4;

    final start = Offset(size.width * 0.13, size.height * 0.18);
    canvas.drawLine(start, start + const Offset(0, 70), polePaint);

    final flagPaint = Paint()..color = Colors.redAccent.withOpacity(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(start.dx, start.dy, 58, 40),
        const Radius.circular(8),
      ),
      flagPaint,
    );
  }

  void _drawGarageScene(Canvas canvas, Size size) {
    final garagePaint = Paint()..color = Colors.black.withOpacity(0.12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.52,
          size.width * 0.68,
          size.height * 0.30,
        ),
        const Radius.circular(22),
      ),
      garagePaint,
    );

    final doorPaint = Paint()..color = Colors.white.withOpacity(0.16);

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.20, size.height * (0.57 + i * 0.055)),
        Offset(size.width * 0.80, size.height * (0.57 + i * 0.055)),
        doorPaint..strokeWidth = 3,
      );
    }
  }

  void _drawTrafficScene(Canvas canvas, Size size) {
    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..strokeWidth = 5;

    final x = size.width * 0.18;
    final y = size.height * 0.18;

    canvas.drawLine(Offset(x + 26, y + 58), Offset(x + 26, y + 145), polePaint);

    final boxPaint = Paint()..color = Colors.black.withOpacity(0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 52, 74),
        const Radius.circular(14),
      ),
      boxPaint,
    );

    final redPaint = Paint()..color = Colors.redAccent.withOpacity(0.35);
    final yellowPaint = Paint()..color = Colors.amber.withOpacity(0.35);
    final greenPaint = Paint()..color = Colors.greenAccent.withOpacity(0.35);

    canvas.drawCircle(Offset(x + 26, y + 18), 8, redPaint);
    canvas.drawCircle(Offset(x + 26, y + 37), 8, yellowPaint);
    canvas.drawCircle(Offset(x + 26, y + 56), 8, greenPaint);

    _drawStraightRoad(canvas, size);
  }

  void _drawRoadCircles(Canvas canvas, Size size) {
    final wheelPaint = Paint()..color = Colors.black.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.72), 32, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.82), 22, wheelPaint);
  }

  // FOREST HELPERS

  void _drawForestHill(Canvas canvas, Size size) {
    final hillPaint = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.20);

    final hill = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.62,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(hill, hillPaint);
  }

  void _drawLeaves(Canvas canvas, Size size, int variant) {
    final leafPaint = Paint()..color = const Color(0xFF1B5E20).withOpacity(0.17);

    for (int i = 0; i < 10; i++) {
      final x = (i * 43.0 + variant * 18) % size.width;
      final y = size.height * (0.12 + (i % 5) * 0.13);

      final rect = Rect.fromCenter(
        center: Offset(x + 26, y),
        width: 34,
        height: 18,
      );

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(i * 0.4 + variant * 0.2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawOval(rect, leafPaint);
      canvas.restore();
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunPaint = Paint()..color = const Color(0xFFFFF176).withOpacity(0.30);
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.16),
      42,
      sunPaint,
    );
  }

  void _drawLakeScene(Canvas canvas, Size size) {
    final lakePaint = Paint()..color = const Color(0xFF4FC3F7).withOpacity(0.18);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.78),
        width: size.width * 0.78,
        height: size.height * 0.18,
      ),
      lakePaint,
    );

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.46, size.height * (0.75 + i * 0.035)),
          width: size.width * 0.38,
          height: 28,
        ),
        0,
        pi,
        false,
        wavePaint,
      );
    }
  }

  void _drawButterflyScene(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.pinkAccent.withOpacity(0.18);

    for (int i = 0; i < 4; i++) {
      final cx = size.width * (0.18 + i * 0.20);
      final cy = size.height * (0.24 + (i % 2) * 0.18);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 8, cy), width: 18, height: 26),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 8, cy), width: 18, height: 26),
        paint,
      );
    }
  }

  void _drawDeepForest(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = const Color(0xFF4E342E).withOpacity(0.14);
    final treePaint = Paint()..color = const Color(0xFF1B5E20).withOpacity(0.20);

    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.12 + i * 0.19);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.58, 12, size.height * 0.23),
        trunkPaint,
      );
      canvas.drawCircle(
        Offset(x + 6, size.height * 0.53),
        34,
        treePaint,
      );
    }
  }

  // RAINBOW HELPERS

  void _drawRainbowArc(Canvas canvas, Size size) {
    final colors = [
      Colors.redAccent.withOpacity(0.20),
      Colors.orangeAccent.withOpacity(0.20),
      Colors.yellowAccent.withOpacity(0.22),
      Colors.greenAccent.withOpacity(0.20),
      Colors.blueAccent.withOpacity(0.18),
      Colors.purpleAccent.withOpacity(0.18),
    ];

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;

      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.55),
        width: size.width * (1.45 - i * 0.12),
        height: size.height * (0.95 - i * 0.08),
      );

      canvas.drawArc(rect, pi, pi, false, paint);
    }
  }

  void _drawBalloonScene(Canvas canvas, Size size) {
    final colors = [
      Colors.redAccent.withOpacity(0.22),
      Colors.blueAccent.withOpacity(0.20),
      Colors.orangeAccent.withOpacity(0.20),
      Colors.purpleAccent.withOpacity(0.18),
    ];

    for (int i = 0; i < colors.length; i++) {
      final x = size.width * (0.18 + i * 0.20);
      final y = size.height * (0.24 + (i % 2) * 0.12);

      final paint = Paint()..color = colors[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 40,
          height: 52,
        ),
        paint,
      );

      final stringPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(x, y + 26),
        Offset(x, y + 78),
        stringPaint,
      );
    }
  }

  void _drawConfettiScene(Canvas canvas, Size size) {
    final random = Random(22 + variantIndex);

    final colors = [
      Colors.redAccent.withOpacity(0.28),
      Colors.amber.withOpacity(0.28),
      Colors.blueAccent.withOpacity(0.25),
      Colors.greenAccent.withOpacity(0.25),
      Colors.purpleAccent.withOpacity(0.25),
    ];

    for (int i = 0; i < 55; i++) {
      final paint = Paint()..color = colors[i % colors.length];

      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 8, 4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawPastelWaves(Canvas canvas, Size size) {
    final paints = [
      Paint()..color = Colors.pinkAccent.withOpacity(0.12),
      Paint()..color = Colors.blueAccent.withOpacity(0.10),
      Paint()..color = Colors.orangeAccent.withOpacity(0.10),
    ];

    for (int i = 0; i < paints.length; i++) {
      final path = Path()
        ..moveTo(0, size.height * (0.55 + i * 0.10))
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height * (0.46 + i * 0.08),
          size.width,
          size.height * (0.58 + i * 0.10),
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      canvas.drawPath(path, paints[i]);
    }
  }

  void _drawCloud(Canvas canvas, Offset center) {
    final paint = Paint()..color = Colors.white.withOpacity(0.45);

    canvas.drawCircle(center + const Offset(-22, 4), 18, paint);
    canvas.drawCircle(center, 14, paint);
    canvas.drawCircle(center + const Offset(20, 5), 20, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(0, 14),
          width: 70,
          height: 22,
        ),
        const Radius.circular(999),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThemeBackgroundPainter oldDelegate) {
    return oldDelegate.themeId != themeId ||
        oldDelegate.variantIndex != variantIndex;
  }
}