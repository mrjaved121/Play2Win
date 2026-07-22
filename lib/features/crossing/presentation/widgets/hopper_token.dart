import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';

/// The player's token on the lane board — a glowing gradient orb. The
/// parent ([CrossingLaneBoard]) is responsible for *positioning* this via
/// `AnimatedPositioned` as `currentLane` changes (smooth slide between
/// lanes); this widget only plays a one-shot bounce/shake on top of that,
/// re-triggered whenever [laneKey] changes (a new lane reached, or a bust).
class HopperToken extends StatelessWidget {
  const HopperToken({required this.size, required this.busted, required this.laneKey, super.key});

  final double size;
  final bool busted;
  final Object laneKey;

  @override
  Widget build(BuildContext context) {
    final Color glow = busted ? AppColors.error : AppColors.gold;
    final Widget orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: busted
            ? const LinearGradient(colors: <Color>[AppColors.error, Color(0xFF7A1030)])
            : AppGradients.gold,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: AppShadows.glow(glow, intensity: 0.9),
      ),
      alignment: Alignment.center,
      child: Icon(
        busted ? Icons.close_rounded : Icons.directions_walk_rounded,
        color: busted ? AppColors.textPrimary : AppColors.textOnGold,
        size: size * 0.55,
      ),
    );

    final Widget animated = busted
        ? orb.animate(key: ValueKey<Object>(laneKey)).shake(duration: 420.ms, hz: 6)
        : orb
            .animate(key: ValueKey<Object>(laneKey))
            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 260.ms, curve: Curves.easeOutBack)
            .then()
            .shake(duration: 180.ms, hz: 3, rotation: 0.03);

    return animated;
  }
}
