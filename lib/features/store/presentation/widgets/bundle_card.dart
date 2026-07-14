import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// A themed bundle: an emoji icon, a title, a short contents line and a
/// price CTA — used for "Starter Pack", "High Roller Bundle", etc.
class BundleCard extends StatelessWidget {
  const BundleCard({
    required this.emoji,
    required this.title,
    required this.contents,
    required this.price,
    this.onBuy,
    super.key,
  });

  final String emoji;
  final String title;
  final String contents;
  final String price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  contents,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 92,
            child: GradientButton.secondary(
              label: price,
              size: GradientButtonSize.small,
              onPressed: onBuy,
            ),
          ),
        ],
      ),
    );
  }
}
