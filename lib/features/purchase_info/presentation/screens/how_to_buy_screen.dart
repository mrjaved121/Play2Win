import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/purchase_info_providers.dart';

/// Admin-editable "How to Buy Credits" info — plain text display only,
/// not a payment flow. Reached from the Help & Support screen.
class HowToBuyScreen extends ConsumerWidget {
  const HowToBuyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PurchaseInfoState state = ref.watch(purchaseInfoProvider);
    final bool hasTitle = state.info?.title.isNotEmpty ?? false;
    final bool hasContent = state.info?.content.isNotEmpty ?? false;

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          PremiumAppBar(title: hasTitle ? state.info!.title : 'How to Buy Credits'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => ref.read(purchaseInfoProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                children: <Widget>[
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                    )
                  else
                    GlassCard(
                      child: Text(
                        hasContent ? state.info!.content : 'No instructions available.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
