import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// One of the 3 scratch-card cells. [revealed] toggles between a covered
/// "?" tile and the symbol underneath, via a scale+fade cross-fade —
/// a simplified stand-in for real finger-drag scratch-off (which would
/// need a custom-painted erase layer); this keeps the satisfying reveal
/// beat without that added complexity.
class ScratchPanel extends StatelessWidget {
  const ScratchPanel({required this.symbol, required this.revealed, super.key});

  final String symbol;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: revealed
            ? Container(
                key: const ValueKey<bool>(true),
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.goldLight),
                ),
                alignment: Alignment.center,
                child: Text(symbol, style: const TextStyle(fontSize: 40)),
              )
            : Container(
                key: const ValueKey<bool>(false),
                decoration: BoxDecoration(
                  color: AppColors.cardPurple,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.question_mark_rounded, color: AppColors.textMuted, size: 32),
              ),
      ),
    );
  }
}
