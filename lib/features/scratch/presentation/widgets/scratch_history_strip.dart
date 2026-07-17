import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/scratch_result.dart';

/// Small strip of past card outcomes (most recent first) — this guest's
/// own history, colored green/red for win/loss, same convention as the
/// crash game's round history strip.
class ScratchHistoryStrip extends StatelessWidget {
  const ScratchHistoryStrip({required this.history, super.key});

  final List<ScratchHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        'No cards played yet this session',
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
          final ScratchHistoryEntry entry = history[index];
          return BadgePill(
            label: entry.isWin ? '+${entry.winAmount}' : '0',
            color: entry.isWin ? AppColors.success : AppColors.error,
            filled: index == 0,
          );
        },
      ),
    );
  }
}
