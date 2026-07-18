import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/crash_constants.dart';

/// Free-text bet entry with a trailing Clear (X) button — sits alongside
/// [QuickBetRow]'s one-tap presets rather than replacing them.
class BetInputField extends StatefulWidget {
  const BetInputField({required this.value, required this.onChanged, required this.enabled, super.key});

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  State<BetInputField> createState() => _BetInputFieldState();
}

class _BetInputFieldState extends State<BetInputField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(BetInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only overwrite the field from external state when the player isn't
    // actively typing in it — otherwise a quick-bet tap elsewhere would
    // fight the cursor mid-edit.
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
    widget.onChanged(CrashConstants.minBet);
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
          Text('PKR', style: AppTextStyles.label),
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
