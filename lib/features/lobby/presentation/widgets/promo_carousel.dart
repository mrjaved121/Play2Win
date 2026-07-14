import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
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
