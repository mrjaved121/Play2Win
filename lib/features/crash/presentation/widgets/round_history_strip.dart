import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/crash_round.dart';

/// Small strip of past round outcomes (most recent first) — this guest's
/// own history, colored green/red for win/crash, so a played session
/// reads at a glance.
class RoundHistoryStrip extends StatelessWidget {
  const RoundHistoryStrip({required this.history, super.key});

  final List<CrashHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        'No rounds played yet this session',
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
          final CrashHistoryEntry entry = history[index];
          return BadgePill(
            label: '${entry.multiplier.toStringAsFixed(2)}x',
            color: entry.isWin ? AppColors.success : AppColors.error,
            filled: index == 0,
          );
        },
      ),
    );
  }
}
