/// Centralized route paths + names for [GoRouter]. Feature screens should
/// navigate via `context.goNamed(RouteNames.xyz)` rather than hardcoded
/// path strings.
abstract final class RouteNames {
  // Root / bottom-nav tabs
  static const String home = 'home';
  static const String store = 'store';
  static const String leaderboard = 'leaderboard';
  static const String missions = 'missions';
  static const String settings = 'settings';

  // Pushed on top of the shell
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String profile = 'profile';
  static const String wallet = 'wallet';
  static const String rewards = 'rewards';
  static const String achievements = 'achievements';
  static const String playSlots = 'playSlots';
  static const String login = 'login';
}

abstract final class RoutePaths {
  static const String home = '/';
  static const String store = '/store';
  static const String leaderboard = '/leaderboard';
  static const String missions = '/missions';
  static const String settings = '/settings';

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String rewards = '/rewards';
  static const String achievements = '/achievements';
  static const String playSlots = '/play/slots';
  static const String login = '/login';
}
