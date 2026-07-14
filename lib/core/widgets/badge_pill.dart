import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Small rounded label — VIP tier, "NEW", streak counters, rank chips.
class BadgePill extends StatelessWidget {
  const BadgePill({
    required this.label,
    this.icon,
    this.color = AppColors.gold,
    this.filled = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.16),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: filled ? AppColors.textOnGold : color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: filled ? AppColors.textOnGold : color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
