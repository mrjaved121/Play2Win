import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../missions/domain/entities/missions_progress.dart';
import '../../../missions/presentation/providers/missions_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../rewards/domain/entities/daily_bonus_state.dart';
import '../../../rewards/presentation/providers/daily_bonus_providers.dart';
import '../../../slot/domain/entities/game_state.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../../wallet/domain/entities/wallet_transaction.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../data/repositories/supabase_progress_repository.dart';
import '../../domain/repositories/progress_repository.dart';

/// Null when Supabase isn't configured — mirrors [[authRepositoryProvider]].
final Provider<ProgressRepository?> progressRepositoryProvider = Provider<ProgressRepository?>((Ref ref) {
  if (!getIt.isRegistered<SupabaseClient>()) return null;
  return SupabaseProgressRepository(getIt<SupabaseClient>());
});

final Provider<ProgressSyncController> progressSyncControllerProvider =
    Provider<ProgressSyncController>((Ref ref) => ProgressSyncController(ref));

/// Syncs local guest progress with the cloud at the moment of a
/// successful sign-in/sign-up — not continuously — so it only runs when
/// [[LoginScreen]] explicitly calls it, never on every cold start (a
/// global auth-state listener would re-run this on every app launch
/// where a session was already restored, which risks clobbering local
/// progress made since the last real sync).
///
/// Conflict rule: whichever save has played more (`totalSpins`) wins —
/// never silently discards the more-advanced one. First sync for an
/// account just backs local up to the cloud.
class ProgressSyncController {
  ProgressSyncController(this._ref);

  final Ref _ref;

  Future<void> syncOnSignIn(String userId) async {
    final ProgressRepository? repo = _ref.read(progressRepositoryProvider);
    if (repo == null) return;

    try {
      final Map<String, dynamic>? remote = await repo.fetch(userId);
      if (remote == null) {
        await repo.push(userId, _buildSnapshot());
        return;
      }

      final Map<String, dynamic>? remoteGameJson = remote['gameState'] as Map<String, dynamic>?;
      final int remoteSpins =
          remoteGameJson != null ? ((remoteGameJson['totalSpins'] as num?)?.toInt() ?? 0) : 0;
      final int localSpins = _ref.read(gameRepositoryProvider).load().totalSpins;

      if (remoteSpins > localSpins) {
        await _applySnapshot(remote);
      } else {
        await repo.push(userId, _buildSnapshot());
      }
    } catch (_) {
      // Best-effort — a network hiccup here should never block sign-in.
    }
  }

  Map<String, dynamic> _buildSnapshot() {
    final DailyBonusState? dailyBonus = _ref.read(dailyBonusRepositoryProvider).load();
    final MissionsProgress? missions = _ref.read(missionsRepositoryProvider).load();
    return <String, dynamic>{
      'playerName': _ref.read(playerNameProvider),
      'gameState': _ref.read(gameRepositoryProvider).load().toJson(),
      'walletTransactions': <Map<String, dynamic>>[
        for (final WalletTransaction t in _ref.read(walletRepositoryProvider).load()) t.toJson(),
      ],
      if (dailyBonus != null) 'dailyBonus': dailyBonus.toJson(),
      if (missions != null) 'missionsProgress': missions.toJson(),
    };
  }

  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    final String? playerName = snapshot['playerName'] as String?;
    if (playerName != null && playerName.isNotEmpty) {
      _ref.read(playerNameProvider.notifier).setName(playerName);
    }

    final Map<String, dynamic>? gameJson = snapshot['gameState'] as Map<String, dynamic>?;
    if (gameJson != null) {
      await _ref.read(gameRepositoryProvider).save(GameState.fromJson(gameJson));
      _ref.invalidate(gameProvider);
    }

    final List<dynamic>? txJson = snapshot['walletTransactions'] as List<dynamic>?;
    if (txJson != null) {
      final List<WalletTransaction> transactions = <WalletTransaction>[
        for (final dynamic e in txJson)
          WalletTransaction.fromJson((e as Map<dynamic, dynamic>).cast<String, dynamic>()),
      ];
      await _ref.read(walletRepositoryProvider).save(transactions);
      _ref.invalidate(walletTransactionsProvider);
    }

    final Map<String, dynamic>? bonusJson = snapshot['dailyBonus'] as Map<String, dynamic>?;
    if (bonusJson != null) {
      await _ref.read(dailyBonusRepositoryProvider).save(DailyBonusState.fromJson(bonusJson));
      _ref.invalidate(dailyBonusProvider);
    }

    final Map<String, dynamic>? missionsJson = snapshot['missionsProgress'] as Map<String, dynamic>?;
    if (missionsJson != null) {
      await _ref.read(missionsRepositoryProvider).save(MissionsProgress.fromJson(missionsJson));
      _ref.invalidate(missionsProgressProvider);
    }
  }
}
