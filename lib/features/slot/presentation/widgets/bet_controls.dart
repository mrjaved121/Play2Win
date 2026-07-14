import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// "Double Bet" card — shows the bet doubling on tap (current -> next).
class DoubleBetCard extends StatelessWidget {
  const DoubleBetCard({
    required this.currentBet,
    required this.doubledBet,
    this.onDouble,
    super.key,
  });

  final int currentBet;
  final int doubledBet;
  final VoidCallback? onDouble;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Double Bet',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Increase your bet for bigger wins!',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  '$currentBet',
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.double_arrow_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$doubledBet',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.gold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientButton.secondary(
            label: 'DOUBLE',
            size: GradientButtonSize.small,
            onPressed: onDouble,
          ),
        ],
      ),
    );
  }
}

/// "Auto Spin" card — on/off toggle + a "stop after N spins" dropdown.
class AutoSpinCard extends StatelessWidget {
  const AutoSpinCard({
    required this.enabled,
    required this.stopAfter,
    required this.options,
    this.onToggle,
    this.onStopAfterChanged,
    super.key,
  });

  final bool enabled;
  final int stopAfter;
  final List<int> options;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<int?>? onStopAfterChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.autorenew_rounded, color: AppColors.neonPurpleLight, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Auto Spin',
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(value: enabled, onChanged: onToggle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Text('Stop after', style: AppTextStyles.bodySmall),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: stopAfter,
                  dropdownColor: AppColors.cardPurpleLight,
                  style: AppTextStyles.titleSmall,
                  borderRadius: AppRadius.radiusSm,
                  items: <DropdownMenuItem<int>>[
                    for (final int option in options)
                      DropdownMenuItem<int>(value: option, child: Text('$option')),
                  ],
                  onChanged: enabled ? onStopAfterChanged : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
