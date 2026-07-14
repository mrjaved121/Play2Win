import 'package:flutter_test/flutter_test.dart';
import 'package:premium_slots/core/constants/game_constants.dart';
import 'package:premium_slots/features/slot/domain/services/spin_engine.dart';

/// Statistical regression test: simulates many spins and asserts the
/// resulting RTP lands in a sane range around [GameConstants.targetRtp].
///
/// A previous tuning of `SlotSymbolX.payoutMultiplier` produced a ~19%
/// RTP instead of the intended ~92% — wildly too player-unfavorable to
/// be a fun game — because the multipliers didn't account for how
/// strongly [SlotSymbolX.weight] suppresses the odds of a 3-match. This
/// test exists so a future retune of weights/multipliers can't silently
/// reintroduce that mismatch.
void main() {
  test('RTP stays within a sane range of the target', () {
    final SpinEngine engine = SpinEngine();
    const int trials = 20000;
    const int bet = 20;
    int totalPayout = 0;
    int wins = 0;

    for (int i = 0; i < trials; i++) {
      final outcome = engine.spin(bet: bet);
      if (outcome.isWin) wins++;
      totalPayout += outcome.totalPayout;
    }

    final double rtp = totalPayout / (trials * bet);

    expect(wins, greaterThan(0), reason: 'Engine should produce at least some wins over $trials spins.');
    // Symbol-payout RTP alone (excludes jackpot pot payouts, which push
    // real in-game RTP a bit higher) — allow a wide-ish band since this
    // is a Monte Carlo estimate, not an exact value.
    expect(
      rtp,
      inInclusiveRange(GameConstants.targetRtp - 0.15, GameConstants.targetRtp + 0.05),
      reason: 'RTP $rtp is too far from the ${GameConstants.targetRtp} target — '
          'check SlotSymbolX.payoutMultiplier against SlotSymbolX.weight.',
    );
  });
}
