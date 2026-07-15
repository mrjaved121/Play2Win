import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Which subset of [LobbyCatalog.games] the lobby's game sections show.
enum CategoryFilter { all, live, comingSoon }

extension CategoryFilterLabel on CategoryFilter {
  String get label => switch (this) {
        CategoryFilter.all => 'All',
        CategoryFilter.live => 'Live',
        CategoryFilter.comingSoon => 'Coming Soon',
      };

  IconData get icon => switch (this) {
        CategoryFilter.all => Icons.apps_rounded,
        CategoryFilter.live => Icons.play_circle_rounded,
        CategoryFilter.comingSoon => Icons.upcoming_rounded,
      };
}

/// Quick filter chips above the game rows — mirrors LUNA-BET's
/// All/Top/Choice row, driving which of the "Top Games"/"Coming Soon"
/// sections [LobbyScreen] renders.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    required this.selected,
    required this.onSelected,
    this.onBrowseTap,
    super.key,
  });

  final CategoryFilter selected;
  final ValueChanged<CategoryFilter> onSelected;
  final VoidCallback? onBrowseTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final CategoryFilter filter in CategoryFilter.values) ...<Widget>[
          _Chip(filter: filter, selected: filter == selected, onTap: () => onSelected(filter)),
          const SizedBox(width: AppSpacing.sm),
        ],
        const Spacer(),
        IconActionButton(icon: Icons.grid_view_rounded, size: 36, onTap: onBrowseTap),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.filter, required this.selected, required this.onTap});

  final CategoryFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.gold : AppGradients.card,
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: selected ? AppColors.gold : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(filter.icon, size: 14, color: selected ? AppColors.textOnGold : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              filter.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.textOnGold : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
