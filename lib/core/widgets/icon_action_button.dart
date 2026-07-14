import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Circular glass icon button used for header actions (Settings,
/// Notifications, Wallet, Profile). Optionally shows a small unread-count
/// badge in the corner.
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
    this.size = 44,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.glass,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: size * 0.5, color: AppColors.textPrimary),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
