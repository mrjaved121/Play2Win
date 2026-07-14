import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Hero card promoting VIP membership — perks list + subscribe CTA.
class VipMembershipCard extends StatelessWidget {
  const VipMembershipCard({
    required this.perks,
    required this.price,
    this.onSubscribe,
    super.key,
  });

  final List<String> perks;
  final String price;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[AppColors.neonPurpleDark, AppColors.cardPurple],
      ),
      borderColor: AppColors.neonPurple,
      glow: AppShadows.purpleGlow,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 26),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('VIP Membership', style: AppTextStyles.headlineMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final String perk in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(perk, style: AppTextStyles.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          GradientButton.gold(
            label: 'SUBSCRIBE • $price/mo',
            onPressed: onSubscribe,
          ),
        ],
      ),
    );
  }
}
