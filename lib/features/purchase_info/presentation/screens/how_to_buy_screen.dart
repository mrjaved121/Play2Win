import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/purchase_info.dart';
import '../providers/purchase_info_providers.dart';

/// Admin-managed "How to Buy Credits" guide — a CMS-backed list of
/// purchase-method/FAQ entries (blackhole_admin's How to Buy page),
/// reached from Help & Support and from the "Out of Credits" sheet.
/// Display-only content, not a payment flow — this app has no payment
/// integration, so the disclaimer up top says that plainly rather than
/// implying otherwise.
class HowToBuyScreen extends ConsumerWidget {
  const HowToBuyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PurchaseInfoState state = ref.watch(purchaseInfoProvider);

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'How to Buy Credits'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => ref.read(purchaseInfoProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                children: <Widget>[
                  const _HeroBanner(),
                  const SizedBox(height: AppSpacing.md),
                  const _DemoNotice(),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Ways to Top Up', icon: Icons.payments_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _GuideList(state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: AppGradients.gold,
      borderColor: Colors.white.withValues(alpha: 0.22),
      glow: AppShadows.button(AppColors.gold),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_rounded, color: AppColors.textOnGold, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Top Up Your Balance',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.textOnGold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a method below to keep playing',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnGold.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This is a non-commercial research demo. No in-app purchase is processed automatically — '
              'each method below explains how our team tops up your balance manually. Coins have no '
              'real-world value.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.state});

  final PurchaseInfoState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (state.errorMessage != null) {
      return GlassCard(child: Text(state.errorMessage!, style: AppTextStyles.bodyMedium));
    }
    if (state.guides.isEmpty) {
      return GlassCard(
        child: Text(
          'No purchase methods published yet — check back soon, or reach out via Help & Support.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (final PurchaseGuideEntry guide in state.guides)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _GuideExpansionCard(guide: guide),
          ),
      ],
    );
  }
}

/// Picks a representative icon from the entry's title so the list reads
/// as visually distinct method-cards rather than identical text blocks —
/// purely cosmetic, admin doesn't configure this per entry.
IconData _iconForTitle(String title) {
  final String t = title.toLowerCase();
  if (t.contains('bank') || t.contains('transfer')) return Icons.account_balance_rounded;
  if (t.contains('wallet') || t.contains('jazzcash') || t.contains('easypaisa') || t.contains('mobile')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (t.contains('crypto') || t.contains('usdt') || t.contains('btc') || t.contains('bitcoin')) {
    return Icons.currency_bitcoin_rounded;
  }
  if (t.contains('card') || t.contains('credit') || t.contains('debit')) return Icons.credit_card_rounded;
  if (t.contains('support') || t.contains('contact') || t.contains('help')) return Icons.support_agent_rounded;
  return Icons.storefront_rounded;
}

class _GuideExpansionCard extends StatefulWidget {
  const _GuideExpansionCard({required this.guide});

  final PurchaseGuideEntry guide;

  @override
  State<_GuideExpansionCard> createState() => _GuideExpansionCardState();
}

class _GuideExpansionCardState extends State<_GuideExpansionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: _expanded ? AppColors.gold.withValues(alpha: 0.5) : AppColors.cardBorder,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(_iconForTitle(widget.guide.title), color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(widget.guide.title, style: AppTextStyles.titleSmall),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppConstants.animFast,
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppConstants.animNormal,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        widget.guide.content,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
