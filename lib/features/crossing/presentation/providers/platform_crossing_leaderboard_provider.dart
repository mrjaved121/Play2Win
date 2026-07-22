import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/crossing_leaderboard.dart';
import 'crossing_providers.dart';

/// Platform-wide activity (all players, not this session's own) — mirrors
/// `PlatformLeaderboardNotifier` from Multiplier Climb. Self-initializing,
/// plus [refresh] for pull-to-refresh; not a perpetual poller, same
/// rationale as the crash version.
class PlatformCrossingLeaderboardNotifier extends Notifier<AsyncValue<CrossingLeaderboard>> {
  @override
  AsyncValue<CrossingLeaderboard> build() {
    unawaited(refresh());
    return const AsyncValue<CrossingLeaderboard>.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue<CrossingLeaderboard>.loading();
    state = await AsyncValue.guard(() async {
      final Map<String, dynamic> json = await ref.read(crossingApiClientProvider).fetchLeaderboard();
      return CrossingLeaderboard.fromJson(json);
    });
  }
}

final NotifierProvider<PlatformCrossingLeaderboardNotifier, AsyncValue<CrossingLeaderboard>>
    platformCrossingLeaderboardProvider =
    NotifierProvider<PlatformCrossingLeaderboardNotifier, AsyncValue<CrossingLeaderboard>>(
  PlatformCrossingLeaderboardNotifier.new,
);
