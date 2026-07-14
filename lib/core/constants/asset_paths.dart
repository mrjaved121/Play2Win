/// Centralized asset path strings so a folder rename only ever touches
/// this file. Mirrors the structure under `assets/`.
abstract final class AssetPaths {
  // ---------------------------------------------------------------------
  // Images — symbols (slot reel icons)
  // ---------------------------------------------------------------------
  static const String _symbols = 'assets/images/symbols';
  static const String symbolCherry = '$_symbols/cherry.png';
  static const String symbolLemon = '$_symbols/lemon.png';
  static const String symbolBar = '$_symbols/bar.png';
  static const String symbolSeven = '$_symbols/seven.png';
  static const String symbolSkull = '$_symbols/skull.png';
  static const String symbolDiamond = '$_symbols/diamond.png';
  static const String symbolBell = '$_symbols/bell.png';
  static const String symbolLuckyStar = '$_symbols/lucky_star.png';
  static const String symbolCoin = '$_symbols/coin.png';

  // ---------------------------------------------------------------------
  // Images — icons & backgrounds
  // ---------------------------------------------------------------------
  static const String icons = 'assets/images/icons';
  static const String backgrounds = 'assets/images/backgrounds';
  static const String reelFrame = 'assets/images/backgrounds/reel_frame.png';

  // ---------------------------------------------------------------------
  // Animations
  // ---------------------------------------------------------------------
  static const String lottie = 'assets/animations/lottie';
  static const String rive = 'assets/animations/rive';
  static const String lottieConfetti = '$lottie/confetti.json';
  static const String lottieCoinExplosion = '$lottie/coin_explosion.json';
  static const String lottieJackpot = '$lottie/jackpot.json';
  static const String riveSlotEffects = '$rive/slot_effects.riv';

  // ---------------------------------------------------------------------
  // Audio
  // ---------------------------------------------------------------------
  static const String sfx = 'assets/audio/sfx';
  static const String music = 'assets/audio/music';
  static const String sfxButtonClick = '$sfx/button_click.wav';
  static const String sfxSpin = '$sfx/spin.wav';
  static const String sfxReelStop = '$sfx/reel_stop.wav';
  static const String sfxWin = '$sfx/win.wav';
  static const String sfxBigWin = '$sfx/big_win.wav';
  static const String sfxJackpot = '$sfx/jackpot.wav';
  static const String sfxCoinCollect = '$sfx/coin_collect.wav';
  static const String musicBackground = '$music/background_loop.wav';
}
