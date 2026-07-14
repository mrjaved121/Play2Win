import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Flame-powered coin-burst particle effect, fired from [HomeScreen] when
/// a spin resolves as a win. This is the one place in the app that
/// reaches for Flame rather than plain Flutter animation — a radial
/// burst of many independently-accelerated, fading particles is exactly
/// what Flame's particle system is built for, unlike the reel spin
/// (Phase 3), which is a simple widget-scroll problem better served by a
/// plain `AnimationController`.
class CoinExplosionGame extends FlameGame {
  final math.Random _random = math.Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  /// Spawns a radial burst of gold particles from [origin] (in this
  /// game's local coordinate space, i.e. relative to the overlay's own
  /// size) that arc outward and fall with gravity before fading out.
  void burst({required Vector2 origin, int count = 26, double intensity = 1.0}) {
    add(
      ParticleSystemComponent(
        position: origin,
        particle: Particle.generate(
          count: count,
          lifespan: 1.0 + _random.nextDouble() * 0.3,
          generator: (int i) {
            final double angle = _random.nextDouble() * math.pi * 2;
            final double speed = (140 + _random.nextDouble() * 220) * intensity;
            final Vector2 velocity = Vector2(math.cos(angle), math.sin(angle) * 0.7 - 0.7) * speed;
            final Color color = <Color>[
              AppColors.gold,
              AppColors.goldLight,
              AppColors.goldDark,
            ][_random.nextInt(3)];

            return AcceleratedParticle(
              speed: velocity,
              acceleration: Vector2(0, 480),
              child: CircleParticle(
                radius: 2.5 + _random.nextDouble() * 3.5,
                paint: Paint()..color = color,
              ),
            );
          },
        ),
      ),
    );
  }
}
