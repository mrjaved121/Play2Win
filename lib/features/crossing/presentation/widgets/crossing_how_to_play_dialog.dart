import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/crossing_round.dart';
import '../providers/crossing_providers.dart';

/// "How to play?" explainer — lane counts reflect live settings rather
/// than a hardcoded copy, so it can never drift from what the difficulty
/// picker actually shows.
void showCrossingHowToPlayDialog(BuildContext context, CrossingSharedState state) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardPurple,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Text('How to play?', style: AppTextStyles.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _Step(number: 1, text: 'Specify the amount of your bet.'),
            const _Step(number: 2, text: 'Choose a difficulty level. Harder levels have fewer, riskier lanes but pay off faster.'),
            _Step(
              number: 3,
              text: 'There are 4 difficulty levels in the game:\n'
                  '${CrossingDifficulty.values.map((CrossingDifficulty d) => "• ${d.label} — ${state.difficulties[d]?.laneCount ?? '—'} lanes").join('\n')}',
            ),
            const _Step(number: 4, text: 'Press "PLAY" to start your round.'),
            const _Step(
              number: 5,
              text: 'Your goal is to cross as many lanes as possible without getting caught. '
                  'You can cash out your winnings at any stage after the first lane.',
            ),
            const _Step(number: 6, text: 'Every round is provably fair — see "Provably fair settings" in the menu to verify a result.'),
            const _Step(number: 7, text: 'Malfunction voids all pays and plays.'),
          ],
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

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$number.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
