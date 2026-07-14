import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/wallet_transaction.dart';

/// A single wallet transaction row: icon, label, relative time and a
/// signed, colored amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.transaction, super.key});

  final WalletTransaction transaction;

  (IconData, Color) get _visual => switch (transaction.type) {
        TransactionType.win => (Icons.casino_rounded, AppColors.success),
        TransactionType.purchase => (Icons.shopping_bag_rounded, AppColors.gold),
        TransactionType.bonus => (Icons.card_giftcard_rounded, AppColors.neonPurpleLight),
        TransactionType.loss => (Icons.trending_down_rounded, AppColors.error),
      };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _visual;
    final bool positive = transaction.amount >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(transaction.label, style: AppTextStyles.titleMedium),
                Text(transaction.timeAgoLabel, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${transaction.amount}',
            style: AppTextStyles.titleMedium.copyWith(
              color: positive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
