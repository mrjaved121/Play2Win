import '../entities/auth_user.dart';

/// Cloud-account authentication boundary — mirrors this app's other
/// repository interfaces (e.g. [[WalletRepository]]) but async/stream-
/// based throughout since every operation is a network call.
abstract class AuthRepository {
  /// Emits the current user (or `null` when signed out) immediately on
  /// listen, then again on every sign-in/sign-out.
  Stream<AppAuthUser?> authStateChanges();

  AppAuthUser? get currentUser;

  Future<void> signInWithPassword({required String email, required String password});

  Future<void> signUpWithPassword({required String email, required String password});

  /// Sends a passwordless sign-in link to [email].
  Future<void> signInWithMagicLink({required String email});

  Future<void> signInWithGoogle();

  Future<void> signOut();
}
