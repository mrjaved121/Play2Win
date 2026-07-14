import 'package:flutter/widgets.dart';

/// Corner radius scale. The design spec calls for 18-24px rounded corners
/// on most surfaces; smaller values are reserved for chips/pills/icons.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill =
      BorderRadius.all(Radius.circular(pill));
}
