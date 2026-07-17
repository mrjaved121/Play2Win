import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Top-of-screen bar: back button, title, and the server-tracked balance
/// (deliberately labeled "Server Credits" — this is a separate,
/// server-authoritative balance from the local Wallet balance the slot
/// machine uses; see the admin backend's crash-game README section).
class CrashHeader extends StatelessWidget {
  const CrashHeader({
    required this.balance,
    required this.balanceLoading,
    required this.onBack,
    super.key,
  });

  final int? balance;
  final bool balanceLoading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Back to lobby',
          child: IconActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Multiplier Climb', style: AppTextStyles.titleLarge),
              Text('Server Credits', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        HeaderInfoChip(
          label: 'Balance',
          value: balance ?? 0,
          icon: Icons.dns_rounded,
          accentColor: AppColors.gold,
          animateValue: !balanceLoading,
        ),
      ],
    );
  }
}
