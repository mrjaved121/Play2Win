import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/onboarding_providers.dart';

/// Branded launch screen. Shown briefly on every cold start, then routes
/// to Onboarding (first launch only) or straight to Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceed());
  }

  Future<void> _proceed() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final bool onboarded = ref.read(onboardingCompleteProvider);
    if (onboarded) {
      context.goNamed(RouteNames.home);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight, width: 2),
                boxShadow: AppShadows.goldGlow,
              ),
              child: const Icon(Icons.casino_rounded, color: AppColors.textOnGold, size: 60),
            )
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .scaleXY(end: 1.08, duration: 1100.ms, curve: Curves.easeInOut),
            const SizedBox(height: AppSpacing.xxl),
            Text(AppConstants.appName, style: AppTextStyles.displayLarge)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: AppSpacing.xxxl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
