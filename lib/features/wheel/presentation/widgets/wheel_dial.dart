import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Display spec for one wedge — mirrors blackhole_admin's WHEEL_SEGMENTS
/// (src/lib/games/wheel.ts) for rendering. The server is authoritative for
/// which segment actually wins; this list must stay in the same order and
/// count as the server's table (same convention as crash's client-side
/// MIN_BET/MAX_BET already duplicating server constants).
class WheelSegmentSpec {
  const WheelSegmentSpec({required this.label, required this.color});

  final String label;
  final Color color;
}

const List<WheelSegmentSpec> wheelSegments = <WheelSegmentSpec>[
  WheelSegmentSpec(label: 'BUST', color: AppColors.backgroundDeep),
  WheelSegmentSpec(label: '0.5x', color: AppColors.cardPurpleLight),
  WheelSegmentSpec(label: '1x', color: AppColors.info),
  WheelSegmentSpec(label: '1.5x', color: AppColors.success),
  WheelSegmentSpec(label: '2x', color: AppColors.orange),
  WheelSegmentSpec(label: '3x', color: AppColors.neonPurple),
  WheelSegmentSpec(label: '5x', color: AppColors.gold),
  WheelSegmentSpec(label: '10x', color: AppColors.jackpotRed),
];

/// The static wheel face — 8 wedges + a center hub. Rotation is applied by
/// the caller (see WheelScreen) via [Transform.rotate], not this painter,
/// so the same paint work isn't repeated every animation frame.
class WheelDial extends StatelessWidget {
  const WheelDial({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WheelPainter(),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double sweep = 2 * pi / wheelSegments.length;

    for (int i = 0; i < wheelSegments.length; i++) {
      final Paint paint = Paint()..color = wheelSegments[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep - pi / 2,
        sweep,
        true,
        paint,
      );
    }

    final Paint divider = Paint()
      ..color = AppColors.backgroundDeep
      ..strokeWidth = 2;
    for (int i = 0; i < wheelSegments.length; i++) {
      final double angle = i * sweep - pi / 2;
      canvas.drawLine(center, center + Offset(cos(angle), sin(angle)) * radius, divider);
    }

    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.gold,
    );

    for (int i = 0; i < wheelSegments.length; i++) {
      final double angle = i * sweep + sweep / 2 - pi / 2;
      final Offset labelCenter = center + Offset(cos(angle), sin(angle)) * (radius * 0.68);
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: wheelSegments[i].label,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(labelCenter.dx, labelCenter.dy);
      canvas.rotate(angle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius * 0.14, Paint()..color = AppColors.backgroundElevated);
    canvas.drawCircle(
      center,
      radius * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
