import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Callback shape for confirming autoplay settings from the bottom sheet —
/// all three are optional stop conditions, `null` meaning "no limit".
typedef AutoplayEnableCallback = void Function({int? maxRounds, int? stopOnProfit, int? stopOnLoss});

/// Autoplay toggle. Off -> On opens a bottom sheet to configure round
/// limit + optional profit/loss stop conditions before confirming; On ->
/// the switch alone turns it off via [onDisable].
class AutoplayControl extends StatelessWidget {
  const AutoplayControl({
    required this.enabled,
    required this.roundsRemaining,
    required this.onEnable,
    required this.onDisable,
    super.key,
  });

  final bool enabled;

  /// Null while enabled means "no limit configured".
  final int? roundsRemaining;
  final AutoplayEnableCallback onEnable;
  final VoidCallback onDisable;

  Future<void> _openSettings(BuildContext context) async {
    final _AutoplaySettings? settings = await showModalBottomSheet<_AutoplaySettings>(
      context: context,
      backgroundColor: AppColors.cardPurple,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext sheetContext) => const _AutoplaySettingsSheet(),
    );
    if (settings != null) {
      onEnable(maxRounds: settings.maxRounds, stopOnProfit: settings.stopOnProfit, stopOnLoss: settings.stopOnLoss);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onDisable : () => unawaited(_openSettings(context)),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled ? AppGradients.neonPurple : null,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.neonPurpleLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            enabled ? (roundsRemaining != null ? '$roundsRemaining LEFT' : 'AUTOPLAY ON') : 'ENABLE\nAUTOPLAY',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.neonPurpleLight,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoplaySettings {
  const _AutoplaySettings({this.maxRounds, this.stopOnProfit, this.stopOnLoss});

  final int? maxRounds;
  final int? stopOnProfit;
  final int? stopOnLoss;
}

class _AutoplaySettingsSheet extends StatefulWidget {
  const _AutoplaySettingsSheet();

  @override
  State<_AutoplaySettingsSheet> createState() => _AutoplaySettingsSheetState();
}

class _AutoplaySettingsSheetState extends State<_AutoplaySettingsSheet> {
  static const List<int?> _roundPresets = <int?>[10, 25, 50, null];

  int? _selectedRounds = 25;
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _lossController = TextEditingController();

  @override
  void dispose() {
    _profitController.dispose();
    _lossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Autoplay settings', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Text('STOP AFTER', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _roundPresets
                .map(
                  (int? rounds) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: PressableScale(
                      onTap: () => setState(() => _selectedRounds = rounds),
                      child: BadgePill(
                        label: rounds == null ? '∞' : '$rounds',
                        filled: rounds == _selectedRounds,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(child: _StopConditionField(label: 'Stop on profit (PKR)', controller: _profitController)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _StopConditionField(label: 'Stop on loss (PKR)', controller: _lossController)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton.primary(
            label: 'Start Autoplay',
            icon: Icons.play_arrow_rounded,
            size: GradientButtonSize.large,
            onPressed: () => Navigator.of(context).pop(
              _AutoplaySettings(
                maxRounds: _selectedRounds,
                stopOnProfit: int.tryParse(_profitController.text),
                stopOnLoss: int.tryParse(_lossController.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopConditionField extends StatelessWidget {
  const _StopConditionField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppGradients.card,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Off'),
          ),
        ),
      ],
    );
  }
}
