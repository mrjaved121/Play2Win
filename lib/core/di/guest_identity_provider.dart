import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../services/storage_service.dart';
import 'service_locator.dart';

/// Stable per-install id sent with every backend-driven game's requests
/// instead of a login — generated once and persisted locally, same "Guest
/// Mode" spirit as the rest of this app. Every backend-driven game must
/// resolve to the *same* `players` row/wallet server-side (see
/// blackhole_admin's playerResolution.ts), so this id has to be shared
/// across features rather than minted separately per game.
///
/// This was originally `crashGuestIdProvider`, defined only inside the
/// crash feature — the Hive key stays `'crash_guest_id'` on purpose so
/// existing installs keep resolving to the same guest player row instead of
/// silently getting a new one (and a split wallet) the first time this
/// provider is read from a non-crash feature.
final Provider<String> guestIdProvider = Provider<String>((Ref ref) {
  const String key = 'crash_guest_id';
  final StorageService storage = getIt<StorageService>();
  final String? existing = storage.get<String>(key);
  if (existing != null) return existing;

  final String created = const Uuid().v4();
  unawaited(storage.put<String>(key, created));
  return created;
});
