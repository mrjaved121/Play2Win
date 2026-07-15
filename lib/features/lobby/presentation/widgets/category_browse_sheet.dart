import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/lobby_catalog.dart';
import 'category_chip_row.dart';

/// Category browser modal — mirrors LUNA-BET's "All Games / Slots / Live"
/// counts list, but sourced from the real catalog instead of placeholder
/// numbers. Tapping a row applies that filter and closes the sheet.
Future<void> showCategoryBrowseSheet(
  BuildContext context, {
  required CategoryFilter selected,
  required ValueChanged<CategoryFilter> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        CategoryBrowseSheet(selected: selected, onSelected: onSelected),
  );
}

class CategoryBrowseSheet extends StatelessWidget {
  const CategoryBrowseSheet({required this.selected, required this.onSelected, super.key});

  final CategoryFilter selected;
  final ValueChanged<CategoryFilter> onSelected;

  int _countFor(CategoryFilter filter) => switch (filter) {
        CategoryFilter.all => LobbyCatalog.games.length,
        CategoryFilter.live => LobbyCatalog.live.length,
        CategoryFilter.comingSoon => LobbyCatalog.comingSoon.length,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: AppRadius.radiusPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Category', icon: Icons.category_rounded),
          const SizedBox(height: AppSpacing.md),
          for (final CategoryFilter filter in CategoryFilter.values) ...<Widget>[
            _CategoryRow(
              filter: filter,
              count: _countFor(filter),
              selected: filter == selected,
              onTap: () {
                onSelected(filter);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final CategoryFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      borderColor: selected ? AppColors.gold : AppColors.cardBorder,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(filter.icon, color: selected ? AppColors.gold : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(filter.label, style: AppTextStyles.titleSmall),
                Text('$count games', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
