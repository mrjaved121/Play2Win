import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

AppAuthUser _toAppUser(User user) {
  return AppAuthUser(
    id: user.id,
    email: user.email,
    displayName: user.userMetadata?['full_name'] as String?,
  );
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AppAuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map(
      (AuthState state) => state.session?.user != null ? _toAppUser(state.session!.user) : null,
    );
  }

  @override
  AppAuthUser? get currentUser {
    final User? user = _client.auth.currentUser;
    return user != null ? _toAppUser(user) : null;
  }

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Future<void> signInWithPassword({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithPassword({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithMagicLink({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
