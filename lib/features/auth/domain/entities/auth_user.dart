/// The signed-in cloud account, decoupled from Supabase's own `User`
/// type so the rest of the app never depends on the Supabase SDK
/// directly. Never persisted to Hive — the SDK owns session persistence
/// — so this stays a plain class rather than a Freezed/JSON entity.
class AppAuthUser {
  const AppAuthUser({required this.id, this.email, this.displayName});

  final String id;
  final String? email;
  final String? displayName;
}
