import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Size presets for [GradientButton].
enum GradientButtonSize { small, medium, large }

/// The app's primary call-to-action button: a gradient-filled, glowing,
/// tap-scaling pill. Every gradient CTA (SPIN, CLAIM, DOUBLE, AUTO SPIN,
/// store purchase buttons, …) should be built from this rather than a
/// one-off `Container` + `GestureDetector`.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.gradient,
    this.onPressed,
    this.icon,
    this.subtitle,
    this.size = GradientButtonSize.medium,
    this.glowColor,
    this.textColor,
    this.expand = true,
    this.enabled = true,
    this.loading = false,
    super.key,
  });

  /// Orange gradient — the game's default CTA (SPIN, primary actions).
  static GradientButton primary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    String? subtitle,
    GradientButtonSize size = GradientButtonSize.medium,
    bool expand = true,
    bool enabled = true,
    bool loading = false,
  }) {
    return GradientButton(
      label: label,
      gradient: AppGradients.primaryButton,
      glowColor: AppColors.orange,
      onPressed: onPressed,
      icon: icon,
      subtitle: subtitle,
      size: size,
      expand: expand,
      enabled: enabled,
      loading: loading,
    );
  }

  /// Neon purple gradient — secondary actions (Auto Spin, Double).
  static GradientButton secondary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    GradientButtonSize size = GradientButtonSize.medium,
    bool expand = true,
    bool enabled = true,
  }) {
    return GradientButton(
      label: label,
      gradient: AppGradients.neonPurple,
      glowColor: AppColors.neonPurple,
      onPressed: onPressed,
      icon: icon,
      size: size,
      expand: expand,
      enabled: enabled,
    );
  }

  /// Green gradient — positive confirmations (Claim, Collect).
  static GradientButton success({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    GradientButtonSize size = GradientButtonSize.medium,
    bool expand = true,
    bool enabled = true,
  }) {
    return GradientButton(
      label: label,
      gradient: AppGradients.success,
      glowColor: AppColors.success,
      onPressed: onPressed,
      icon: icon,
      size: size,
      expand: expand,
      enabled: enabled,
    );
  }

  /// Gold gradient — premium/jackpot actions (purchases, VIP upsell).
  static GradientButton gold({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    GradientButtonSize size = GradientButtonSize.medium,
    bool expand = true,
    bool enabled = true,
  }) {
    return GradientButton(
      label: label,
      gradient: AppGradients.gold,
      glowColor: AppColors.gold,
      textColor: AppColors.textOnGold,
      onPressed: onPressed,
      icon: icon,
      size: size,
      expand: expand,
      enabled: enabled,
    );
  }

  final String label;
  final String? subtitle;
  final Gradient gradient;
  final Color? glowColor;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GradientButtonSize size;
  final bool expand;
  final bool enabled;
  final bool loading;
  final Color? textColor;

  double get _height => switch (size) {
        GradientButtonSize.small => 40,
        GradientButtonSize.medium => 52,
        GradientButtonSize.large => 64,
      };

  TextStyle _labelStyle() {
    final TextStyle base = switch (size) {
      GradientButtonSize.small => AppTextStyles.buttonMedium,
      GradientButtonSize.medium => AppTextStyles.buttonLarge,
      GradientButtonSize.large =>
        AppTextStyles.buttonLarge.copyWith(fontSize: 22),
    };
    return base.copyWith(color: textColor ?? AppColors.textPrimary);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && !loading && onPressed != null;

    final Widget content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: textColor ?? AppColors.textPrimary,
            ),
          )
        // `FittedBox` absorbs sub-pixel mismatches between this fixed-height
        // button and its text content's intrinsic height (e.g. the large
        // size's 22px label + subtitle is ~1px taller than `_height` at
        // some font metrics) instead of throwing a RenderFlex overflow.
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(
                        icon,
                        color: textColor ?? AppColors.textPrimary,
                        size: size == GradientButtonSize.small ? 16 : 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      label,
                      style: _labelStyle(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: (textColor ?? AppColors.textPrimary)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          );

    return Opacity(
      opacity: isEnabled || loading ? 1 : 0.45,
      child: PressableScale(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          height: _height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: size == GradientButtonSize.small ? AppSpacing.sm : AppSpacing.xl,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: isEnabled && glowColor != null
                ? AppShadows.button(glowColor!)
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
