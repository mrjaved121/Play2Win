import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// One intro slide: a glowing icon badge, a title and supporting copy.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

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
              gradient: AppGradients.neonPurple,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonPurpleLight, width: 2),
              boxShadow: AppShadows.purpleGlow,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 64),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
