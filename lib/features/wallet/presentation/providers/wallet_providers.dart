import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/hive_wallet_repository.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';

final Provider<WalletRepository> walletRepositoryProvider = Provider<WalletRepository>(
  (Ref ref) => HiveWalletRepository(getIt<StorageService>()),
);

/// Recent-activity feed shown on the Wallet screen — newest first,
/// capped so the persisted list can't grow unbounded. Recorded live by
/// [[HomeScreen]] (bets/payouts) and [[DailyBonusNotifier]] (claims) as
/// those events actually happen, not mock data.
class WalletTransactionsNotifier extends Notifier<List<WalletTransaction>> {
  static const int _maxEntries = 30;

  @override
  List<WalletTransaction> build() => ref.read(walletRepositoryProvider).load();

  void record({required TransactionType type, required String label, required int amount}) {
    if (amount == 0) return;
    final List<WalletTransaction> updated = <WalletTransaction>[
      WalletTransaction(type: type, label: label, amount: amount, timestamp: DateTime.now()),
      ...state,
    ].take(_maxEntries).toList();
    state = updated;
    unawaited(ref.read(walletRepositoryProvider).save(updated));
  }
}

final NotifierProvider<WalletTransactionsNotifier, List<WalletTransaction>> walletTransactionsProvider =
    NotifierProvider<WalletTransactionsNotifier, List<WalletTransaction>>(WalletTransactionsNotifier.new);
