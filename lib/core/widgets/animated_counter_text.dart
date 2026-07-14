import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Text that smoothly tweens between the old and new [value] whenever it
/// changes, instead of snapping — used for balance/bet/jackpot readouts
/// so wins visibly "count up".
class AnimatedCounterText extends StatelessWidget {
  const AnimatedCounterText({
    required this.value,
    required this.style,
    this.duration = AppConstants.animSlow,
    this.prefix = '',
    super.key,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final String prefix;

  static final NumberFormat _format = NumberFormat.decimalPattern('en_US');

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text('$prefix${_format.format(animatedValue.round())}', style: style);
      },
    );
  }
}
