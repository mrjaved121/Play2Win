import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/coin_explosion_game.dart';

/// Transparent, non-interactive overlay that hosts [CoinExplosionGame].
/// Sits in a [Stack] on top of the reel; the parent triggers bursts via
/// [game]'s own `burst()` method (see [HomeScreen]).
class CoinExplosionOverlay extends StatelessWidget {
  const CoinExplosionOverlay({required this.game, super.key});

  final CoinExplosionGame game;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: GameWidget(game: game),
      ),
    );
  }
}
