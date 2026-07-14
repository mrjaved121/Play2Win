import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Frosted glassmorphism surface: blurred backdrop + translucent fill +
/// hairline border. Used for overlays and secondary surfaces that should
/// read as "floating" above the background rather than a solid card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppRadius.radiusLg,
    this.onTap,
    this.blur = 16,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final Widget card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: AppGradients.glass,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}
