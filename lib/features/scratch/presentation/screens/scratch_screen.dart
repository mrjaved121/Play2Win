import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/scratch_result.dart';
import '../providers/scratch_providers.dart';
import '../widgets/scratch_history_strip.dart';
import '../widgets/scratch_panel.dart';

/// Scratch Card: buy a card, watch the 3 panels reveal whatever the server
/// already decided. Like Lucky Wheel, the reveal animation is purely
/// cosmetic over an already-resolved result — see ScratchNotifier.
class ScratchScreen extends ConsumerStatefulWidget {
  const ScratchScreen({super.key});

  @override
  ConsumerState<ScratchScreen> createState() => _ScratchScreenState();
}

class _ScratchScreenState extends ConsumerState<ScratchScreen> {
  List<bool> _revealed = <bool>[false, false, false];
  List<String> _panelSymbols = <String>['❔', '❔', '❔'];

  Future<void> _playAndReveal() async {
    final ScratchPlayResult? result = await ref.read(scratchProvider.notifier).buy();
    if (result == null || !mounted) return;

    setState(() {
      _panelSymbols = result.panels;
      _revealed = <bool>[false, false, false];
    });

    for (int i = 0; i < _panelSymbols.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _revealed[i] = true);
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    ref.read(scratchProvider.notifier).finishReveal(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isConfigured) {
      return ScreenBackground(
        child: GameServerNotConfigured(gameName: 'Scratch Card', onBack: () => context.pop()),
      );
    }

    final ScratchUiState state = ref.watch(scratchProvider);

    return ScreenBackground(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: <Widget>[
                IconActionButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const Spacer(),
                Text('Scratch Card', style: AppTextStyles.headlineMedium),
                const Spacer(),
                HeaderInfoChip(
                  label: 'Balance',
                  value: state.balance ?? 0,
                  icon: Icons.monetization_on_rounded,
                  animateValue: !state.balanceLoading,
                ),
              ],
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: _ErrorBanner(message: state.errorMessage!),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        for (int i = 0; i < 3; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(child: ScratchPanel(symbol: _panelSymbols[i], revealed: _revealed[i])),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (state.lastResult != null && state.phase == ScratchPhase.idle)
                      _ResultBanner(result: state.lastResult!),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: ScratchHistoryStrip(history: state.history),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.backgroundElevated,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (state.phase == ScratchPhase.idle) ...<Widget>[
                    Center(
                      child: HeaderInfoChip(
                        label: 'Cost',
                        value: state.cost,
                        accentColor: AppColors.neonPurpleLight,
                        onDecrement: () => ref.read(scratchProvider.notifier).adjustCost(-AppConstants.betStep),
                        onIncrement: () => ref.read(scratchProvider.notifier).adjustCost(AppConstants.betStep),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  GradientButton.primary(
                    label: state.phase == ScratchPhase.revealing ? 'REVEALING…' : 'BUY CARD',
                    subtitle: state.phase == ScratchPhase.idle ? '${state.cost} CR' : null,
                    icon: Icons.style_rounded,
                    size: GradientButtonSize.large,
                    onPressed: state.canAfford && state.phase == ScratchPhase.idle ? _playAndReveal : null,
                    loading: state.busy,
                    enabled: state.canAfford,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final ScratchPlayResult result;

  @override
  Widget build(BuildContext context) {
    final bool won = result.winAmount > 0;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Text(
        won ? 'You won ${result.winAmount} CR! (${result.multiplier}x)' : 'No win this time',
        style: AppTextStyles.titleSmall.copyWith(color: won ? AppColors.success : AppColors.textSecondary),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
        ],
      ),
    );
  }
}
