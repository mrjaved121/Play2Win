import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Circular player avatar with a VIP-tier-colored glow ring and an
/// optional tier pill underneath (matches the header's avatar+VIP badge
/// and the leaderboard's per-row avatars).
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    this.imageUrl,
    this.icon = Icons.person_rounded,
    this.size = 52,
    this.vipTier,
    this.showTierLabel = false,
    super.key,
  });

  final String? imageUrl;
  final IconData icon;
  final double size;

  /// Index into [AppColors.vipTierColors]; null renders a neutral ring.
  final int? vipTier;
  final bool showTierLabel;

  Color get _ringColor {
    if (vipTier == null) return AppColors.cardBorder;
    const List<Color> colors = AppColors.vipTierColors;
    return colors[vipTier!.clamp(0, colors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final Widget ring = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[_ringColor, _ringColor.withValues(alpha: 0.4)],
        ),
        boxShadow: vipTier != null ? AppShadows.glow(_ringColor, intensity: 0.7) : null,
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundElevated,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Icon(icon, size: size * 0.5, color: AppColors.textSecondary),
      ),
    );

    if (!showTierLabel || vipTier == null) return ring;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ring,
        const SizedBox(height: AppSpacing.xxs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
          decoration: BoxDecoration(
            color: _ringColor,
            borderRadius: AppRadius.radiusPill,
          ),
          child: Text(
            'VIP ${vipTier! + 1}',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textOnGold,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}
