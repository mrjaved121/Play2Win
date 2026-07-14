import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';

/// Player display name — set once during Guest Mode onboarding, editable
/// later from Settings/Profile. There's no real account system (see
/// [[project-backend-architecture]]), so this is just a local nickname,
/// not an authenticated identity.
class PlayerNameNotifier extends Notifier<String> {
  static const String _key = 'player_display_name';

  @override
  String build() {
    final StorageService storage = getIt<StorageService>();
    return storage.get<String>(_key) ?? _randomGuestName();
  }

  void setName(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    getIt<StorageService>().put<String>(_key, trimmed);
  }

  static String _randomGuestName() {
    final int suffix = 1000 + Random().nextInt(9000);
    return 'Guest$suffix';
  }
}

final NotifierProvider<PlayerNameNotifier, String> playerNameProvider =
    NotifierProvider<PlayerNameNotifier, String>(PlayerNameNotifier.new);

/// Whether the player has completed (or skipped) the onboarding flow —
/// gates whether [SplashScreen] routes to Onboarding or straight Home.
class OnboardingCompleteNotifier extends Notifier<bool> {
  static const String _key = 'onboarding_complete';

  @override
  bool build() => getIt<StorageService>().get<bool>(_key) ?? false;

  void complete() {
    state = true;
    getIt<StorageService>().put<bool>(_key, true);
  }
}

final NotifierProvider<OnboardingCompleteNotifier, bool> onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(OnboardingCompleteNotifier.new);
