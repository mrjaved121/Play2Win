import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/hive_recently_played_repository.dart';
import '../../domain/repositories/recently_played_repository.dart';

final Provider<RecentlyPlayedRepository> recentlyPlayedRepositoryProvider =
    Provider<RecentlyPlayedRepository>(
  (Ref ref) => HiveRecentlyPlayedRepository(getIt<StorageService>()),
);

/// Most-recently-played game ids, newest first, capped so the persisted
/// list can't grow unbounded — same shape as
/// [[WalletTransactionsNotifier]]'s activity feed.
class RecentlyPlayedNotifier extends Notifier<List<String>> {
  static const int _maxEntries = 5;

  @override
  List<String> build() => ref.read(recentlyPlayedRepositoryProvider).load();

  void recordPlayed(String gameId) {
    final List<String> updated = <String>[
      gameId,
      ...state.where((String id) => id != gameId),
    ].take(_maxEntries).toList();
    state = updated;
    unawaited(ref.read(recentlyPlayedRepositoryProvider).save(updated));
  }
}

final NotifierProvider<RecentlyPlayedNotifier, List<String>> recentlyPlayedProvider =
    NotifierProvider<RecentlyPlayedNotifier, List<String>>(RecentlyPlayedNotifier.new);
