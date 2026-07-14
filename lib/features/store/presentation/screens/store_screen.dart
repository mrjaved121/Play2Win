import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/bundle_card.dart';
import '../widgets/coin_pack_card.dart';
import '../widgets/special_offer_card.dart';
import '../widgets/vip_membership_card.dart';

/// Store tab: special offer, coin pack grid, VIP membership upsell and
/// themed bundles. All prices/contents are placeholder catalog data —
/// Phase 6 wires this to a real IAP catalog.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  static const List<({int coins, String price, int bonus, bool popular})> _coinPacks =
      <({int coins, String price, int bonus, bool popular})>[
    (coins: 500, price: r'$0.99', bonus: 0, popular: false),
    (coins: 1200, price: r'$2.99', bonus: 10, popular: false),
    (coins: 3000, price: r'$5.99', bonus: 20, popular: true),
    (coins: 7500, price: r'$11.99', bonus: 35, popular: false),
    (coins: 16000, price: r'$22.99', bonus: 50, popular: false),
    (coins: 35000, price: r'$44.99', bonus: 75, popular: false),
  ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: <Widget>[
            Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Purchases aren\'t connected yet — check back soon!'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int columns = context.isExpanded ? 4 : (context.isTablet ? 3 : 2);

    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Store', style: AppTextStyles.displaySmall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: <Widget>[
                SpecialOfferCard(
                  title: 'Weekend Mega Bundle',
                  description: '50,000 coins + 20 free spins + 3 days VIP',
                  originalPrice: r'$29.99',
                  discountedPrice: r'$14.99',
                  remaining: const Duration(hours: 6, minutes: 12),
                  onBuy: () => _showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Coin Packs', icon: Icons.monetization_on_rounded),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final ({int coins, String price, int bonus, bool popular}) pack =
                      _coinPacks[index];
                  return CoinPackCard(
                    coins: pack.coins,
                    price: pack.price,
                    bonusPercent: pack.bonus,
                    popular: pack.popular,
                    onBuy: () => _showComingSoon(context),
                  );
                },
                childCount: _coinPacks.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: <Widget>[
                const SizedBox(height: AppSpacing.md),
                VipMembershipCard(
                  perks: const <String>[
                    '2x coin rewards on every spin',
                    'Exclusive VIP slot machine skins',
                    'Daily bonus doubled',
                    'Priority customer support',
                  ],
                  price: r'$9.99',
                  onSubscribe: () => _showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Bundles', icon: Icons.card_giftcard_rounded),
                const SizedBox(height: AppSpacing.md),
                BundleCard(
                  emoji: '🚀',
                  title: 'Starter Pack',
                  contents: '2,000 coins + 10 free spins',
                  price: r'$1.99',
                  onBuy: () => _showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.md),
                BundleCard(
                  emoji: '💎',
                  title: 'High Roller Bundle',
                  contents: '25,000 coins + 2x multiplier token',
                  price: r'$19.99',
                  onBuy: () => _showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.md),
                BundleCard(
                  emoji: '🎰',
                  title: 'Jackpot Chaser',
                  contents: '10,000 coins + guaranteed bonus round',
                  price: r'$9.99',
                  onBuy: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
