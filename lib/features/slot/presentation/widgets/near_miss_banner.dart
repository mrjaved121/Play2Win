import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

/// "SO CLOSE!" callout shown after a near-miss spin (two matching
/// symbols + one adjacent-in-paytable symbol on a payline). Purely a
/// presentation component — Phase 4's game logic decides *when* to show
/// it via [GameConstants.nearMissChance].
class NearMissBanner extends StatelessWidget {
  const NearMissBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'SO CLOSE!',
      style: AppTextStyles.displayLarge.copyWith(
        color: AppColors.gold,
        shadows: <Shadow>[
          Shadow(color: AppColors.gold.withValues(alpha: 0.8), blurRadius: 18),
          Shadow(color: AppColors.orange.withValues(alpha: 0.6), blurRadius: 32),
        ],
      ),
    )
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .scaleXY(end: 1.08, duration: 600.ms, curve: Curves.easeInOut)
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
  }
}
