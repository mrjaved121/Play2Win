import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/crossing_verify.dart';
import '../../domain/entities/crossing_round.dart';
import '../providers/crossing_providers.dart';

/// "Provably fair settings" — shows the editable client seed and, for the
/// most recent round, its server seed hash and (once resolved) an actual
/// working VERIFY action that recomputes the reveal client-side. Unlike
/// Multiplier Climb's equivalent panel (which only ever *displays* the
/// hash), this genuinely checks it — see `crossing_verify.dart`.
void showCrossingProvablyFairSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _ProvablyFairSheet(),
  );
}

class _ProvablyFairSheet extends ConsumerStatefulWidget {
  const _ProvablyFairSheet();

  @override
  ConsumerState<_ProvablyFairSheet> createState() => _ProvablyFairSheetState();
}

class _ProvablyFairSheetState extends ConsumerState<_ProvablyFairSheet> {
  late final TextEditingController _seedController =
      TextEditingController(text: ref.read(crossingClientSeedProvider));
  CrossingVerifyResult? _result;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _verify(CrossingRound round) {
    setState(() => _result = verifyCrossingRound(round));
  }

  @override
  Widget build(BuildContext context) {
    final CrossingRound? round = ref.watch(crossingGameProvider).round;
    final bool resolved = round != null && round.status != CrossingRoundStatus.pending;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.backgroundElevated,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: const BoxDecoration(gradient: AppGradients.gold),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.verified_user_rounded, color: AppColors.textOnGold),
                      const SizedBox(width: AppSpacing.sm),
                      Text('PROVABLY FAIR', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textOnGold)),
                      const Spacer(),
                      PressableScale(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close_rounded, color: AppColors.textOnGold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: <Widget>[
                      Text(
                        'Every round uses provably fair technology to determine its result.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('YOUR CLIENT SEED', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Mixed into every lane\'s outcome — change it any time to control your own randomness. Takes effect on your next bet.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: AppGradients.card,
                                borderRadius: AppRadius.radiusMd,
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: TextField(
                                controller: _seedController,
                                style: AppTextStyles.bodyMedium,
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                onSubmitted: (String v) => ref.read(crossingClientSeedProvider.notifier).setSeed(v),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconActionButton(
                            icon: Icons.casino_rounded,
                            size: 44,
                            onTap: () {
                              ref.read(crossingClientSeedProvider.notifier).regenerate();
                              _seedController.text = ref.read(crossingClientSeedProvider);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('CURRENT ROUND', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      if (round == null)
                        Text('Place a bet to see this round\'s seed hash here.', style: AppTextStyles.bodySmall)
                      else ...<Widget>[
                        _SeedRow(label: 'Server seed hash', value: round.serverSeedHash),
                        if (resolved) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          _SeedRow(label: 'Server seed (revealed)', value: round.serverSeed ?? ''),
                          const SizedBox(height: AppSpacing.md),
                          GradientButton.gold(label: 'VERIFY THIS ROUND', onPressed: () => _verify(round)),
                          if (_result != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            _VerifyResultCard(result: _result!),
                          ],
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'The server seed stays hidden until this round resolves — that\'s what keeps each lane\'s outcome secret until you reveal it.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(gradient: AppGradients.card, borderRadius: AppRadius.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          SelectableText(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _VerifyResultCard extends StatelessWidget {
  const _VerifyResultCard({required this.result});

  final CrossingVerifyResult result;

  @override
  Widget build(BuildContext context) {
    final Color color = result.allMatch ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(result.allMatch ? Icons.check_circle_rounded : Icons.error_rounded, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                result.allMatch ? 'Verified — outcome matches' : 'Mismatch detected',
                style: AppTextStyles.titleSmall.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'sha256(server seed) == hash: ${result.hashMatches ? 'yes' : 'no'}\n'
            '${result.laneMatches.length} lane draw(s) replayed, '
            '${result.laneMatches.values.where((bool m) => m).length} matched',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
