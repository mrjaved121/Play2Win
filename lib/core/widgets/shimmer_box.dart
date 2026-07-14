import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Loading placeholder: a rounded box with a shimmer sweep animating
/// across it. Use while feature data (leaderboard, store catalog, …) is
/// loading instead of a bare spinner.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.radiusSm,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.cardPurpleLight,
            child: Align(
              alignment: Alignment(-3 + _controller.value * 6, 0),
              child: const FractionallySizedBox(
                widthFactor: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.shimmer),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
