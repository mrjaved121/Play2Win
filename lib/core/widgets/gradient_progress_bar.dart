import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/theme.dart';

/// Rounded progress track with an animated gradient fill. Used for daily
/// bonus spin progress, mission progress and profile XP bars.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    required this.progress,
    this.gradient = AppGradients.success,
    this.height = 10,
    this.trackColor = AppColors.cardBorder,
    super.key,
  });

  /// 0.0 - 1.0
  final double progress;
  final Gradient gradient;
  final double height;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: AppConstants.animSlow,
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clamped,
              height: height,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
