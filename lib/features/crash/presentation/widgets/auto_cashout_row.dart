import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// One-tap auto-cash-out targets — once the live multiplier reaches
/// [current], [CrashSlotNotifier] collects automatically. `null` means
/// manual-only (the default).
class AutoCashoutRow extends StatelessWidget {
  const AutoCashoutRow({required this.current, required this.onSelect, super.key});

  final double? current;
  final ValueChanged<double?> onSelect;

  static const List<double?> _presets = <double?>[null, 1.5, 2.0, 3.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final double? target = _presets[index];
          final bool selected = target == current;
          return PressableScale(
            onTap: () => onSelect(target),
            child: BadgePill(
              label: target == null ? 'Manual' : '${target.toStringAsFixed(2)}x',
              color: AppColors.neonPurpleLight,
              filled: selected,
            ),
          );
        },
      ),
    );
  }
}
