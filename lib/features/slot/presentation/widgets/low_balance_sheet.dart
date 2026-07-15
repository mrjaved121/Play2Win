import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Shown when [SpinUseCase.prepareSpin] can't cover the bet — replaces the
/// previous silent no-op with LUNA-BET-style "Low balance" interstitial
/// that nudges the player to the Store instead of leaving the SPIN tap
/// looking like it did nothing.
Future<void> showLowBalanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const LowBalanceSheet(),
  );
}

class LowBalanceSheet extends StatelessWidget {
  const LowBalanceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: AppRadius.radiusPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Low Balance', textAlign: TextAlign.center, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You don't have enough coins to cover this bet. Top up your balance to keep spinning.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton.gold(
            label: 'ADD COINS',
            icon: Icons.add_circle_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed(RouteNames.store);
            },
          ),
        ],
      ),
    );
  }
}
