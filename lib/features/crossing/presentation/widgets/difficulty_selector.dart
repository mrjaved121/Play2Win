import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/crossing_round.dart';
import '../providers/crossing_providers.dart';

/// Four-tile difficulty chooser — Easy/Medium/Hard/Hardcore, each showing
/// its lane count and first-lane payout so the risk/reward tradeoff is
/// visible before betting (the ladder is public, no secret involved — see
/// [CrossingRound]'s doc comment). Reference UI uses a dropdown; this reads
/// as more "clean/professional" by surfacing the numbers up front instead
/// of hiding them behind a menu.
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    required this.selected,
    required this.difficulties,
    required this.onSelect,
    required this.enabled,
    super.key,
  });

  final CrossingDifficulty selected;
  final Map<CrossingDifficulty, DifficultyInfo> difficulties;
  final ValueChanged<CrossingDifficulty> onSelect;
  final bool enabled;

  static const Map<CrossingDifficulty, Color> _accent = <CrossingDifficulty, Color>{
    CrossingDifficulty.easy: AppColors.success,
    CrossingDifficulty.medium: AppColors.info,
    CrossingDifficulty.hard: AppColors.orange,
    CrossingDifficulty.hardcore: AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CrossingDifficulty.values
          .map(
            (CrossingDifficulty difficulty) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DifficultyTile(
                  difficulty: difficulty,
                  info: difficulties[difficulty],
                  accent: _accent[difficulty]!,
                  isSelected: difficulty == selected,
                  enabled: enabled,
                  onTap: () => onSelect(difficulty),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.info,
    required this.accent,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final CrossingDifficulty difficulty;
  final DifficultyInfo? info;
  final Color accent;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double? firstLaneMultiplier = info != null && info!.ladder.isNotEmpty ? info!.ladder.first : null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: PressableScale(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isSelected ? null : AppGradients.card,
            color: isSelected ? accent.withValues(alpha: 0.18) : null,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: isSelected ? accent : AppColors.cardBorder, width: isSelected ? 1.5 : 1),
            boxShadow: isSelected ? AppShadows.glow(accent, intensity: 0.5) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                difficulty.label,
                style: AppTextStyles.titleSmall.copyWith(color: isSelected ? accent : AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                info != null ? '${info!.laneCount} lanes' : '—',
                style: AppTextStyles.bodySmall,
              ),
              if (firstLaneMultiplier != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  '${firstLaneMultiplier.toStringAsFixed(2)}x',
                  style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
