import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Limited-time bundle promo — coins + extras, a struck-through original
/// price, and a countdown to create urgency.
class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.remaining,
    this.onBuy,
    super.key,
  });

  final String title;
  final String description;
  final String originalPrice;
  final String discountedPrice;
  final Duration remaining;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: AppGradients.jackpot,
      borderColor: AppColors.gold,
      glow: AppShadows.goldGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BadgePill(label: 'LIMITED OFFER', color: AppColors.gold, filled: true),
              const Spacer(),
              const Icon(Icons.timer_rounded, size: 14, color: AppColors.goldLight),
              const SizedBox(width: 4),
              CountdownText(
                duration: remaining,
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.goldLight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Text(
                originalPrice,
                style: AppTextStyles.bodyMedium.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GradientButton.gold(label: discountedPrice, onPressed: onBuy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
