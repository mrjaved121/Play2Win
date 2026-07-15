import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';

/// Auto-rotating hero banner above the game rows — cycles through
/// [slides] on a timer (mirrors [CountdownText]'s `Timer.periodic`
/// pattern) while staying swipeable, with a dot indicator in the same
/// style as onboarding's page dots.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({
    required this.slides,
    this.height = 200,
    this.autoRotateInterval = const Duration(seconds: 5),
    super.key,
  });

  final List<Widget> slides;
  final double height;
  final Duration autoRotateInterval;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(widget.autoRotateInterval, (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final int next = (_page + 1) % widget.slides.length;
    unawaited(
      _controller.animateToPage(next, duration: AppConstants.animNormal, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: PageView(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _page = i),
            children: <Widget>[for (final Widget slide in widget.slides) Center(child: slide)],
          ),
        ),
        if (widget.slides.length > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < widget.slides.length; i++)
                AnimatedContainer(
                  duration: AppConstants.animFast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.gold : AppColors.cardBorder,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Jackpot hero slide: live jackpot readout + a PLAY CTA. Visual language
/// matches [SpecialOfferCard] (gradient/glow/badge) so it reads as part
/// of the same promo-card family.
class JackpotPromoSlide extends StatelessWidget {
  const JackpotPromoSlide({required this.jackpot, this.onPlay, super.key});

  final int jackpot;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: AppGradients.jackpot,
      borderColor: AppColors.gold,
      glow: AppShadows.goldGlow,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const BadgePill(
                  label: 'JACKPOT',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.gold,
                  filled: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    const Icon(Icons.monetization_on_rounded, color: AppColors.goldLight, size: 22),
                    const SizedBox(width: 4),
                    AnimatedCounterText(
                      value: jackpot,
                      style: AppTextStyles.displayJackpot.copyWith(fontSize: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Spin now for a shot at the pot',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GradientButton.gold(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            expand: false,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Mini/Medium/Grand jackpot breakdown slide — pure presentation over the
/// single pooled [jackpot] value in [GameState] (mirrors LUNA-BET's tiered
/// jackpot carousel). Tiers and their "draws between" ranges are derived
/// proportionally so no new payout logic or persisted state is needed;
/// the actual number paid out on a jackpot spin is still just [jackpot].
class JackpotTierSlide extends StatelessWidget {
  const JackpotTierSlide({required this.jackpot, this.onPlay, super.key});

  final int jackpot;
  final VoidCallback? onPlay;

  static const List<(String label, double multiplier, Color color)> _tiers = <(String, double, Color)>[
    ('MINI', 0.1, AppColors.info),
    ('MEDIUM', 1.0, AppColors.success),
    ('GRAND', 10.0, AppColors.gold),
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: AppGradients.jackpot,
      borderColor: AppColors.gold,
      glow: AppShadows.goldGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BadgePill(
                label: 'JACKPOT TIERS',
                icon: Icons.emoji_events_rounded,
                color: AppColors.gold,
                filled: true,
              ),
              const Spacer(),
              GradientButton.gold(
                label: 'PLAY',
                icon: Icons.play_arrow_rounded,
                expand: false,
                size: GradientButtonSize.small,
                onPressed: onPlay,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (String label, double multiplier, Color color) tier in _tiers)
            _TierRow(label: tier.$1, amount: (jackpot * tier.$2).round(), color: tier.$3),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.label, required this.amount, required this.color});

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int low = (amount * 0.85).round();
    final int high = (amount * 1.15).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Icon(Icons.monetization_on_rounded, size: 14, color: color),
                const SizedBox(width: 3),
                AnimatedCounterText(
                  value: amount,
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            '${low.asCompact}–${high.asCompact}',
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
