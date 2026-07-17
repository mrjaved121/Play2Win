import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/wheel_result.dart';
import '../providers/wheel_providers.dart';
import '../widgets/wheel_dial.dart';
import '../widgets/wheel_history_strip.dart';

/// Lucky Wheel: place a bet, spin, watch the wheel land on whatever
/// segment the server already decided. Like Multiplier Climb, this screen
/// never computes a result itself — it only animates toward
/// [WheelNotifier]'s response.
class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0;

  static final double _sweep = 2 * pi / wheelSegments.length;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _rotation = AlwaysStoppedAnimation<double>(_currentRotation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final WheelPlayResult? result = await ref.read(wheelProvider.notifier).spin();
    if (result == null || !mounted) return;

    final double targetAbsolute = -(result.segmentIndex * _sweep + _sweep / 2);
    final double normalizedTarget = ((targetAbsolute % (2 * pi)) + 2 * pi) % (2 * pi);
    final double normalizedCurrent = ((_currentRotation % (2 * pi)) + 2 * pi) % (2 * pi);
    final double forwardDelta = ((normalizedTarget - normalizedCurrent) % (2 * pi) + 2 * pi) % (2 * pi);
    final double newRotation = _currentRotation + forwardDelta + (2 * pi * 5);

    _rotation = Tween<double>(begin: _currentRotation, end: newRotation)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentRotation = newRotation;

    await _controller.forward(from: 0);
    if (!mounted) return;
    ref.read(wheelProvider.notifier).finishSpin();
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isConfigured) {
      return ScreenBackground(
        child: GameServerNotConfigured(gameName: 'Lucky Wheel', onBack: () => context.pop()),
      );
    }

    final WheelUiState state = ref.watch(wheelProvider);

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
                Text('Lucky Wheel', style: AppTextStyles.headlineMedium),
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
              child: SizedBox(
                width: 300,
                height: 340,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Positioned(
                      top: 40,
                      child: AnimatedBuilder(
                        animation: _rotation,
                        builder: (BuildContext context, Widget? child) {
                          return Transform.rotate(angle: _rotation.value, child: child);
                        },
                        child: const WheelDial(size: 280),
                      ),
                    ),
                    const Positioned(
                      top: 22,
                      child: Icon(Icons.arrow_drop_down_rounded, size: 44, color: AppColors.gold),
                    ),
                    if (state.lastResult != null && state.phase == WheelPhase.idle)
                      Positioned(
                        bottom: 0,
                        child: _ResultBanner(result: state.lastResult!),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: WheelHistoryStrip(history: state.history),
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
                  if (state.phase == WheelPhase.idle) ...<Widget>[
                    Center(
                      child: HeaderInfoChip(
                        label: 'Bet',
                        value: state.bet,
                        accentColor: AppColors.neonPurpleLight,
                        onDecrement: () => ref.read(wheelProvider.notifier).adjustBet(-AppConstants.betStep),
                        onIncrement: () => ref.read(wheelProvider.notifier).adjustBet(AppConstants.betStep),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  GradientButton.primary(
                    label: state.phase == WheelPhase.spinning ? 'SPINNING…' : 'SPIN',
                    subtitle: state.phase == WheelPhase.idle ? '${state.bet} CR' : null,
                    icon: Icons.casino_rounded,
                    size: GradientButtonSize.large,
                    onPressed: state.canAffordBet && state.phase == WheelPhase.idle ? _spin : null,
                    loading: state.busy,
                    enabled: state.canAffordBet,
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

  final WheelPlayResult result;

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
