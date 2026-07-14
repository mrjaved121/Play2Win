import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Null when Supabase hasn't been configured (see [[SupabaseConfig]]) —
/// the UI treats that as its own "cloud login unavailable" state rather
/// than crashing, since Guest Mode must work with zero backend.
final Provider<AuthRepository?> authRepositoryProvider = Provider<AuthRepository?>((Ref ref) {
  if (!getIt.isRegistered<SupabaseClient>()) return null;
  return SupabaseAuthRepository(getIt<SupabaseClient>());
});

/// The signed-in cloud account, or `null` when signed out / not
/// configured. `StreamProvider` (rather than this app's usual
/// `Notifier`) because Supabase's `onAuthStateChange` is already the
/// source of truth — there's no local state to own on top of it.
final StreamProvider<AppAuthUser?> authStateProvider = StreamProvider<AppAuthUser?>((Ref ref) {
  final AuthRepository? repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream<AppAuthUser?>.value(null);
  return repo.authStateChanges();
});
