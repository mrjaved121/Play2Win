import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Free-text bet entry with a trailing Clear (X) button — mirrors Multiplier
/// Climb's `BetInputField`, duplicated per this app's existing per-feature
/// convention rather than importing across features (see
/// `crash_top_actions.dart`'s doc comment).
class CrossingBetInputField extends StatefulWidget {
  const CrossingBetInputField({
    required this.value,
    required this.minBet,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final int value;
  final int minBet;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  State<CrossingBetInputField> createState() => _CrossingBetInputFieldState();
}

class _CrossingBetInputFieldState extends State<CrossingBetInputField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(CrossingBetInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final int? parsed = int.tryParse(text);
    if (parsed != null) widget.onChanged(parsed);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged(widget.minBet);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Text('CR', style: AppTextStyles.label),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.counter.copyWith(fontSize: 16),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onChanged: _submit,
            ),
          ),
          if (widget.enabled)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: _clear,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

/// One-tap preset bet amounts as a single scrollable-free row — mirrors
/// Multiplier Climb's `QuickBetRow`.
class CrossingQuickBetRow extends StatelessWidget {
  const CrossingQuickBetRow({
    required this.currentBet,
    required this.presets,
    required this.onSelect,
    required this.enabled,
    super.key,
  });

  final int currentBet;
  final List<int> presets;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: presets
          .map(
            (int amount) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _QuickBetChip(
                  amount: amount,
                  selected: amount == currentBet,
                  enabled: enabled,
                  onTap: () => onSelect(amount),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickBetChip extends StatelessWidget {
  const _QuickBetChip({required this.amount, required this.selected, required this.enabled, required this.onTap});

  final int amount;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: PressableScale(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.cardPurpleLight,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(color: selected ? AppColors.gold : AppColors.cardBorder),
          ),
          child: Text(
            '$amount',
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.textOnGold : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
