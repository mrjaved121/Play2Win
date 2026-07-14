import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Row of numbered dots (1..total) showing daily-bonus spin progress —
/// completed dots are filled gold, the next pending dot glows, the rest
/// stay muted.
class SpinProgressStrip extends StatelessWidget {
  const SpinProgressStrip({required this.completed, required this.total, super.key});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List<Widget>.generate(total, (int i) {
        final int day = i + 1;
        final bool done = day <= completed;
        final bool isNext = day == completed + 1;

        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: done ? AppGradients.gold : null,
            color: done ? null : AppColors.cardPurple,
            shape: BoxShape.circle,
            border: Border.all(
              color: done
                  ? AppColors.goldLight
                  : (isNext ? AppColors.neonPurpleLight : AppColors.cardBorder),
              width: isNext ? 2 : 1,
            ),
            boxShadow: done
                ? AppShadows.glow(AppColors.gold, intensity: 0.4)
                : (isNext ? AppShadows.glow(AppColors.neonPurple, intensity: 0.5) : null),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: AppColors.textOnGold)
              : Text('$day', style: AppTextStyles.bodySmall),
        );
      }),
    );
  }
}
