import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/wheel_result.dart';

/// Small strip of past spin outcomes (most recent first) — this guest's
/// own history, colored green/red for win/loss, same convention as the
/// crash game's round history strip.
class WheelHistoryStrip extends StatelessWidget {
  const WheelHistoryStrip({required this.history, super.key});

  final List<WheelHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        'No spins played yet this session',
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      );
    }
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final WheelHistoryEntry entry = history[index];
          return BadgePill(
            label: '${entry.multiplier.toStringAsFixed(entry.multiplier == entry.multiplier.roundToDouble() ? 0 : 1)}x',
            color: entry.isWin ? AppColors.success : AppColors.error,
            filled: index == 0,
          );
        },
      ),
    );
  }
}
