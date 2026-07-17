import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../data/datasources/games_api_client.dart';
import '../../domain/entities/game_catalog_entry.dart';
import '../../domain/lobby_catalog.dart';

final Provider<GamesApiClient> gamesApiClientProvider = Provider<GamesApiClient>(
  (Ref ref) => GamesApiClient(),
);

class LobbyCatalogState {
  const LobbyCatalogState({required this.games});

  final List<GameCatalogEntry> games;

  List<GameCatalogEntry> get live => games.where((GameCatalogEntry g) => g.isLive).toList();

  List<GameCatalogEntry> get comingSoon =>
      games.where((GameCatalogEntry g) => !g.isLive).toList();
}

/// Starts from [LobbyCatalog.games] (the static, always-available roster)
/// so the lobby never shows a blank/loading state, then swaps in the
/// admin-managed catalog once fetched. Any failure — unconfigured backend,
/// network error, empty response — just keeps the static fallback rather
/// than surfacing an error, since a game hub should never look broken.
class LobbyCatalogNotifier extends Notifier<LobbyCatalogState> {
  @override
  LobbyCatalogState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_load());
    }
    return const LobbyCatalogState(games: LobbyCatalog.games);
  }

  Future<void> _load() async {
    try {
      final List<GameCatalogEntry> remote = await ref.read(gamesApiClientProvider).fetchCatalog();
      if (remote.isNotEmpty) {
        state = LobbyCatalogState(games: remote);
      }
    } catch (_) {
      // Keep the static fallback catalog.
    }
  }
}

final NotifierProvider<LobbyCatalogNotifier, LobbyCatalogState> lobbyCatalogProvider =
    NotifierProvider<LobbyCatalogNotifier, LobbyCatalogState>(LobbyCatalogNotifier.new);
