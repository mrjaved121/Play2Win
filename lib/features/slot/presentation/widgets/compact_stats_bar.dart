import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Single-line Last Win / Best Win / Spins readout — the space-saving
/// phone counterpart to [StatsRow], which is still used in the
/// tablet/web side panel.
class CompactStatsBar extends StatelessWidget {
  const CompactStatsBar({
    required this.lastWin,
    required this.bestWinToday,
    required this.gamesPlayed,
    super.key,
  });

  final int lastWin;
  final int bestWinToday;
  final int gamesPlayed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _Stat(label: 'Last Win', value: lastWin)),
          _divider(),
          Expanded(child: _Stat(label: 'Best Today', value: bestWinToday)),
          _divider(),
          Expanded(child: _Stat(label: 'Spins', value: gamesPlayed, isCoins: false)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 24, color: AppColors.cardBorder);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.isCoins = true});

  final String label;
  final int value;
  final bool isCoins;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 8)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isCoins) ...<Widget>[
              const Icon(Icons.monetization_on_rounded, size: 11, color: AppColors.gold),
              const SizedBox(width: 2),
            ],
            Text('$value', style: AppTextStyles.titleSmall),
          ],
        ),
      ],
    );
  }
}
