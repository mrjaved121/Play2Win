/// Supabase project credentials, injected at build/run time via
/// `--dart-define` rather than hardcoded — e.g.
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Login is optional (Guest Mode always works), so the app must boot
/// cleanly with neither value set: [isConfigured] gates whether
/// [setupServiceLocator] initializes Supabase at all, and the auth
/// feature treats "not configured" as its own state rather than
/// crashing or throwing.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
