import 'package:flutter/material.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme.dart';

/// Renders a single reel symbol.
///
/// No symbol artwork ships with the project yet (`assets/images/symbols/`
/// is an empty placeholder folder — see Phase 1 notes), so this paints a
/// premium-looking stand-in per symbol (emoji glyph or a styled "BAR" /
/// gradient "7" lockup) rather than waiting on real art. Swapping in real
/// PNG/SVG art later only means changing this one widget.
class SlotSymbolView extends StatelessWidget {
  const SlotSymbolView({
    required this.symbol,
    this.size = 64,
    this.dimmed = false,
    super.key,
  });

  final SlotSymbol symbol;
  final double size;

  /// Losing symbols on a resolved spin fade slightly per the spec.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: _glyph(size)),
      ),
    );
  }

  Widget _glyph(double size) {
    switch (symbol) {
      case SlotSymbol.bar:
        return _BarGlyph(size: size);
      case SlotSymbol.seven:
        return _GradientGlyph(
          text: '7',
          size: size,
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFFF5C5C),
              Color(0xFFF2B94D),
              Color(0xFF4CD3E0),
              Color(0xFFFF3D78),
            ],
          ),
        );
      case SlotSymbol.luckyStar:
        return _Emoji('⭐', size);
      case SlotSymbol.diamond:
        return _Emoji('💎', size);
      case SlotSymbol.coin:
        return _Emoji('🪙', size);
      case SlotSymbol.bell:
        return _Emoji('🔔', size);
      case SlotSymbol.cherry:
        return _Emoji('🍒', size);
      case SlotSymbol.lemon:
        return _Emoji('🍋', size);
      case SlotSymbol.skull:
        return _Emoji('💀', size);
    }
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji(this.glyph, this.size);

  final String glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(glyph, style: TextStyle(fontSize: size * 0.62));
  }
}

class _BarGlyph extends StatelessWidget {
  const _BarGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.1, vertical: size * 0.06),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: BorderRadius.circular(size * 0.12),
        border: Border.all(color: AppColors.info, width: size * 0.035),
      ),
      child: Text(
        'BAR',
        style: TextStyle(
          fontSize: size * 0.26,
          fontWeight: FontWeight.w900,
          color: AppColors.error,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _GradientGlyph extends StatelessWidget {
  const _GradientGlyph({
    required this.text,
    required this.size,
    required this.gradient,
  });

  final String text;
  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size * 0.62,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
