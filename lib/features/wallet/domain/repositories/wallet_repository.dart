import '../entities/wallet_transaction.dart';

/// Persistence boundary for the recent-activity transaction log.
abstract class WalletRepository {
  List<WalletTransaction> load();
  Future<void> save(List<WalletTransaction> transactions);
}
