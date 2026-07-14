import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// The app's default solid surface: dark purple gradient fill, hairline
/// border and a soft drop shadow. Use for the majority of cards (stat
/// tiles, mission rows, store items, list rows); reach for [GlassCard]
/// only when a translucent/overlay feel is specifically wanted.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppRadius.radiusLg,
    this.onTap,
    this.borderColor = AppColors.cardBorder,
    this.gradient,
    this.glow,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Color borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? glow;

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.card,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: glow ?? AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}
