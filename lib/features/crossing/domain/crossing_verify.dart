import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import 'entities/crossing_round.dart';

/// Client-side provably-fair verification — closes a gap Multiplier Climb
/// still has today (it only ever *displays* the seed hash, never actually
/// recomputes it). Exact port of blackhole_admin's `engine.ts`
/// (`hashServerSeed`/`isLaneBust`) to Dart, so a player can independently
/// confirm a resolved round's outcome without trusting the app's own UI.
class LaneVerification {
  const LaneVerification({required this.laneIndex, required this.reportedBust});

  final int laneIndex;

  /// Whether *this* lane is expected to have busted, per what the round
  /// actually showed (true only for the final lane of a busted round).
  final bool reportedBust;
}

class CrossingVerifyResult {
  const CrossingVerifyResult({required this.hashMatches, required this.laneMatches});

  /// sha256(serverSeed) == serverSeedHash.
  final bool hashMatches;

  /// One entry per lane checked, true if replaying the HMAC draw
  /// reproduces exactly what the round reported for that lane.
  final Map<int, bool> laneMatches;

  bool get allMatch => hashMatches && laneMatches.values.every((bool m) => m);
}

bool _laneIsBust(String serverSeed, String clientSeed, String roundId, int laneIndex, double bustPct) {
  final String message = '$clientSeed:$roundId:$laneIndex';
  final Hmac hmac = Hmac(sha256, utf8.encode(serverSeed));
  final String hex = hmac.convert(utf8.encode(message)).toString();
  final int h = int.parse(hex.substring(0, 13), radix: 16);
  final double u = h / math.pow(2, 52);
  return u < bustPct / 100;
}

/// Verifies a resolved [CrossingRound] end-to-end: the seed reveal, and
/// every lane from 1..currentLane (all must have survived) plus, for a
/// busted round, the one extra lane that ended it (must have busted).
/// Returns null if the round isn't resolved yet (nothing to verify).
CrossingVerifyResult? verifyCrossingRound(CrossingRound round) {
  final String? serverSeed = round.serverSeed;
  final double? bustPct = round.bustPct;
  if (serverSeed == null || bustPct == null || round.status == CrossingRoundStatus.pending) return null;

  final bool hashMatches = sha256.convert(utf8.encode(serverSeed)).toString() == round.serverSeedHash;

  final Map<int, bool> laneMatches = <int, bool>{};
  for (int lane = 1; lane <= round.currentLane; lane++) {
    final bool busted = _laneIsBust(serverSeed, round.clientSeed, round.roundId, lane, bustPct);
    laneMatches[lane] = !busted; // every lane up to currentLane must have survived
  }
  if (round.status == CrossingRoundStatus.busted) {
    final int finalLane = round.currentLane + 1;
    laneMatches[finalLane] = _laneIsBust(serverSeed, round.clientSeed, round.roundId, finalLane, bustPct);
  }

  return CrossingVerifyResult(hashMatches: hashMatches, laneMatches: laneMatches);
}
