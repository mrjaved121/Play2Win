import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'premium_card.dart';

/// Small icon + label + value tile used for stats rows (Last Win, Best
/// Win Today, Games Played, …) and profile statistics grids.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor = AppColors.textPrimary,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: AppColors.gold),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(color: valueColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
