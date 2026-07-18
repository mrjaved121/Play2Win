import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/crash_leaderboard.dart';
import 'crash_providers.dart';

/// Platform-wide activity (all players, not this session's own) — self-
/// initializing (fetches once as soon as anything first watches it,
/// mirroring [CrashSlotNotifier.build]'s own `_loadBalance`/`_loadHistory`
/// calls), plus [refresh] for the manual pull-to-refresh affordance.
/// Deliberately not a perpetual poller: this isn't in the "real-time"
/// scope of this pass (see the Phase A plan), and polling something
/// rarely visible isn't worth the battery/network cost.
class PlatformLeaderboardNotifier extends Notifier<AsyncValue<CrashLeaderboard>> {
  @override
  AsyncValue<CrashLeaderboard> build() {
    unawaited(refresh());
    return const AsyncValue<CrashLeaderboard>.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue<CrashLeaderboard>.loading();
    state = await AsyncValue.guard(() async {
      final Map<String, dynamic> json = await ref.read(crashApiClientProvider).fetchLeaderboard();
      return CrashLeaderboard.fromJson(json);
    });
  }
}

final NotifierProvider<PlatformLeaderboardNotifier, AsyncValue<CrashLeaderboard>> platformLeaderboardProvider =
    NotifierProvider<PlatformLeaderboardNotifier, AsyncValue<CrashLeaderboard>>(PlatformLeaderboardNotifier.new);
