import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/crash_providers.dart';
import 'crash_history_modal.dart';

/// T&C (opens a rules dialog) + HISTORY (opens the round-history modal) —
/// the two buttons shown above the multiplier stage, matching the
/// reference layout's top action row.
class CrashTopActions extends StatelessWidget {
  const CrashTopActions({required this.state, super.key});

  final CrashSharedState state;

  /// Same dialog shape as the Settings screen's legal dialogs
  /// (`_showLegalDialog` in `settings_screen.dart`) — duplicated locally
  /// rather than extracted, matching this app's existing per-feature
  /// convention (see e.g. each game's own API client).
  void _showRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardPurple,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Text('Rules & Fair Play', style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Text(
            'Multiplier Climb is a research prototype using simulated '
            '"credits" only — there is no real money anywhere in this app.\n\n'
            'Every round is provably fair: before you bet, the server commits '
            'to a hidden crash point by showing you its SHA-256 hash. Once the '
            'round ends, the server reveals the original value, so anyone can '
            'independently verify sha256(seed) matches the hash you were shown '
            'before the round started, and that the crash point really was '
            'derived from that seed — the outcome could not have been chosen '
            'after the fact.\n\n'
            'The multiplier climbs continuously from the moment you bet and '
            'can end at any point — cash out before it crashes to lock in '
            'your payout (bet × multiplier at the moment you collect). '
            'Bet limits and starting balance are configured for this '
            'prototype and may change.',
            style: AppTextStyles.bodyMedium,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: PressableScale(
            onTap: () => _showRulesDialog(context),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.neonPurpleLight),
              ),
              child: Text(
                'T&C',
                style: AppTextStyles.buttonMedium.copyWith(color: AppColors.neonPurpleLight),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: PressableScale(
            onTap: () => showCrashHistoryModal(context, state),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.radiusMd,
                boxShadow: AppShadows.button(AppColors.gold),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.textOnGold),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'HISTORY',
                    style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnGold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
