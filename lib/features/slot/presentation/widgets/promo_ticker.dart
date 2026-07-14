import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';

/// The thin strip above the game area: a "so-and-so just won" callout on
/// the left and a limited-offer countdown on the right. Stacks vertically
/// on very narrow screens.
class PromoTicker extends StatelessWidget {
  const PromoTicker({
    required this.winnerName,
    required this.winnerAmount,
    required this.offerRemaining,
    super.key,
  });

  final String winnerName;
  final int winnerAmount;
  final Duration offerRemaining;

  @override
  Widget build(BuildContext context) {
    final Widget winner = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: <InlineSpan>[
                TextSpan(text: '$winnerName just won '),
                TextSpan(
                  text: '$winnerAmount coins!',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final Widget offer = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.timer_rounded, size: 14, color: AppColors.error),
        const SizedBox(width: AppSpacing.xs),
        Text('LIMITED OFFER ENDS IN', style: AppTextStyles.label.copyWith(fontSize: 9)),
        const SizedBox(width: AppSpacing.xs),
        CountdownText(
          duration: offerRemaining,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.error),
        ),
      ],
    );

    if (context.isCompact) {
      return PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            winner,
            const SizedBox(height: AppSpacing.xs),
            offer,
          ],
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(child: winner),
          const SizedBox(width: AppSpacing.lg),
          offer,
        ],
      ),
    );
  }
}
