import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Draws the static road texture behind the lane tiles — a subtle asphalt
/// gradient plus a dashed center line running the full scrollable width.
/// Purely decorative, like [CrashCurvePainter]'s "purely decorative" line:
/// per-lane state (cleared/current/busted) is colored by the lane tile
/// widgets stacked on top of this, not by this painter, so state changes
/// never need a repaint here.
class LaneBoardPainter extends CustomPainter {
  const LaneBoardPainter({required this.laneWidth, required this.laneCount});

  final double laneWidth;
  final int laneCount;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[AppColors.backgroundDeep, Color(0xFF160B28)],
      ).createShader(Offset.zero & size);
    final RRect roadRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.md));
    canvas.drawRRect(roadRect, roadPaint);

    final Paint dividerPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (int i = 1; i < laneCount; i++) {
      final double x = i * laneWidth;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), dividerPaint);
    }

    final Paint dashPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const double dashWidth = 10;
    const double dashGap = 8;
    final double centerY = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, centerY), Offset(x + dashWidth, centerY), dashPaint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant LaneBoardPainter oldDelegate) {
    return oldDelegate.laneWidth != laneWidth || oldDelegate.laneCount != laneCount;
  }
}
