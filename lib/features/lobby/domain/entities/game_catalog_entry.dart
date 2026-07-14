import 'package:flutter/material.dart';

/// Whether a lobby tile links to a playable game or a not-yet-built one
/// from the studio roadmap.
enum GameStatus { live, comingSoon }

/// One tile in the game lobby. Static/catalog data, not persisted state —
/// see [LobbyCatalog] for the actual list.
class GameCatalogEntry {
  const GameCatalogEntry({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    this.routeName,
    this.badgeLabel,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GameStatus status;

  /// Route to push when tapped. Required when [status] is [GameStatus.live].
  final String? routeName;

  /// Optional overline badge for live tiles, e.g. "HOT", "NEW".
  final String? badgeLabel;

  bool get isLive => status == GameStatus.live;
}
