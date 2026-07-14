import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/audio_service.dart';

/// Drives a single reel's spin: builds a scrollable strip of filler
/// symbols ending in the caller-supplied final 3, and animates through
/// it with a single decelerating curve (fast start, smooth settle —
/// no separate "constant speed" phase needed since [Curves.easeOutCubic]
/// already reads as spin-then-settle).
///
/// Motion blur strength is derived from the curve's own velocity
/// (`d/dt [1-(1-t)^3] = 3(1-t)^2`) rather than a hand-tuned phase
/// schedule, so it fades out in lockstep with the reel actually slowing
/// down instead of on a fixed timer.
class ReelSpinController {
  ReelSpinController({required TickerProvider vsync, required Duration duration})
      : animationController = AnimationController(vsync: vsync, duration: duration);

  final AnimationController animationController;

  static const int fillerSymbolCount = 16;
  static const double maxBlurSigma = 7;

  /// Full scroll strip: [fillerSymbolCount] random symbols followed by
  /// the 3 symbols the reel will land on. Empty until the first
  /// [spinTo] call.
  List<SlotSymbol> strip = <SlotSymbol>[];

  final math.Random _random = math.Random();

  /// 0..1 eased scroll progress through the strip.
  double get t => Curves.easeOutCubic.transform(animationController.value);

  /// Approximates motion-blur strength from the easing curve's velocity;
  /// zero at rest (idle or once the reel has settled) and while
  /// essentially stopped mid-deceleration.
  double get blurSigma {
    if (!isSpinning) return 0;
    final double velocity = math.pow(1 - animationController.value, 2).toDouble();
    return velocity < 0.03 ? 0 : maxBlurSigma * velocity;
  }

  bool get isSpinning => animationController.isAnimating;

  /// Sets the resting (non-spinning) symbols shown before the first spin,
  /// with no filler strip to scroll through.
  void setIdle(List<SlotSymbol> symbols) {
    assert(symbols.length == GameConstants.symbolsPerReel);
    strip = symbols;
    animationController.value = 0;
  }

  /// Builds a fresh strip ending in [finalSymbols] and animates the reel
  /// from the top of that strip down to rest exactly on them.
  Future<void> spinTo(List<SlotSymbol> finalSymbols) {
    assert(finalSymbols.length == GameConstants.symbolsPerReel);
    strip = <SlotSymbol>[
      for (int i = 0; i < fillerSymbolCount; i++)
        SlotSymbol.values[_random.nextInt(SlotSymbol.values.length)],
      ...finalSymbols,
    ];
    animationController.value = 0;
    return animationController.forward().then((_) {
      if (getIt.isRegistered<AudioService>()) {
        getIt<AudioService>().playSfx(SfxType.reelStop);
      }
    });
  }

  void dispose() => animationController.dispose();
}
