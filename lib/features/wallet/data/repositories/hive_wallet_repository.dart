import '../../../../core/services/storage_service.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Stores the recent-activity list as a JSON array in the default Hive
/// box — same map-based approach as [[HiveGameRepository]] (see
/// [[project-build-environment-gotchas]] for why: no `hive_generator`).
class HiveWalletRepository implements WalletRepository {
  HiveWalletRepository(this._storage);

  final StorageService _storage;

  static const String _key = 'wallet_transactions';

  @override
  List<WalletTransaction> load() {
    final List<dynamic>? raw = _storage.get<List<dynamic>>(_key);
    if (raw == null) return const <WalletTransaction>[];
    return <WalletTransaction>[
      for (final dynamic entry in raw)
        WalletTransaction.fromJson((entry as Map<dynamic, dynamic>).cast<String, dynamic>()),
    ];
  }

  @override
  Future<void> save(List<WalletTransaction> transactions) {
    return _storage.put<List<Map<String, dynamic>>>(
      _key,
      <Map<String, dynamic>>[for (final WalletTransaction t in transactions) t.toJson()],
    );
  }
}
