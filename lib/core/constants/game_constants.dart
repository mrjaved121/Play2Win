import 'asset_paths.dart';

/// The 9 reel symbols. Order here is display/paytable order (lowest to
/// highest value), not reel order.
enum SlotSymbol {
  skull,
  lemon,
  cherry,
  bell,
  bar,
  coin,
  diamond,
  luckyStar,
  seven,
}

/// Per-symbol config: art, weighted odds and payout multipliers.
///
/// [weight] feeds the weighted-random reel generator (higher = more
/// common). [payoutMultiplier] is expressed as "x current bet" for a
/// 3-in-a-row match on an active payline; kept here rather than hardcoded
/// in game logic so RTP can be retuned centrally.
extension SlotSymbolX on SlotSymbol {
  String get assetPath => switch (this) {
        SlotSymbol.cherry => AssetPaths.symbolCherry,
        SlotSymbol.lemon => AssetPaths.symbolLemon,
        SlotSymbol.bar => AssetPaths.symbolBar,
        SlotSymbol.seven => AssetPaths.symbolSeven,
        SlotSymbol.skull => AssetPaths.symbolSkull,
        SlotSymbol.diamond => AssetPaths.symbolDiamond,
        SlotSymbol.bell => AssetPaths.symbolBell,
        SlotSymbol.luckyStar => AssetPaths.symbolLuckyStar,
        SlotSymbol.coin => AssetPaths.symbolCoin,
      };

  String get displayName => switch (this) {
        SlotSymbol.cherry => 'Cherry',
        SlotSymbol.lemon => 'Lemon',
        SlotSymbol.bar => 'BAR',
        SlotSymbol.seven => 'Lucky Seven',
        SlotSymbol.skull => 'Skull',
        SlotSymbol.diamond => 'Diamond',
        SlotSymbol.bell => 'Bell',
        SlotSymbol.luckyStar => 'Lucky Star',
        SlotSymbol.coin => 'Coin',
      };

  /// Relative weight used by the weighted-random reel generator.
  /// Higher-paying symbols are intentionally rarer.
  int get weight => switch (this) {
        SlotSymbol.skull => 22,
        SlotSymbol.lemon => 20,
        SlotSymbol.cherry => 18,
        SlotSymbol.bell => 14,
        SlotSymbol.bar => 10,
        SlotSymbol.coin => 8,
        SlotSymbol.diamond => 5,
        SlotSymbol.luckyStar => 2,
        SlotSymbol.seven => 1,
      };

  /// Payout as a multiple of the current bet for 3-in-a-row.
  ///
  /// Tuned (with [GameConstants.paylines]' 5 lines and these symbols'
  /// [weight]s) to land close to [GameConstants.targetRtp] — see the
  /// `spin engine statistics` test, which runs 20k simulated spins and
  /// prints the resulting RTP. An earlier pass at these numbers produced
  /// a ~19% RTP instead of the intended ~92%; don't retune without
  /// rerunning that test.
  double get payoutMultiplier => switch (this) {
        SlotSymbol.skull => 0, // skull = no payout, thematically "bust"
        SlotSymbol.lemon => 5,
        SlotSymbol.cherry => 7,
        SlotSymbol.bell => 15,
        SlotSymbol.bar => 25,
        SlotSymbol.coin => 40,
        SlotSymbol.diamond => 75,
        SlotSymbol.luckyStar => 150,
        SlotSymbol.seven => 500,
      };

  /// Tint used for this symbol's glow when part of a winning line.
  AppColorTint get glowTint => switch (this) {
        SlotSymbol.seven || SlotSymbol.luckyStar => AppColorTint.gold,
        SlotSymbol.diamond => AppColorTint.purple,
        _ => AppColorTint.warm,
      };
}

/// Small enum to avoid importing [AppColors] widely from domain constants;
/// presentation code maps this to an actual [AppColors] value.
enum AppColorTint { gold, purple, warm }

/// Central game configuration: reel layout, paylines, RTP and bonus
/// systems. Values here are the single source of truth for Phase 4 game
/// logic — nothing below should be duplicated/hardcoded in providers.
abstract final class GameConstants {
  /// 3x3 grid: 3 reels, 3 visible symbols per reel.
  static const int reelCount = 3;
  static const int symbolsPerReel = 3;

  /// Extra symbols rendered above/below the visible window purely for the
  /// spin-blur animation (not part of game logic).
  static const int spinBufferSymbols = 6;

  /// Row-index paylines across the 3x3 grid. Each inner list is the row
  /// index (0=top..2=bottom) used per reel. A simple 3-line setup:
  /// top row, middle row, bottom row. Diagonals can be added later
  /// without touching call sites since consumers iterate this list.
  static const List<List<int>> paylines = <List<int>>[
    <int>[0, 0, 0], // top row
    <int>[1, 1, 1], // middle row
    <int>[2, 2, 2], // bottom row
    <int>[0, 1, 2], // diagonal \
    <int>[2, 1, 0], // diagonal /
  ];

  /// Target return-to-player used to sanity-check payout tuning in tests;
  /// not enforced at runtime (weights + payouts approximate it).
  static const double targetRtp = 0.92;

  /// Probability [0,1] that a losing spin is deliberately dressed as a
  /// "near miss" (two matching symbols + one adjacent-in-paytable symbol
  /// on the payline) to land the "SO CLOSE!" beat.
  static const double nearMissChance = 0.12;

  /// Consecutive losing spins after which free spins may trigger.
  static const int freeSpinsTriggerCount = 3;
  static const int freeSpinsAwarded = 5;
  static const double freeSpinsMultiplier = 2.0;

  /// Jackpot seed + contribution per spin (a fraction of every bet feeds
  /// the progressive jackpot shown in the header).
  static const int jackpotSeed = 500;
  static const double jackpotContributionRate = 0.01;
  static const double jackpotWinChance = 0.0025;
}
