import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

/// "JACKPOT!" callout shown when a spin hits the progressive jackpot —
/// bigger and gaudier than [NearMissBanner], paired with confetti and a
/// coin-burst triggered by the caller.
class JackpotBanner extends StatelessWidget {
  const JackpotBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'JACKPOT!',
      style: AppTextStyles.displayJackpot.copyWith(
        fontSize: 44,
        shadows: <Shadow>[
          Shadow(color: AppColors.gold.withValues(alpha: 0.9), blurRadius: 20),
          Shadow(color: AppColors.orange.withValues(alpha: 0.7), blurRadius: 40),
        ],
      ),
    )
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .scaleXY(end: 1.1, duration: 450.ms, curve: Curves.easeInOut)
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack)
        .shake(hz: 4, rotation: 0.05, duration: 600.ms);
  }
}
