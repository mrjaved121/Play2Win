import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws the "climb" line behind the big multiplier readout. Purely
/// decorative — [progress] (0..1) is an already-eased visual stand-in for
/// the multiplier (see [MultiplierStage] for the log-scale mapping), not
/// the real crash math.
class CrashCurvePainter extends CustomPainter {
  const CrashCurvePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const int _steps = 48;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Path path = Path()..moveTo(0, size.height);
    Offset head = Offset(0, size.height);
    for (int i = 1; i <= _steps; i++) {
      final double f = progress * i / _steps;
      final double x = size.width * f;
      final double y = size.height * (1 - math.pow(f, 1.8).toDouble());
      head = Offset(x, y);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    final Paint glowPaint = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(head, 11, glowPaint);
    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(head, 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CrashCurvePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
