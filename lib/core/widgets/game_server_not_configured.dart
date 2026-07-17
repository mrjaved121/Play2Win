import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'glass_card.dart';
import 'icon_action_button.dart';

/// Shown instead of a game when [ApiConfig.isConfigured] is false — for
/// any game whose logic runs server-side in blackhole_admin rather than
/// on-device (Multiplier Climb, Lucky Wheel, Scratch Card), so the player
/// sees an explanation instead of every network call silently failing.
class GameServerNotConfigured extends StatelessWidget {
  const GameServerNotConfigured({required this.gameName, required this.onBack, super.key});

  final String gameName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
            ],
          ),
          const Spacer(),
          const Icon(Icons.dns_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('Game server not configured', style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Text(
              "$gameName's game logic runs in blackhole_admin, not "
              'on this device. Run the admin server (npm run dev) and '
              'relaunch this app with:\n\n'
              '--dart-define=API_BASE_URL=http://10.0.2.2:3000\n\n'
              '(use your machine\'s LAN address instead of 10.0.2.2 for a '
              'physical device; 10.0.2.2 only reaches the host from the '
              'Android emulator).',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
