/// App-wide, non-game constants: identity, economy defaults and simple
/// tunables that don't belong to a specific feature.
abstract final class AppConstants {
  static const String appName = 'Premium Slots';

  // ---------------------------------------------------------------------
  // Wallet / economy defaults
  // ---------------------------------------------------------------------
  static const int startingBalance = 100;
  static const int minBet = 10;
  static const int maxBet = 500;
  static const int betStep = 10;
  static const int defaultBet = 20;

  // ---------------------------------------------------------------------
  // Free-coin sources — off for now so a new player's balance can only
  // ever go down from [startingBalance], never up, short of a real
  // purchase. Flip back on to re-enable; nothing else needs to change.
  // ---------------------------------------------------------------------
  static const bool dailyBonusEnabled = false;
  static const bool missionsEnabled = false;

  // ---------------------------------------------------------------------
  // Daily bonus
  // ---------------------------------------------------------------------
  static const int dailyBonusRequiredSpins = 10;
  static const int dailyBonusReward = 100;
  static const Duration dailyBonusResetPeriod = Duration(hours: 24);

  // ---------------------------------------------------------------------
  // VIP tiers — cumulative lifetime coins wagered to reach each tier.
  // Index corresponds to AppColors.vipTierColors.
  // ---------------------------------------------------------------------
  static const List<int> vipTierThresholds = <int>[0, 5000, 20000, 75000, 250000];

  // ---------------------------------------------------------------------
  // Auto spin
  // ---------------------------------------------------------------------
  static const List<int> autoSpinOptions = <int>[10, 25, 50, 100];

  // ---------------------------------------------------------------------
  // Animation timing (shared durations so motion feels consistent)
  // ---------------------------------------------------------------------
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration reelSpinDuration = Duration(milliseconds: 900);
  static const Duration reelStaggerDelay = Duration(milliseconds: 180);
}
