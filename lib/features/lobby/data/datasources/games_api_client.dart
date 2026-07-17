import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/game_catalog_entry.dart';

/// Fetches blackhole_admin's public game catalog (`/api/public/games`) and
/// maps it to [GameCatalogEntry]. Cosmetic fields (icon/color) admin
/// doesn't manage are derived from `category`; whether a tile is playable
/// comes from `appEntryPoint` matching one of this app's real games.
class GamesApiClient {
  GamesApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Future<List<GameCatalogEntry>> fetchCatalog() async {
    final http.Response response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/api/public/games'))
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Games catalog request failed (${response.statusCode})');
    }
    final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> rows = json['games'] as List<dynamic>? ?? <dynamic>[];
    return <GameCatalogEntry>[for (final dynamic row in rows) _toEntry(row as Map<String, dynamic>)];
  }

  GameCatalogEntry _toEntry(Map<String, dynamic> json) {
    final String? entryPoint = json['appEntryPoint'] as String?;
    final String? routeName = switch (entryPoint) {
      'slots' => RouteNames.playSlots,
      'crash' => RouteNames.playCrash,
      'wheel' => RouteNames.playWheel,
      'scratch' => RouteNames.playScratch,
      _ => null,
    };
    final bool live = routeName != null && json['status'] == 'active';
    final (IconData icon, Color color) = _visualsFor(json['category'] as String?);

    return GameCatalogEntry(
      id: json['id'] as String,
      title: json['name'] as String,
      icon: icon,
      accentColor: color,
      status: live ? GameStatus.live : GameStatus.comingSoon,
      routeName: routeName,
    );
  }

  (IconData, Color) _visualsFor(String? category) => switch (category) {
        'slots' => (Icons.casino_rounded, AppColors.gold),
        'table' => (Icons.style_rounded, AppColors.orange),
        'arcade' => (Icons.rocket_launch_rounded, AppColors.error),
        'puzzle' => (Icons.grid_view_rounded, AppColors.success),
        _ => (Icons.videogame_asset_rounded, AppColors.neonPurple),
      };
}
