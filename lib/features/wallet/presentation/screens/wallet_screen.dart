import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../providers/wallet_providers.dart';
import '../widgets/transaction_row.dart';

/// Wallet screen: hero balance display, an "Add Coins" CTA into the
/// Store, and recent transaction history.
///
/// Everything here is real: balance/lifetime coins come from
/// [gameProvider], and the activity feed comes from
/// [walletTransactionsProvider] — recorded live as bets/payouts/claims
/// actually happen (see [[HomeScreen]]/[[DailyBonusNotifier]]), not mock
/// data.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final List<WalletTransaction> transactions = ref.watch(walletTransactionsProvider);

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Wallet'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              children: <Widget>[
                PremiumCard(
                  gradient: AppGradients.jackpot,
                  borderColor: AppColors.gold,
                  glow: AppShadows.goldGlow,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: <Widget>[
                      Text('CURRENT BALANCE', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      AnimatedCounterText(value: game.balance, style: AppTextStyles.displayJackpot),
                      const SizedBox(height: AppSpacing.lg),
                      GradientButton.gold(
                        label: 'ADD COINS',
                        icon: Icons.add_circle_rounded,
                        onPressed: () => context.goNamed(RouteNames.store),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        label: 'Last Win',
                        value: game.lastWin.asGrouped,
                        icon: Icons.trending_up_rounded,
                        valueColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        label: 'Lifetime Coins',
                        value: game.lifetimeWinnings.asCompact,
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Recent Activity', icon: Icons.receipt_long_rounded),
                const SizedBox(height: AppSpacing.sm),
                if (transactions.isEmpty)
                  PremiumCard(
                    child: Column(
                      children: <Widget>[
                        const Icon(Icons.receipt_long_rounded, size: 32, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No activity yet — spin the reels to get started!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  PremiumCard(
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < transactions.length; i++) ...<Widget>[
                          TransactionRow(transaction: transactions[i]),
                          if (i != transactions.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
