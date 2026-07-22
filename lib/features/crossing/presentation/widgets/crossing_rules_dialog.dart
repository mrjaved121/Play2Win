import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../providers/crossing_providers.dart';

/// "Game rules" dialog — bet limits from live settings, mirrors the
/// reference UI's Min bet / Max bet / Max win rows.
void showCrossingRulesDialog(BuildContext context, CrossingSharedState state) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardPurple,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Text('Game rules', style: AppTextStyles.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Bet limits are presented below', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _RuleRow(label: 'Min bet', value: '${state.minBet} CR'),
          const SizedBox(height: AppSpacing.sm),
          _RuleRow(label: 'Max bet', value: '${state.maxBet} CR'),
          const SizedBox(height: AppSpacing.sm),
          _RuleRow(label: 'Max win', value: '${state.maxWin} CR'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Malfunction voids all pays and plays',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('Close', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold)),
        ),
      ],
    ),
  );
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(gradient: AppGradients.card, borderRadius: AppRadius.radiusMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.titleSmall.copyWith(color: AppColors.gold)),
        ],
      ),
    );
  }
}
