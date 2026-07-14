import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_slide.dart';

/// First-launch intro: 3 feature slides + a Guest Mode name entry step.
/// There's no real account system (see [[project-backend-architecture]]
/// — Firebase Auth needs the user's own project), so "sign up" here is
/// just picking a local nickname; [OnboardingCompleteNotifier] makes
/// sure this only ever shows once.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _page = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _finish() {
    final String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(playerNameProvider.notifier).setName(name);
    }
    ref.read(onboardingCompleteProvider.notifier).complete();
    context.goNamed(RouteNames.home);
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final bool lastPage = _page == _pageCount - 1;

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Opacity(
                opacity: lastPage ? 0 : 1,
                child: TextButton(
                  onPressed: lastPage ? null : _finish,
                  child: Text('Skip', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int i) => setState(() => _page = i),
              children: <Widget>[
                const OnboardingSlide(
                  icon: Icons.casino_rounded,
                  title: 'Welcome to Premium Slots',
                  description: 'Spin your way to riches in the most thrilling slot\nmachine experience on mobile.',
                ),
                const OnboardingSlide(
                  icon: Icons.emoji_events_rounded,
                  title: 'Win Big, Every Spin',
                  description: 'Weighted reels, real paylines, free spins and a\ngrowing jackpot — every spin counts.',
                ),
                const OnboardingSlide(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Daily Rewards & Missions',
                  description: 'Log in daily, complete missions, and climb the\nleaderboard to earn exclusive rewards.',
                ),
                _GuestNameSlide(controller: _nameController),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < _pageCount; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.gold : AppColors.cardBorder,
                          borderRadius: AppRadius.radiusPill,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                GradientButton.primary(
                  label: lastPage ? 'START PLAYING' : 'NEXT',
                  icon: lastPage ? Icons.play_arrow_rounded : null,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestNameSlide extends StatelessWidget {
  const _GuestNameSlide({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldLight, width: 2),
              boxShadow: AppShadows.goldGlow,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.textOnGold, size: 64),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text('What should we call you?', textAlign: TextAlign.center, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Playing as a guest — you can change this later in Profile.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
            maxLength: 20,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter a nickname',
              hintStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardPurple,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.gold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
