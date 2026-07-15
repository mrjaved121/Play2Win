import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/hive_favorites_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

final Provider<FavoritesRepository> favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (Ref ref) => HiveFavoritesRepository(getIt<StorageService>()),
);

/// The set of favorited game ids, persisted across launches.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(favoritesRepositoryProvider).load().toSet();

  void toggle(String gameId) {
    final Set<String> updated = Set<String>.of(state);
    if (!updated.remove(gameId)) updated.add(gameId);
    state = updated;
    unawaited(ref.read(favoritesRepositoryProvider).save(updated.toList()));
  }
}

final NotifierProvider<FavoritesNotifier, Set<String>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
