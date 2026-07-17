/// Base URL of the Project Blackhole admin/game-API backend
/// (`blackhole_admin`), injected at build/run time via `--dart-define`
/// rather than hardcoded — e.g.
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` to reach a
/// `next dev` server on the host machine from the Android emulator.
///
/// Only the crash game (Multiplier Climb, `features/crash`) and Help &
/// Support (`features/support`) talk to this. Everything else in this app
/// (the slot machine, wallet, missions, …) is fully local/offline, so the
/// app must boot cleanly with this unset: [isConfigured] gates whether
/// those features make any network calls at all instead of crashing.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => baseUrl.isNotEmpty;
}
