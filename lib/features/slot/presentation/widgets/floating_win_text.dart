import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

/// "+240"-style payout callout that floats up and fades out over the
/// reel — the "increase balance" beat that makes a win read as a win
/// before the header's balance counter finishes ticking up.
class FloatingWinText extends StatelessWidget {
  const FloatingWinText({required this.amount, super.key});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '+$amount',
      style: AppTextStyles.displayMedium.copyWith(
        color: AppColors.success,
        shadows: <Shadow>[
          Shadow(color: AppColors.success.withValues(alpha: 0.8), blurRadius: 16),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .moveY(begin: 0, end: -60, duration: 1100.ms, curve: Curves.easeOutCubic)
        .then()
        .fadeOut(duration: 300.ms);
  }
}
