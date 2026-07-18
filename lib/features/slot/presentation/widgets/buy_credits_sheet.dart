import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Shown when the player's balance has hit exactly 0 — distinct from
/// [showLowBalanceSheet], which covers "can't quite cover this bet" and
/// routes to the Store. Zero balance is a harder stop (no free-coin
/// sources left to top it back up — see AppConstants.dailyBonusEnabled/
/// missionsEnabled), so this routes to How to Buy instead, which is the
/// one purchase-information screen this app actually has wired up.
Future<void> showBuyCreditsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const BuyCreditsSheet(),
  );
}

class BuyCreditsSheet extends StatelessWidget {
  const BuyCreditsSheet({super.key});

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
            child: Icon(Icons.monetization_on_rounded, size: 48, color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Out of Credits', textAlign: TextAlign.center, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're out of coins. Buy more credits to keep playing.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton.gold(
            label: 'BUY CREDITS',
            icon: Icons.monetization_on_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed(RouteNames.howToBuy);
            },
          ),
        ],
      ),
    );
  }
}
