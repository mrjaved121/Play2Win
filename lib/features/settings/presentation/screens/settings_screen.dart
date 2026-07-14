import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../achievements/presentation/providers/achievements_providers.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../missions/presentation/providers/missions_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../rewards/presentation/providers/daily_bonus_providers.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

/// Settings tab: audio/haptics/appearance toggles + account/legal nav
/// rows. Music/Sound/Vibration read from and write straight through to
/// [AudioService]/[HapticService] so they stay in sync with whatever the
/// Home screen's own sound toggle does; Dark Mode is a placeholder (the
/// app is dark-themed only by design — see `AppTheme`'s doc comment).
///
/// Two distinct, deliberately separate actions live here: the "Account"
/// section's Sign In/Sign Out talks to the optional Supabase cloud
/// account (see [[LoginScreen]]); the destructive "Reset Guest Profile"
/// card wipes the local guest profile/progress and returns to
/// Onboarding. Signing out of the cloud never touches local guest data,
/// and resetting the guest profile never touches the cloud session.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _music = getIt<AudioService>().isMusicEnabled;
  late bool _sound = getIt<AudioService>().isSfxEnabled;
  late bool _vibration = getIt<HapticService>().isEnabled;
  bool _darkMode = true;

  void _showComingSoon() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More languages are coming soon.')),
    );
  }

  void _showLegalDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardPurple,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Text(title, style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Text(body, style: AppTextStyles.bodyMedium),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetGuestProfile() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardPurple,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Text('Reset guest profile?', style: AppTextStyles.titleLarge),
        content: Text(
          'This resets your guest profile — nickname, balance and progress — back to a fresh start.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Reset', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await getIt<StorageService>().clear();
    ref.invalidate(gameProvider);
    ref.invalidate(dailyBonusProvider);
    ref.invalidate(walletTransactionsProvider);
    ref.invalidate(missionsProgressProvider);
    ref.invalidate(achievementViewsProvider);
    ref.invalidate(playerNameProvider);
    ref.invalidate(onboardingCompleteProvider);

    if (mounted) context.goNamed(RouteNames.onboarding);
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider)?.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AppAuthUser? authedUser = ref.watch(authStateProvider).value;

    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Text('Settings', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Audio & Haptics', icon: Icons.tune_rounded),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            child: Column(
              children: <Widget>[
                SettingsToggleRow(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  subtitle: 'Background soundtrack',
                  value: _music,
                  onChanged: (bool v) {
                    setState(() => _music = v);
                    getIt<AudioService>().setMusicEnabled(v);
                  },
                ),
                const Divider(height: AppSpacing.lg),
                SettingsToggleRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Sound Effects',
                  subtitle: 'Spin, win and button sounds',
                  value: _sound,
                  onChanged: (bool v) {
                    setState(() => _sound = v);
                    getIt<AudioService>().setSfxEnabled(v);
                  },
                ),
                const Divider(height: AppSpacing.lg),
                SettingsToggleRow(
                  icon: Icons.vibration_rounded,
                  label: 'Vibration',
                  subtitle: 'Haptic feedback on taps and wins',
                  value: _vibration,
                  onChanged: (bool v) {
                    setState(() => _vibration = v);
                    getIt<HapticService>().setEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Appearance', icon: Icons.palette_rounded),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            child: SettingsToggleRow(
              icon: Icons.dark_mode_rounded,
              label: 'Dark Mode',
              subtitle: 'Premium casino theme',
              value: _darkMode,
              onChanged: (bool v) => setState(() => _darkMode = v),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'General', icon: Icons.settings_rounded),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            child: Column(
              children: <Widget>[
                SettingsNavRow(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  trailingText: 'English',
                  onTap: _showComingSoon,
                ),
                const Divider(height: AppSpacing.lg),
                SettingsNavRow(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy Policy',
                  onTap: () => _showLegalDialog(
                    'Privacy Policy',
                    'Premium Slots is a local, offline-first demo. Your nickname, balance and '
                        'progress are stored only on this device (via Hive) and are never sent to a '
                        'server — there is no backend connected yet.\n\n'
                        'This placeholder text should be replaced with a real privacy policy before '
                        'publishing, especially once analytics, ads, IAP or a real backend are added.',
                  ),
                ),
                const Divider(height: AppSpacing.lg),
                SettingsNavRow(
                  icon: Icons.description_rounded,
                  label: 'Terms of Service',
                  onTap: () => _showLegalDialog(
                    'Terms of Service',
                    'Premium Slots is a free-to-play game for entertainment purposes only. Coins '
                        'have no real-world monetary value and cannot be redeemed or exchanged for '
                        'cash or prizes.\n\n'
                        'This placeholder text should be replaced with real terms before publishing.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Account', icon: Icons.cloud_rounded),
          const SizedBox(height: AppSpacing.sm),
          PremiumCard(
            child: authedUser != null
                ? SettingsNavRow(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    trailingText: authedUser.email,
                    onTap: _signOut,
                  )
                : SettingsNavRow(
                    icon: Icons.login_rounded,
                    label: 'Sign in to sync progress',
                    onTap: () => context.pushNamed(RouteNames.login),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PremiumCard(
            borderColor: AppColors.error,
            child: SettingsNavRow(
              icon: Icons.restart_alt_rounded,
              label: 'Reset Guest Profile',
              destructive: true,
              onTap: _resetGuestProfile,
            ),
          ),
        ],
      ),
    );
  }
}
