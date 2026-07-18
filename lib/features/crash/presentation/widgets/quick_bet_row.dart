import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/crash_constants.dart';

/// One-tap preset bet amounts (see [CrashConstants.quickBetPresets]) as a
/// 2x3 grid, highlighting whichever preset matches the current bet.
class QuickBetRow extends StatelessWidget {
  const QuickBetRow({required this.currentBet, required this.onSelect, required this.enabled, super.key});

  final int currentBet;
  final ValueChanged<int> onSelect;
  final bool enabled;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    const List<int> presets = CrashConstants.quickBetPresets;
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < presets.length; i += _columns) {
      final List<int> rowPresets = presets.skip(i).take(_columns).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + _columns < presets.length ? AppSpacing.xs : 0),
          child: Row(
            children: rowPresets
                .map(
                  (int amount) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _QuickBetChip(
                        amount: amount,
                        selected: amount == currentBet,
                        enabled: enabled,
                        onTap: () => onSelect(amount),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _QuickBetChip extends StatelessWidget {
  const _QuickBetChip({required this.amount, required this.selected, required this.enabled, required this.onTap});

  final int amount;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: PressableScale(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.cardPurpleLight,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(color: selected ? AppColors.gold : AppColors.cardBorder),
          ),
          child: Text(
            '$amount',
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.textOnGold : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
