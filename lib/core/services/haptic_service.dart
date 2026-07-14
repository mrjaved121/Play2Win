import 'package:flutter/services.dart';

/// Thin wrapper around [HapticFeedback] that respects the user's
/// Settings > Vibration toggle so feature code never has to check it.
abstract class HapticService {
  bool get isEnabled;
  void setEnabled(bool enabled);

  void light();
  void medium();
  void heavy();
  void selection();
}

class DeviceHapticService implements HapticService {
  bool _enabled = true;

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled(bool enabled) => _enabled = enabled;

  @override
  void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  @override
  void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  @override
  void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  @override
  void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }
}
