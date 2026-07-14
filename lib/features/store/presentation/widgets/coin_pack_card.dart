import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';

/// One purchasable coin pack: amount, bonus % badge, price and a Buy CTA.
class CoinPackCard extends StatelessWidget {
  const CoinPackCard({
    required this.coins,
    required this.price,
    this.bonusPercent = 0,
    this.popular = false,
    this.onBuy,
    super.key,
  });

  final int coins;
  final String price;
  final int bonusPercent;
  final bool popular;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: popular ? AppColors.gold : AppColors.cardBorder,
      glow: popular ? AppShadows.goldGlow : AppShadows.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (popular)
            const Align(
              alignment: Alignment.topRight,
              child: BadgePill(label: 'BEST VALUE', color: AppColors.gold, filled: true),
            ),
          const Text('🪙', style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            coins.asGrouped,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          if (bonusPercent > 0) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              '+$bonusPercent% BONUS',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(color: AppColors.success),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          GradientButton.gold(
            label: price,
            size: GradientButtonSize.small,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}
