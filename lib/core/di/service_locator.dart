import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/storage_service.dart';

/// Global service locator.
///
/// Scope: cross-cutting, non-reactive **services** (audio, storage,
/// haptics, the Supabase client) live here and are resolved with
/// `getIt<T>()`. Reactive **app/feature state** lives in Riverpod
/// providers, which read from these services rather than duplicating
/// them. This keeps a single instance of each service (audio players,
/// open Hive boxes, the Supabase client) regardless of how many
/// providers depend on it.
final GetIt getIt = GetIt.instance;

/// Registers and initializes all core services. Must be awaited before
/// `runApp()` so `StorageService`/`AudioService` are ready the first time
/// a widget/provider touches them.
Future<void> setupServiceLocator() async {
  final StorageService storageService = HiveStorageService();
  await storageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  final AudioService audioService = JustAudioService();
  await audioService.init();
  getIt.registerSingleton<AudioService>(audioService);

  getIt.registerSingleton<HapticService>(DeviceHapticService());

  // Login is optional (see [[project-backend-architecture]] /
  // SupabaseConfig's doc comment) — skip entirely, and leave
  // SupabaseClient unregistered, until real credentials are supplied.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
    getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  }
}
