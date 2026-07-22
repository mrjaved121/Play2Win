import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

enum LaneState { cleared, current, upcoming, busted }

/// One lane's tinted overlay + multiplier badge, stacked on top of
/// [LaneBoardPainter]'s static road texture at a fixed x offset. Purely
/// decorative obstacle icons appear on a few upcoming lanes for visual
/// flavor (deterministic per lane index, not tied to the real hidden
/// bust/survive draw — that stays server-side until revealed).
class LaneTile extends StatelessWidget {
  const LaneTile({
    required this.laneWidth,
    required this.multiplier,
    required this.state,
    required this.showObstacle,
    super.key,
  });

  final double laneWidth;
  final double multiplier;
  final LaneState state;
  final bool showObstacle;

  Color get _tint => switch (state) {
        LaneState.cleared => AppColors.success,
        LaneState.current => AppColors.gold,
        LaneState.upcoming => Colors.transparent,
        LaneState.busted => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final bool dim = state == LaneState.upcoming;
    return SizedBox(
      width: laneWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _tint == Colors.transparent ? AppColors.cardPurple : _tint.withValues(alpha: 0.85),
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: _tint == Colors.transparent ? AppColors.cardBorder : _tint),
            ),
            child: Text(
              '${multiplier.toStringAsFixed(2)}x',
              style: AppTextStyles.bodySmall.copyWith(
                color: _tint == Colors.transparent
                    ? AppColors.textSecondary
                    : (state == LaneState.current ? AppColors.textOnGold : AppColors.textPrimary),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
              decoration: BoxDecoration(
                color: _tint == Colors.transparent ? Colors.transparent : _tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: showObstacle && dim
                  ? Icon(Icons.directions_car_filled_rounded, size: 18, color: AppColors.textMuted.withValues(alpha: 0.4))
                  : (state == LaneState.busted
                      ? const Icon(Icons.close_rounded, color: AppColors.error, size: 20)
                          .animate()
                          .shake(duration: 400.ms)
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}
