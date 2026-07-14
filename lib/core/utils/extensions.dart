import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Quick access to theme pieces + responsive helpers from any
/// [BuildContext] without importing Theme.of(context) boilerplate
/// everywhere.
extension BuildContextX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Breakpoints follow Material 3 window size classes (compact / medium
  /// / expanded), used to switch layouts between phone, tablet and web.
  bool get isCompact => screenWidth < 600;
  bool get isMedium => screenWidth >= 600 && screenWidth < 840;
  bool get isExpanded => screenWidth >= 840;

  bool get isTablet => screenWidth >= 600;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
}

/// Coin/number formatting shared by balance, bet and jackpot displays.
extension CoinAmountX on num {
  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');

  /// `1234` -> `"1,234"`
  String get asGrouped => _grouped.format(this);

  /// `1234567` -> `"1.2M"` — used where space is tight (leaderboard rows).
  String get asCompact => _compact.format(this);
}

/// Convenience for repeated tap-scale / press-state widgets.
extension WidgetPaddingX on Widget {
  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );
}
