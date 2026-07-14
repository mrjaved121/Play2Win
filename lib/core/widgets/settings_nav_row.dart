import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// A tappable icon + label + trailing value/chevron row — used for
/// navigational Settings entries (Language, Privacy Policy, Terms,
/// Logout) that aren't simple toggles.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color tint = destructive ? AppColors.error : AppColors.neonPurpleLight;
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: AppRadius.radiusSm,
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 3,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: destructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            if (trailingText != null)
              Flexible(
                flex: 2,
                child: Text(
                  trailingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
