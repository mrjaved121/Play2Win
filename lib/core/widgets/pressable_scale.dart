import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../di/service_locator.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

/// Wraps [child] with a tap-scale micro-interaction: shrinks slightly on
/// press and springs back on release, plus a button-click sound and a
/// light haptic tick. Every tappable card/button in the app should go
/// through this instead of hand-rolling its own `GestureDetector` +
/// `AnimatedScale` pair.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.enabled = true,
    this.playClickSound = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  /// Set false for widgets that trigger their own more specific sound
  /// (e.g. the SPIN button plays [SfxType.spin] instead).
  final bool playClickSound;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.playClickSound && getIt.isRegistered<AudioService>()) {
      unawaited(getIt<AudioService>().playSfx(SfxType.buttonClick));
    }
    if (getIt.isRegistered<HapticService>()) {
      getIt<HapticService>().light();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onTap != null;
    return GestureDetector(
      onTap: interactive ? _handleTap : null,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppConstants.animFast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
