import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

/// The gradient backdrop every screen sits on, wrapped in a [SafeArea].
/// Wrap each screen's body with this instead of repeating the
/// `DecoratedBox(gradient: AppGradients.background)` boilerplate.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    required this.child,
    this.bottom = true,
    this.wrapInScaffold = true,
    super.key,
  });

  final Widget child;

  /// Whether the bottom safe-area inset is respected here. Screens hosted
  /// inside the bottom-nav shell should pass `false` since the shell's
  /// `Scaffold(extendBody: true)` + bottom nav already handle it.
  final bool bottom;

  /// Whether this wraps itself in its own [Scaffold]. Pushed screens
  /// (Profile, Wallet, Rewards, Achievements, …) need this — without a
  /// [Material]/[Scaffold] ancestor, Android renders an underline under
  /// every piece of text. Bottom-nav tab screens should pass `false`
  /// since they already sit inside `AppShellScreen`'s `Scaffold` and
  /// nesting a second one is redundant.
  final bool wrapInScaffold;

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: SafeArea(bottom: bottom, child: child),
    );

    if (!wrapInScaffold) return content;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: content,
    );
  }
}
